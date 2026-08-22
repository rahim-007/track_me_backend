import { ReminderSchedulerService } from './reminder-scheduler.service';

// Monday 2026-08-10, 07:30 server-local
const MON_730 = new Date(2026, 7, 10, 7, 30, 0, 0);

const config = (overrides: Record<string, any> = {}) =>
  ({
    get: (key: string, def?: any) => (key in overrides ? overrides[key] : def),
  } as any);

describe('ReminderSchedulerService.tick (habits)', () => {
  const habit = (over: Partial<any> = {}) => ({
    id: 'h1',
    userId: 'u1',
    name: 'Morning Run',
    emoji: '🏃',
    repeatDays: [true, true, true, true, true, true, true], // daily
    reminderTime: '07:30',
    user: { timezone: null },
    ...over,
  });

  const prisma = {
    habit: { findMany: jest.fn() },
    goal: { findMany: jest.fn().mockResolvedValue([]) },
    notification: { findMany: jest.fn().mockResolvedValue([]) },
    habitLog: { findMany: jest.fn().mockResolvedValue([]) },
  };
  const notifications = { create: jest.fn().mockResolvedValue({ id: 'n1' }) };

  beforeEach(() => {
    jest.resetAllMocks();
    prisma.habit.findMany.mockResolvedValue([habit()]);
    prisma.goal.findMany.mockResolvedValue([]);
    prisma.notification.findMany.mockResolvedValue([]);
    prisma.habitLog.findMany.mockResolvedValue([]);
    notifications.create.mockResolvedValue({ id: 'n1' });
  });

  it('sends a reminder for a habit due at the current time', async () => {
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());

    const sent = await service.tick(MON_730);

    expect(sent).toBe(1);
    // Queries ALL habits with a reminder time — per-user tz matching is in JS.
    expect(prisma.habit.findMany).toHaveBeenCalledWith({
      where: { isActive: true, reminderTime: { not: null } },
      select: {
        id: true,
        userId: true,
        name: true,
        emoji: true,
        repeatDays: true,
        reminderTime: true,
        user: { select: { timezone: true } },
      },
    });
    expect(notifications.create).toHaveBeenCalledWith({
      userId: 'u1',
      type: 'HABIT_REMINDER',
      title: '⏰ 🏃 Morning Run',
      body: 'Time to complete this habit. Keep your streak alive!',
      data: {
        category: 'habit',
        relatedId: 'h1',
        relatedType: 'habit',
        route: '/habits',
      },
    });
  });

  it('does nothing when no habit has a reminder time', async () => {
    prisma.habit.findMany.mockResolvedValue([]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(MON_730);
    expect(sent).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('skips habits whose reminder time does not match the local clock', async () => {
    prisma.habit.findMany.mockResolvedValue([habit({ reminderTime: '08:00' })]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(MON_730);
    expect(sent).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('skips habits not scheduled for today (repeatDays weekday=false)', async () => {
    // Mon(0)=false → not due on Monday.
    prisma.habit.findMany.mockResolvedValue([
      habit({ repeatDays: [false, true, true, true, true, true, true] }),
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(MON_730);
    expect(sent).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('does not re-send when a HABIT_REMINDER for this habit already exists today', async () => {
    prisma.notification.findMany.mockResolvedValue([
      { userId: 'u1', data: { category: 'habit', relatedId: 'h1' } },
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(MON_730);
    expect(sent).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('skips habits already completed today (non-skipped log exists)', async () => {
    prisma.habitLog.findMany.mockResolvedValue([{ habitId: 'h1' }]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(MON_730);
    expect(sent).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('matches by the user stored timezone (overrides env fallback)', async () => {
    // User in Kolkata: 2026-08-10 07:30 UTC = 13:00 IST, Monday.
    prisma.habit.findMany.mockResolvedValue([
      habit({ reminderTime: '13:00', user: { timezone: 'Asia/Kolkata' } }),
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config({
      REMINDER_TIMEZONE: 'UTC', // fallback would NOT match 13:00
    }));
    const utcNow = new Date(Date.UTC(2026, 7, 10, 7, 30, 0));
    const sent = await service.tick(utcNow);
    expect(sent).toBe(1);
  });

  it('falls back to the configured timezone when the user has none', async () => {
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config({
      REMINDER_TIMEZONE: 'Asia/Kolkata',
    }));
    // 07:30 UTC = 13:00 IST. Habit's reminderTime is 07:30 but in IST it is
    // 13:00 — so no match, nothing is sent.
    const utcNow = new Date(Date.UTC(2026, 7, 10, 7, 30, 0));
    const sent = await service.tick(utcNow);
    expect(sent).toBe(0);

    // With a habit scheduled at 13:00, the same instant matches.
    prisma.habit.findMany.mockResolvedValue([
      habit({ reminderTime: '13:00', user: { timezone: null } }),
    ]);
    const sent2 = await service.tick(utcNow);
    expect(sent2).toBe(1);
  });

  it('only reminds the user whose local clock matches (mixed timezones)', async () => {
    prisma.habit.findMany.mockResolvedValue([
      habit({ id: 'h-kolkata', userId: 'u-k', reminderTime: '13:00', user: { timezone: 'Asia/Kolkata' } }),
      habit({ id: 'h-utc', userId: 'u-u', reminderTime: '07:30', user: { timezone: 'UTC' } }),
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    // 07:30 UTC → 13:00 IST for Kolkata user, 07:30 for UTC user. Both due.
    const utcNow = new Date(Date.UTC(2026, 7, 10, 7, 30, 0));
    const sent = await service.tick(utcNow);
    expect(sent).toBe(2);

    // 07:30 UTC → 13:00 IST; a NYC user (UTC-4 in August) is at 03:30 → not due.
    prisma.habit.findMany.mockResolvedValue([
      habit({ id: 'h-nyc', userId: 'u-n', reminderTime: '07:30', user: { timezone: 'America/New_York' } }),
      habit({ id: 'h-kolkata', userId: 'u-k', reminderTime: '13:00', user: { timezone: 'Asia/Kolkata' } }),
    ]);
    const sent2 = await service.tick(utcNow);
    expect(sent2).toBe(1);
  });

  it('is idempotent across repeated ticks (same-day dedupe via DB)', async () => {
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    await service.tick(MON_730); // first run: sends

    // Second run: the DB now reports the reminder was already sent.
    prisma.notification.findMany.mockResolvedValue([
      { userId: 'u1', data: { category: 'habit', relatedId: 'h1' } },
    ]);
    const sent = await service.tick(MON_730);

    expect(sent).toBe(0);
    expect(notifications.create).toHaveBeenCalledTimes(1);
  });

  it('continues past a habit whose notification fails (per-habit error handling)', async () => {
    notifications.create
      .mockRejectedValueOnce(new Error('db down'))
      .mockResolvedValueOnce({ id: 'n2' });
    prisma.habit.findMany.mockResolvedValue([
      habit({ id: 'h1' }),
      habit({ id: 'h2', name: 'Read' }),
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());

    const sent = await service.tick(MON_730);
    expect(sent).toBe(1); // h1 failed, h2 succeeded
  });
});

describe('ReminderSchedulerService.tick (goals)', () => {
  // Tuesday 2026-08-11, 09:00 server-local — matches default GOAL_REMINDER_TIME.
  const TUE_0900 = new Date(2026, 7, 11, 9, 0, 0, 0);

  const goal = (over: Partial<any> = {}) => ({
    id: 'g1',
    userId: 'u1',
    name: 'Run a marathon',
    status: 'IN_PROGRESS',
    // Midnight UTC so the day counts are machine-timezone independent.
    targetDate: new Date(Date.UTC(2026, 7, 15, 0, 0, 0)), // 4 days after 2026-08-11
    user: { timezone: null },
    ...over,
  });

  const prisma = {
    habit: { findMany: jest.fn().mockResolvedValue([]) },
    goal: { findMany: jest.fn() },
    notification: { findMany: jest.fn().mockResolvedValue([]) },
    habitLog: { findMany: jest.fn().mockResolvedValue([]) },
  };
  const notifications = { create: jest.fn().mockResolvedValue({ id: 'n1' }) };

  beforeEach(() => {
    jest.resetAllMocks();
    prisma.habit.findMany.mockResolvedValue([]);
    prisma.goal.findMany.mockResolvedValue([goal()]);
    prisma.notification.findMany.mockResolvedValue([]);
    prisma.habitLog.findMany.mockResolvedValue([]);
    notifications.create.mockResolvedValue({ id: 'n1' });
  });

  it('sends a goal reminder for an in-progress goal within the window', async () => {
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());

    const sent = await service.tick(TUE_0900);

    expect(sent).toBe(1);
    // Coarse prune in SQL (wide margins for tz differences); exact per-user
    // window + time-of-day gate happen in JS.
    expect(prisma.goal.findMany).toHaveBeenCalledWith({
      where: {
        status: { in: ['NOT_STARTED', 'IN_PROGRESS'] },
        targetDate: { gte: expect.any(Date), lte: expect.any(Date) },
      },
      select: {
        id: true,
        userId: true,
        name: true,
        targetDate: true,
        user: { select: { timezone: true } },
      },
    });
    expect(notifications.create).toHaveBeenCalledWith({
      userId: 'u1',
      type: 'GOAL_REMINDER',
      title: '🎯 Run a marathon',
      body: 'Your goal target date is in 4 days. Keep pushing!',
      data: {
        category: 'goals',
        relatedId: 'g1',
        relatedType: 'goal',
        route: '/goals',
      },
    });
  });

  it('does not nudge when the local time-of-day is outside GOAL_REMINDER_TIME', async () => {
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(MON_730); // 07:30 ≠ 09:00
    // The goal query still runs (per-user gate) but nothing is sent.
    expect(prisma.goal.findMany).toHaveBeenCalled();
    expect(sent).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('respects GOAL_REMINDER_DAYS as the per-user window (JS-side)', async () => {
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config({
      GOAL_REMINDER_DAYS: 3,
    }));
    // targetDate is 4 days out → outside the 3-day window → not sent.
    const sent = await service.tick(TUE_0900);
    expect(sent).toBe(0);

    prisma.goal.findMany.mockResolvedValue([
      goal({ targetDate: new Date(Date.UTC(2026, 7, 14, 0, 0, 0)) }), // exactly 3 days out
    ]);
    const sent2 = await service.tick(TUE_0900);
    expect(sent2).toBe(1);
  });

  it('excludes completed/overdue goals via the status filter (no rows → no reminder)', async () => {
    prisma.goal.findMany.mockResolvedValue([]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(TUE_0900);
    expect(sent).toBe(0);
    expect(prisma.goal.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: { in: ['NOT_STARTED', 'IN_PROGRESS'] },
        }),
      }),
    );
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('does not re-nudge a goal already reminded today', async () => {
    prisma.notification.findMany.mockResolvedValue([
      { userId: 'u1', data: { category: 'goals', relatedId: 'g1' } },
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    const sent = await service.tick(TUE_0900);
    expect(sent).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('phrases the body for a goal due today', async () => {
    prisma.goal.findMany.mockResolvedValue([
      goal({ targetDate: new Date(Date.UTC(2026, 7, 11, 0, 0, 0)) }),
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    await service.tick(TUE_0900);
    expect(notifications.create).toHaveBeenCalledWith(
      expect.objectContaining({ body: 'Your goal target date is today. Keep pushing!' }),
    );
  });

  it('nudges at the user local goal time regardless of server clock (tz-aware)', async () => {
    prisma.goal.findMany.mockResolvedValue([
      goal({ id: 'g-k', userId: 'u-k', user: { timezone: 'Asia/Kolkata' } }),
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    // 2026-08-11 03:30 UTC = 09:00 IST → the Kolkata user's local goal time.
    const ist0900 = new Date(Date.UTC(2026, 7, 11, 3, 30, 0));
    const sent = await service.tick(ist0900);
    expect(sent).toBe(1);
  });

  it('only nudges the users whose local clock says GOAL_REMINDER_TIME', async () => {
    prisma.goal.findMany.mockResolvedValue([
      goal({ id: 'g-k', userId: 'u-k', user: { timezone: 'Asia/Kolkata' } }),
      goal({ id: 'g-u', userId: 'u-u', user: { timezone: 'UTC' } }),
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config());
    // 03:30 UTC: Kolkata is 09:00 (nudge), UTC is 03:30 (no nudge).
    const ist0900 = new Date(Date.UTC(2026, 7, 11, 3, 30, 0));
    const sent = await service.tick(ist0900);
    expect(sent).toBe(1);
    expect(notifications.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u-k' }),
    );
    expect(notifications.create).not.toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u-u' }),
    );
  });

  it('sends both habit and goal reminders in one pass', async () => {
    prisma.habit.findMany.mockResolvedValue([
      {
        id: 'h1',
        userId: 'u1',
        name: 'Run',
        emoji: null,
        repeatDays: [true, true, true, true, true, true, true],
        reminderTime: '07:30',
        user: { timezone: null },
      },
    ]);
    const service = new ReminderSchedulerService(prisma as any, notifications as any, config({
      GOAL_REMINDER_TIME: '07:30',
    }));
    const sent = await service.tick(MON_730);
    expect(sent).toBe(2);
    expect(notifications.create).toHaveBeenCalledTimes(2);
  });
});
