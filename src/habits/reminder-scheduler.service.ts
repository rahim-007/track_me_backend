import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

/**
 * Backend reminder scheduler.
 *
 * Runs every minute and handles two kinds of reminders:
 *
 * 1. Habit reminders — active habits whose `reminderTime` (HH:MM) matches the
 *    user's local clock and whose `repeatDays` includes the user's local
 *    weekday. Creates an in-app notification + FCM push for each due habit.
 * 2. Goal reminders — in-progress goals whose `targetDate` falls within the
 *    reminder window (GOAL_REMINDER_DAYS, default 7), nudged once per goal per
 *    day at the user's local GOAL_REMINDER_TIME (default 09:00), skipping
 *    completed/overdue goals.
 *
 * **Timezone resolution** — each user's stored `timezone` (IANA name) decides
 * what "now" means for them, so a 07:00 habit or the 09:00 goal nudge fires at
 * the user's own local clock. Fallback chain:
 *   1. user.timezone          (stored per-user, set from the app)
 *   2. REMINDER_TIMEZONE env  (global fallback for users without one)
 *   3. server-local time
 *
 * Both passes are idempotent: a habit/goal is reminded at most once per local
 * calendar day (checked against today's HABIT_REMINDER / GOAL_REMINDER
 * notifications in the DB, so restarts cannot cause duplicates). Habits
 * already completed today are skipped.
 *
 * Configuration (all optional):
 *   HABIT_REMINDERS_ENABLED           (default "true")
 *   HABIT_REMINDER_CHECK_INTERVAL_MS  (default 60000)
 *   REMINDER_TIMEZONE                 (IANA fallback for users with no
 *                                      timezone; default = server local)
 *   GOAL_REMINDER_DAYS                (default 7)
 *   GOAL_REMINDER_TIME                (HH:MM, default "09:00")
 */
