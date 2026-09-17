import {
  computeHabitStreak,
  computeOverallStreaks,
  StreakHabitInput,
  StreakLogInput,
} from './streaks.util';

// All test dates are UTC midnights; 2026-08-10 is a Monday.
const day = (s: string): Date => new Date(`${s}T00:00:00Z`);
const completed = (dates: string[]): Set<string> => new Set(dates);

// repeatDays index 0 = Monday … 6 = Sunday
const monWedFri = [true, false, true, false, true, false, false];
const monFri = [true, false, false, false, true, false, false];
const daily = [false, false, false, false, false, false, false];

describe('computeHabitStreak', () => {
  it('Mon/Wed/Fri all completed → 3 scheduled-day streak (Tue/Thu ignored)', () => {
    const streak = computeHabitStreak(
      { repeatDays: monWedFri },
      completed(['2026-08-10', '2026-08-12', '2026-08-14']),
      day('2026-08-14'),
    );
    expect(streak).toBe(3);
  });

  it('a missing scheduled day breaks the streak', () => {
    // Mon ✅, Wed ❌ missing, Fri ✅ → walking back from Fri breaks at Wed.
    const streak = computeHabitStreak(
      { repeatDays: monWedFri },
      completed(['2026-08-10', '2026-08-14']),
      day('2026-08-14'),
    );
    expect(streak).toBe(1);
  });

  it('a skipped scheduled day breaks the streak', () => {
    // Wed is skipped → not in the completed set → breaks the streak.
    const streak = computeHabitStreak(
      { repeatDays: monWedFri },
      completed(['2026-08-10', '2026-08-14']),
      day('2026-08-14'),
    );
    expect(streak).toBe(1);
  });

  it('unscheduled days never break the streak', () => {
    // Mon ✅, Tue not scheduled, Wed ✅ → streak = 2.
    const streak = computeHabitStreak(
      { repeatDays: monWedFri },
      completed(['2026-08-10', '2026-08-12']),
      day('2026-08-12'),
    );
    expect(streak).toBe(2);
  });

  it('daily habit keeps streak alive on incomplete today (grace period)', () => {
    // Mon ✅, Tue ✅, Wed (today, incomplete) → streak stays 2 from Mon+Tue.
    const streak = computeHabitStreak(
      { repeatDays: daily },
      completed(['2026-08-10', '2026-08-11']),
      day('2026-08-12'),
    );
    expect(streak).toBe(2);
  });

  it('daily habit breaks on a missing past day', () => {
    // Mon ✅, Tue ✅, Wed (missing past day), Thu (today, incomplete) → breaks on Wed (0).
    const streak = computeHabitStreak(
      { repeatDays: daily },
      completed(['2026-08-10', '2026-08-11']),
      day('2026-08-13'),
    );
    expect(streak).toBe(0);
  });

  it('Mon/Fri schedule with both completed → 2 scheduled-day streak', () => {
    const streak = computeHabitStreak(
      { repeatDays: monFri },
      completed(['2026-08-10', '2026-08-14']),
      day('2026-08-14'),
    );
    expect(streak).toBe(2);
  });
});

