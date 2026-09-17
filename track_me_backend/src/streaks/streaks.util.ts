/**
 * Shared streak calculations.
 *
 * Single source of truth for both streak concepts so the client and server
 * (and the per-habit vs overall views) always agree:
 *
 * - Skipped is NOT completed. A skipped log can never satisfy a day.
 * - Per-habit streak evaluates only scheduled days (repeatDays); unscheduled
 *   days are ignored and never break the streak.
 * - Overall streak counts a day only when EVERY habit scheduled that day has
 *   a valid non-skipped completion.
 * - Today keeps its grace period: an incomplete/skipped today does not break
 *   the current streak (it simply does not count).
 *
 * Dates are handled as UTC 'yyyy-MM-dd' strings — the same convention the
 * backend uses everywhere else (logs are stored at UTC midnight and surfaced
 * as `toISOString().split('T')[0]`), so results are timezone-independent.
 */

export interface StreakHabitInput {
  id: string;
  createdAt: Date;
  repeatDays: boolean[];
}

export interface StreakLogInput {
  habitId: string;
  date: Date;
  isSkipped: boolean;
}

const MAX_SCAN_DAYS = 366;

/** 'yyyy-MM-dd' UTC date string for a Date. */
function toDateStr(d: Date): string {
  return d.toISOString().split('T')[0];
}

/**
 * Weekday index (0 = Monday, 6 = Sunday) derived from a 'yyyy-MM-dd' string.
 * Parsing the string is timezone-independent.
 */
function weekdayIndexFromDateStr(dateStr: string): number {
  const [y, m, d] = dateStr.split('-').map(Number);
  const utcDay = new Date(Date.UTC(y, m - 1, d)).getUTCDay(); // 0 = Sunday
  return utcDay === 0 ? 6 : utcDay - 1;
}

/**
 * A habit with no repeat day selected is treated as daily (scheduled every
 * day), matching the app's habit list behavior.
 */
function isScheduled(repeatDays: boolean[], weekdayIndex: number): boolean {
  const hasRepeatDay = repeatDays.some((d) => d);
  if (!hasRepeatDay) return true;
  return !!repeatDays[weekdayIndex];
}

/**
 * Resolves the user's current local calendar date as a UTC midnight Date.
 * If timezone is omitted or invalid, falls back to UTC.
 */
export function getUserNow(timezone?: string | null, date: Date = new Date()): Date {
  if (!timezone) return date;
  try {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    const formatted = formatter.format(date); // "YYYY-MM-DD"
    const [y, m, d] = formatted.split('-').map(Number);
    if (!isNaN(y) && !isNaN(m) && !isNaN(d)) {
      return new Date(Date.UTC(y, m - 1, d));
    }
  } catch (_) {
    // Unsupported or malformed timezone name -> fallback to UTC date
  }
  return date;
}

/**
 * Calculates both per-habit current streak and longest streak across the habit's
 * lifetime (up to MAX_SCAN_DAYS).
 *
 * `completedDateStrs` must contain only non-skipped completion dates.
 */
export function computeHabitStreaks(
  habit: Pick<StreakHabitInput, 'repeatDays'> & { createdAt?: Date },
  completedDateStrs: Set<string>,
  now: Date = new Date(),
): { currentStreak: number; longestStreak: number } {
  let currentStreak = 0;
  const todayStr = toDateStr(now);
  const earliestStr = habit.createdAt ? toDateStr(habit.createdAt) : '1970-01-01';

  const dateStrings: string[] = [];
  const checkDate = new Date(now);
  let checkDateStr = toDateStr(checkDate);
  const scanLimit = new Date(now);
  scanLimit.setUTCDate(scanLimit.getUTCDate() - MAX_SCAN_DAYS);
  const scanLimitStr = toDateStr(scanLimit);
  const cutoffStr = earliestStr > scanLimitStr ? earliestStr : scanLimitStr;

  while (checkDateStr >= cutoffStr) {
    dateStrings.push(checkDateStr);
    checkDate.setUTCDate(checkDate.getUTCDate() - 1);
    checkDateStr = toDateStr(checkDate);
  }

  // Walk backward for currentStreak
  for (const dateStr of dateStrings) {
    const repeatIndex = weekdayIndexFromDateStr(dateStr);
    if (!isScheduled(habit.repeatDays, repeatIndex)) {
      continue;
    }
    if (completedDateStrs.has(dateStr)) {
      currentStreak++;
    } else {
      // Today is in progress (grace period) — keep the streak from yesterday
      if (dateStr === todayStr) {
        continue;
      } else {
        break;
      }
    }
  }

  // Walk forward for longestStreak
  let longestStreak = 0;
  let tempStreak = 0;
  const chronologicalDates = [...dateStrings].reverse();
  for (const dateStr of chronologicalDates) {
    const repeatIndex = weekdayIndexFromDateStr(dateStr);
    if (!isScheduled(habit.repeatDays, repeatIndex)) {
      continue;
    }
    if (completedDateStrs.has(dateStr)) {
      tempStreak++;
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }
    } else {
      if (dateStr === todayStr) {
        // Incomplete today does not reset historical longest streak
      } else {
        tempStreak = 0;
      }
    }
  }

  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  return { currentStreak, longestStreak };
}