@Injectable()
export class ReminderSchedulerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ReminderSchedulerService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;
  private readonly fallbackTimezone: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
  ) {
    this.fallbackTimezone = this.config.get<string>('REMINDER_TIMEZONE', '') ?? '';
  }

  onModuleInit() {
    if (this.config.get<string>('HABIT_REMINDERS_ENABLED', 'true') === 'false') {
      this.logger.log('Reminders disabled (HABIT_REMINDERS_ENABLED=false)');
      return;
    }
    const intervalMs =
      this.config.get<number>('HABIT_REMINDER_CHECK_INTERVAL_MS', 60_000) ?? 60_000;

    // First pass shortly after boot, then on the interval.
    setTimeout(() => void this.tickSafe(), 5_000);
    this.timer = setInterval(() => void this.tickSafe(), intervalMs);
    this.logger.log(
      `Reminder scheduler started (every ${intervalMs}ms, fallback tz="${
        this.fallbackTimezone || 'local'
      }")`,
    );
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  private async tickSafe(): Promise<void> {
    if (this.running) return;
    this.running = true;
    try {
      await this.tick();
    } catch (e) {
      this.logger.error(`Reminder pass failed: ${(e as Error).message}`);
    } finally {
      this.running = false;
    }
  }

  /**
   * One scheduler pass: fires due habit reminders AND the daily goal check.
   * Public + injectable `now` so it's unit-testable.
   * @returns how many reminders were sent (habit + goal).
   */
  async tick(now: Date = new Date()): Promise<number> {
    const habitSent = await this.checkHabitReminders(now);
    const goalSent = await this.checkGoalReminders(now);
    return habitSent + goalSent;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Habit reminders
  // ───────────────────────────────────────────────────────────────────────────

  private async checkHabitReminders(now: Date): Promise<number> {
    // Every active habit that has a reminder time. Per-user timezone matching
    // happens in JS below — a single global HH:MM filter would miss users in
    // other timezones.
    const habits = await this.prisma.habit.findMany({
      where: {
        isActive: true,
        reminderTime: { not: null },
      },
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

    // Due = reminder time matches the user's local clock AND the weekday is
    // scheduled. Grouped by effective timezone so "today" (for the idempotency
    // and completion checks below) is each user's local calendar day.
    const groups = new Map<string, HabitRow[]>();
    for (const h of habits) {
      const tz = this.effectiveTz(h.user?.timezone);
      const { hhmm, weekday } = this.timeParts(now, tz);
      if (h.reminderTime !== hhmm) continue;
      if (!Array.isArray(h.repeatDays) || h.repeatDays[weekday] !== true) continue;
      const list = groups.get(tz) ?? [];
      list.push(h);
      groups.set(tz, list);
    }
    if (groups.size === 0) return 0;

    let sent = 0;
    for (const [tz, due] of groups) {
      const { dateStr } = this.timeParts(now, tz);
      const startOfToday = new Date(`${dateStr}T00:00:00.000Z`);
      const userIds = [...new Set(due.map((h) => h.userId))];
      const habitIds = due.map((h) => h.id);

      const [sentToday, completedToday] = await Promise.all([
        // Idempotency: what has already been pushed today (restart-safe).
        this.prisma.notification.findMany({
          where: {
            userId: { in: userIds },
            type: 'HABIT_REMINDER',
            sentAt: { gte: startOfToday },
          },
          select: { userId: true, data: true },
        }),
        // Don't remind for something already done today.
        this.prisma.habitLog.findMany({
          where: {
            habitId: { in: habitIds },
            date: startOfToday,
            isSkipped: false,
          },
          select: { habitId: true },
        }),
      ]);

      const alreadySent = new Set(
        sentToday
          .map((n) => `${n.userId}:${(n.data as any)?.relatedId}`)
          .filter((k) => !k.endsWith('undefined')),
      );
      const completed = new Set(completedToday.map((l) => l.habitId));

      for (const habit of due) {
        if (alreadySent.has(`${habit.userId}:${habit.id}`)) continue;
        if (completed.has(habit.id)) continue;

        try {
          await this.notifications.create({
            userId: habit.userId,
            type: 'HABIT_REMINDER',
            title: `⏰ ${habit.emoji ? habit.emoji + ' ' : ''}${habit.name}`,
            body: 'Time to complete this habit. Keep your streak alive!',
            data: {
              category: 'habit',
              relatedId: habit.id,
              relatedType: 'habit',
              route: '/habits',
            },
          });
          sent++;
        } catch (e) {
          this.logger.error(
            `Failed to send reminder for habit ${habit.id}: ${(e as Error).message}`,
          );
        }
      }
    }

    if (sent > 0) this.logger.log(`Sent ${sent} habit reminder(s)`);
    return sent;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Goal reminders
  // ───────────────────────────────────────────────────────────────────────────

  private async checkGoalReminders(now: Date): Promise<number> {
    const goalTime = this.config.get<string>('GOAL_REMINDER_TIME', '09:00') ?? '09:00';
    const windowDays = this.config.get<number>('GOAL_REMINDER_DAYS', 7) ?? 7;

    // Coarse server-side prune with a generous margin (user timezones span
    // roughly ±14h around UTC); the exact per-user window is checked in JS.
    const coarseGte = new Date(now.getTime() - 2 * 86_400_000);
    const coarseLte = new Date(now.getTime() + (windowDays + 2) * 86_400_000);

    const goals = await this.prisma.goal.findMany({
      where: {
        // Only goals that are actively being worked on.
        status: { in: ['NOT_STARTED', 'IN_PROGRESS'] },
        targetDate: { gte: coarseGte, lte: coarseLte },
      },
      select: {
        id: true,
        userId: true,
        name: true,
        targetDate: true,
        user: { select: { timezone: true } },
      },
    });
    if (goals.length === 0) return 0;

    // The goal pass fires once per day per user at their local goalTime.
    // Grouped by effective timezone so the window + "sent today" boundary are
    // each user's local calendar day.
    const groups = new Map<string, { goal: GoalRow; startOfToday: Date }[]>();
    for (const g of goals) {
      const tz = this.effectiveTz(g.user?.timezone);
      const parts = this.timeParts(now, tz);
      if (parts.hhmm !== goalTime) continue;

      const startOfToday = new Date(`${parts.dateStr}T00:00:00.000Z`);
      const windowEnd = new Date(startOfToday);
      windowEnd.setUTCDate(windowEnd.getUTCDate() + windowDays);
      if (g.targetDate < startOfToday || g.targetDate > windowEnd) continue;

      const list = groups.get(tz) ?? [];
      list.push({ goal: g, startOfToday });
      groups.set(tz, list);
    }
    if (groups.size === 0) return 0;

    let sent = 0;
    for (const [, due] of groups) {
      const userIds = [...new Set(due.map((d) => d.goal.userId))];

      // Idempotency: a goal is nudged at most once per (local) day.
      const sentToday = await this.prisma.notification.findMany({
        where: {
          userId: { in: userIds },
          type: 'GOAL_REMINDER',
          sentAt: { gte: due[0].startOfToday },
        },
        select: { userId: true, data: true },
      });
      const alreadySent = new Set(
        sentToday
          .map((n) => `${n.userId}:${(n.data as any)?.relatedId}`)
          .filter((k) => !k.endsWith('undefined')),
      );

      for (const { goal, startOfToday } of due) {
        if (alreadySent.has(`${goal.userId}:${goal.id}`)) continue;

        const left = Math.max(
          Math.ceil(
            (goal.targetDate.getTime() - startOfToday.getTime()) / 86_400_000,
          ),
          0,
        );
        const when =
          left === 0 ? 'today' : left === 1 ? 'tomorrow' : `in ${left} days`;

        try {
          await this.notifications.create({
            userId: goal.userId,
            type: 'GOAL_REMINDER',
            title: `🎯 ${goal.name}`,
            body: `Your goal target date is ${when}. Keep pushing!`,
            data: {
              category: 'goals',
              relatedId: goal.id,
              relatedType: 'goal',
              route: '/goals',
            },
          });
          sent++;
        } catch (e) {
          this.logger.error(
            `Failed to send reminder for goal ${goal.id}: ${(e as Error).message}`,
          );
        }
      }
    }

    if (sent > 0) this.logger.log(`Sent ${sent} goal reminder(s)`);
    return sent;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Time helpers
  // ───────────────────────────────────────────────────────────────────────────

  /**
   * Effective timezone for a user: their stored IANA timezone, falling back to
   * the global REMINDER_TIMEZONE env, then '' = server-local time.
   */
  private effectiveTz(userTz?: string | null): string {
    const tz = userTz?.trim();
    return tz ? tz : this.fallbackTimezone;
  }

  /**
   * Resolve the effective time in the given timezone (or server-local when tz
   * is empty). Returns the "HH:MM" string, weekday index (0 = Monday) and the
   * YYYY-MM-DD date string — all in that same zone so matching is consistent.
   */
  private timeParts(now: Date, tz: string): {
    hhmm: string;
    weekday: number;
    dateStr: string;
  } {
    const pad = (n: number) => String(n).padStart(2, '0');
    const zoned = tz ? this.toZoneParts(now, tz) : null;

    if (!zoned) {
      // Server-local fallback (invalid/empty timezone).
      const hhmm = `${pad(now.getHours())}:${pad(now.getMinutes())}`;
      const weekday = (now.getDay() + 6) % 7;
      const dateStr =
        `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
      return { hhmm, weekday, dateStr };
    }

    const { hour, minute, weekday, year, month, day } = zoned;
    return {
      hhmm: `${pad(hour)}:${pad(minute)}`,
      weekday,
      dateStr: `${year}-${pad(month)}-${pad(day)}`,
    };
  }

  /** Extract date/time parts in an IANA timezone; null if invalid. */
  private toZoneParts(
    now: Date,
    tz: string,
  ): {
    hour: number;
    minute: number;
    weekday: number;
    year: number;
    month: number;
    day: number;
  } | null {
    try {
      const fmt = new Intl.DateTimeFormat('en-US', {
        timeZone: tz,
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        hourCycle: 'h23',
        weekday: 'short',
      });
      const parts = fmt.formatToParts(now);
      const get = (t: string) => parts.find((p) => p.type === t)?.value;
      let hour = Number(get('hour'));
      const minute = Number(get('minute'));
      if (Number.isNaN(hour) || Number.isNaN(minute)) return null;
      if (hour === 24) hour = 0; // h23 shouldn't emit 24, but be defensive

      const weekdayNames: Record<string, number> = {
        Sun: 6, Mon: 0, Tue: 1, Wed: 2, Thu: 3, Fri: 4, Sat: 5,
      };
      return {
        hour,
        minute,
        weekday: weekdayNames[get('weekday') ?? ''] ?? 0,
        year: Number(get('year')),
        month: Number(get('month')),
        day: Number(get('day')),
      };
    } catch {
      return null;
    }
  }
}

type HabitRow = {
  id: string;
  userId: string;
  name: string;
  emoji: string | null;
  repeatDays: boolean[];
  reminderTime: string | null;
  user?: { timezone: string | null } | null;
};

type GoalRow = {
  id: string;
  userId: string;
  name: string;
  targetDate: Date;
  user?: { timezone: string | null } | null;
};
