/**
 * Goal units understood by the Goal Tracker.
 *
 * A goal can be expressed in a unit so the target and progress values are
 * meaningful (e.g. "Lose 5 kg"). Units fall into two buckets:
 *
 * - measurement units  -> fractional values make sense (0.5 kg, 1.25 L, 2.5 km)
 * - count units        -> only whole numbers make sense (2 books, 5 tasks)
 *
 * The unit also decides which numeric keyboard/format the app uses and what the
 * backend accepts for `target` / implied progress values. Keeping the list here
 * (server-side) means API callers cannot bypass the frontend restriction.
 */
export const GOAL_UNITS = [
  // Measurement - decimals allowed
  'kg',
  'g',
  'km',
  'm',
  'L',
  'ml',
  'hours',
  'minutes',
  // Count / currency - whole numbers only
  '₹',
  '$',
  '€',
  '£',
  'books',
  'tasks',
  'workouts',
  'reps',
  'times',
  'sessions',
  'days',
  'pages',
] as const;

export type GoalUnit = (typeof GOAL_UNITS)[number];

/** Units where fractional values do not make sense (money, counts). */
const COUNT_ONLY_UNITS = new Set<string>([
  '₹',
  '$',
  '€',
  '£',
  'books',
  'tasks',
  'workouts',
  'reps',
  'times',
  'sessions',
  'days',
  'pages',
]);

/** Currency symbols are a special count-only case (never fractional money). */
const CURRENCY_UNITS = new Set<string>(['₹', '$', '€', '£']);

export function isAllowedUnit(unit: string | undefined | null): boolean {
  return (
    unit === undefined ||
    unit === null ||
    GOAL_UNITS.includes(unit as GoalUnit)
  );
}

/** True when the unit forbids fractional values (e.g. 'books', '₹'). */
export function isCountOnlyUnit(unit: string | undefined | null): boolean {
  return !!unit && COUNT_ONLY_UNITS.has(unit);
}

/** True when the unit is a currency symbol (₹, $, …). */
export function isCurrencyUnit(unit: string | undefined | null): boolean {
  return !!unit && CURRENCY_UNITS.has(unit);
}

/**
 * Whether a `target` value is acceptable for the given unit.
 *
 * - No unit / measurement unit -> any non-negative number is fine (0.5, 2.75 …).
 * - Count-only unit            -> the target must be a whole number (5, 10, 50000).
 */
export function isValidTargetForUnit(
  target: unknown,
  unit: string | undefined | null,
): boolean {
  if (typeof target !== 'number' || !Number.isFinite(target) || target < 0) {
    return false;
  }
  if (!isCountOnlyUnit(unit)) {
    return true;
  }
  return Number.isInteger(target);
}

/**
 * The implied unit value at a given progress ratio, i.e. progress × target.
 * Returns null when the goal has no measurable target (target <= 0).
 */
export function currentValueForProgress(
  progress: number,
  target: number,
): number | null {
  if (target <= 0) return null;
  return progress * target;
}

/**
 * Whether an implied unit value is a whole number (within floating-point
 * tolerance). Used to reject fractional progress for count-only goals, e.g.
 * "2.5 books" or "5000.50 ₹".
 */
export function isWholeUnitValue(value: number): boolean {
  return Math.abs(value - Math.round(value)) < 1e-6;
}