/**
 * Per-habit streak: consecutive scheduled days (walking backward from `now`)
 * with a valid non-skipped completion. Unscheduled days are ignored; a
 * scheduled day that is missing or skipped breaks the streak.
 *
 * `completedDateStrs` must contain only non-skipped completion dates.
 */
export function computeHabitStreak(
  habit: Pick<StreakHabitInput, 'repeatDays'> & { createdAt?: Date },
  completedDateStrs: Set<string>,
  now: Date = new Date(),
): number {
  return computeHabitStreaks(habit, completedDateStrs, now).currentStreak;
}

/**
 * Overall user streak: walks day by day backward from `now`. A day counts
 * only when every habit scheduled that day has a valid non-skipped
 * completion. Days with nothing scheduled are neutral (ignored). Today keeps
 * its grace period (an incomplete/skipped today does not break the streak).
 */
export function computeOverallStreaks(
  habits: StreakHabitInput[],
  logs: StreakLogInput[],
  now: Date = new Date(),
): { currentStreak: number; longestStreak: number } {
  if (habits.length === 0) {
    return { currentStreak: 0, longestStreak: 0 };
  }

  // Earliest habit creation date.
  let earliestHabitDate = habits[0].createdAt;
  for (const h of habits) {
    if (h.createdAt < earliestHabitDate) earliestHabitDate = h.createdAt;
  }

  // Cap the scan window to one year so streak computation stays fast for
  // long-time users instead of walking every day since the first habit.
  const windowStart = new Date(now);
  windowStart.setUTCDate(windowStart.getUTCDate() - MAX_SCAN_DAYS);
  const scanStart =
    earliestHabitDate < windowStart ? windowStart : earliestHabitDate;

  // Group logs by date string (yyyy-MM-dd).
  const logsByDate = new Map<string, StreakLogInput[]>();
  for (const log of logs) {
    const dateStr = toDateStr(log.date);
    const existing = logsByDate.get(dateStr);
    if (existing) {
      existing.push(log);
    } else {
      logsByDate.set(dateStr, [log]);
    }
  }

  const todayStr = toDateStr(now);
  const earliestStr = toDateStr(scanStart);

  const dateStrings: string[] = [];
  const checkDate = new Date(now);
  let checkDateStr = toDateStr(checkDate);
  while (checkDateStr >= earliestStr) {
    dateStrings.push(checkDateStr);
    checkDate.setUTCDate(checkDate.getUTCDate() - 1);
    checkDateStr = toDateStr(checkDate);
  }

  const dayStatus = new Map<string, 'success' | 'failure' | 'neutral'>();

  for (const dateStr of dateStrings) {
    const repeatIndex = weekdayIndexFromDateStr(dateStr);

    const scheduledHabits = habits.filter(
      (h) =>
        isScheduled(h.repeatDays, repeatIndex) &&
        toDateStr(h.createdAt) <= dateStr,
    );

    if (scheduledHabits.length === 0) {
      dayStatus.set(dateStr, 'neutral');
      continue;
    }

    const dayLogs = logsByDate.get(dateStr) ?? [];
    // A skipped log must NEVER satisfy the completion requirement.
    const allDone = scheduledHabits.every((h) =>
      dayLogs.some((l) => l.habitId === h.id && !l.isSkipped),
    );

    dayStatus.set(dateStr, allDone ? 'success' : 'failure');
  }

  let currentStreak = 0;
  for (const dateStr of dateStrings) {
    const status = dayStatus.get(dateStr);
    if (status === 'success') {
      currentStreak++;
    } else if (status === 'failure') {
      // Today is not done yet — keep the streak alive (grace period).
      if (dateStr === todayStr) {
        continue;
      } else {
        break;
      }
    } else {
      continue;
    }
  }

  let longestStreak = 0;
  let tempStreak = 0;
  const chronologicalDates = [...dateStrings].reverse();
  for (const dateStr of chronologicalDates) {
    const status = dayStatus.get(dateStr);
    if (status === 'success') {
      tempStreak++;
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }
    } else if (status === 'failure') {
      if (dateStr === todayStr) {
        // ignore
      } else {
        tempStreak = 0;
      }
    } else {
      // ignore
    }
  }

  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  return { currentStreak, longestStreak };
}