describe('computeOverallStreaks', () => {
  const habit = (
    id: string,
    repeatDays: boolean[],
    createdAt: string,
  ): StreakHabitInput => ({
    id,
    repeatDays,
    createdAt: day(createdAt),
  });

  const log = (
    habitId: string,
    date: string,
    isSkipped = false,
  ): StreakLogInput => ({
    habitId,
    date: day(date),
    isSkipped,
  });

  it('a skipped habit never counts as completed (2/3 done, day does not count)', () => {
    const a = habit('a', daily, '2026-08-01');
    const b = habit('b', daily, '2026-08-01');
    const c = habit('c', daily, '2026-08-01');

    // Aug 11: all done. Aug 12 (today): A ✅ B ✅ C skipped.
    const logs = [
      log('a', '2026-08-11'),
      log('b', '2026-08-11'),
      log('c', '2026-08-11'),
      log('a', '2026-08-12'),
      log('b', '2026-08-12'),
      log('c', '2026-08-12', true),
    ];

    const { currentStreak, longestStreak } = computeOverallStreaks(
      [a, b, c],
      logs,
      day('2026-08-12'),
    );

    // Aug 11 counts; Aug 12 (skipped habit, grace) does not add.
    expect(currentStreak).toBe(1);
    expect(longestStreak).toBe(1);
  });

  it('a skipped habit on a past scheduled day breaks the streak', () => {
    const a = habit('a', daily, '2026-08-01');
    const b = habit('b', daily, '2026-08-01');
    const c = habit('c', daily, '2026-08-01');

    // Aug 10, 11 all done. Aug 12 (past): C skipped → breaks.
    const logs = [
      log('a', '2026-08-10'),
      log('b', '2026-08-10'),
      log('c', '2026-08-10'),
      log('a', '2026-08-11'),
      log('b', '2026-08-11'),
      log('c', '2026-08-11'),
      log('a', '2026-08-12'),
      log('b', '2026-08-12'),
      log('c', '2026-08-12', true),
    ];

    const { currentStreak } = computeOverallStreaks(
      [a, b, c],
      logs,
      day('2026-08-13'),
    );
    expect(currentStreak).toBe(0);
  });

  it('incomplete today keeps the streak alive (grace period)', () => {
    const a = habit('a', daily, '2026-08-01');
    const b = habit('b', daily, '2026-08-01');

    // Aug 11 all done; Aug 12 (today) not completed yet → grace.
    const logs = [log('a', '2026-08-11'), log('b', '2026-08-11')];

    const { currentStreak } = computeOverallStreaks(
      [a, b],
      logs,
      day('2026-08-12'),
    );
    expect(currentStreak).toBe(1);
  });

  it('a missing habit on a past scheduled day breaks the streak', () => {
    const a = habit('a', daily, '2026-08-01');
    const b = habit('b', daily, '2026-08-01');

    // Aug 11: only A done, B missing → failure on a past day → 0.
    const logs = [log('a', '2026-08-11')];

    const { currentStreak } = computeOverallStreaks(
      [a, b],
      logs,
      day('2026-08-12'),
    );
    expect(currentStreak).toBe(0);
  });

  it('days with nothing scheduled are neutral (ignored)', () => {
    // Mon/Wed/Fri habit: Aug 12 is Wednesday ✅, Aug 11/13 are not scheduled.
    const h = habit('h', monWedFri, '2026-08-01');
    const logs = [log('h', '2026-08-12')];

    const { currentStreak } = computeOverallStreaks(
      [h],
      logs,
      day('2026-08-13'),
    );
    // Aug 12 (Wed) ✅ → 1. Aug 13 (Thu) not scheduled → neutral.
    expect(currentStreak).toBe(1);
  });

  it('empty habits → 0/0', () => {
    expect(computeOverallStreaks([], [], day('2026-08-12'))).toEqual({
      currentStreak: 0,
      longestStreak: 0,
    });
  });

  it('longest streak spans non-consecutive runs', () => {
    const a = habit('a', daily, '2026-08-01');
    const logs = [
      log('a', '2026-08-09'),
      log('a', '2026-08-10'),
      log('a', '2026-08-11'), // run of 3
      // Aug 12 missing → breaks
      log('a', '2026-08-13'),
      log('a', '2026-08-14'), // run of 2 (14 = today)
    ];

    const { currentStreak, longestStreak } = computeOverallStreaks(
      [a],
      logs,
      day('2026-08-14'),
    );
    // Current: Aug 14 ✅, Aug 13 ✅, Aug 12 missing (past) → break → 2.
    expect(currentStreak).toBe(2);
    expect(longestStreak).toBe(3);
  });

  it('skipped logs are never mutated or deleted by the calculation', () => {
    const a = habit('a', daily, '2026-08-01');
    const skipLog = log('a', '2026-08-12', true);
    const logs = [skipLog];

    computeOverallStreaks([a], logs, day('2026-08-12'));
    expect(skipLog.isSkipped).toBe(true);
    expect(logs).toHaveLength(1);
  });

  it('correctly calculates 10, 30, and 100 consecutive completed days for habit and overall', () => {
    const a = habit('a', daily, '2026-01-01');
    const logs: StreakLogInput[] = [];
    const dateSet = new Set<string>();

    const base = new Date('2026-01-01T00:00:00Z');
    for (let i = 0; i < 100; i++) {
      const d = new Date(base);
      d.setUTCDate(d.getUTCDate() + i);
      const str = d.toISOString().split('T')[0];
      logs.push(log('a', str));
      dateSet.add(str);
    }

    const day10 = new Date(base);
    day10.setUTCDate(day10.getUTCDate() + 9);
    const res10 = computeOverallStreaks([a], logs, day10);
    expect(res10.currentStreak).toBe(10);
    expect(res10.longestStreak).toBe(10);

    const day30 = new Date(base);
    day30.setUTCDate(day30.getUTCDate() + 29);
    const res30 = computeOverallStreaks([a], logs, day30);
    expect(res30.currentStreak).toBe(30);
    expect(res30.longestStreak).toBe(30);

    const day100 = new Date(base);
    day100.setUTCDate(day100.getUTCDate() + 99);
    const res100 = computeOverallStreaks([a], logs, day100);
    expect(res100.currentStreak).toBe(100);
    expect(res100.longestStreak).toBe(100);
  });
});

