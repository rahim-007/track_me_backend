import {
  GOAL_UNITS,
  currentValueForProgress,
  isAllowedUnit,
  isCountOnlyUnit,
  isCurrencyUnit,
  isWholeUnitValue,
  isValidTargetForUnit,
} from './goal-units';

describe('goal-units', () => {
  describe('isCountOnlyUnit', () => {
    it('flags count and currency units', () => {
      expect(isCountOnlyUnit('books')).toBe(true);
      expect(isCountOnlyUnit('tasks')).toBe(true);
      expect(isCountOnlyUnit('workouts')).toBe(true);
      expect(isCountOnlyUnit('₹')).toBe(true);
      expect(isCountOnlyUnit('$')).toBe(true);
    });

    it('allows measurement units and empty/undefined', () => {
      expect(isCountOnlyUnit('kg')).toBe(false);
      expect(isCountOnlyUnit('km')).toBe(false);
      expect(isCountOnlyUnit('L')).toBe(false);
      expect(isCountOnlyUnit('hours')).toBe(false);
      expect(isCountOnlyUnit('')).toBe(false);
      expect(isCountOnlyUnit(undefined)).toBe(false);
      expect(isCountOnlyUnit(null)).toBe(false);
    });
  });

  describe('isCurrencyUnit', () => {
    it('identifies currency symbols', () => {
      expect(isCurrencyUnit('₹')).toBe(true);
      expect(isCurrencyUnit('$')).toBe(true);
      expect(isCurrencyUnit('€')).toBe(true);
      expect(isCurrencyUnit('£')).toBe(true);
      expect(isCurrencyUnit('books')).toBe(false);
    });
  });

  describe('isAllowedUnit', () => {
    it('accepts units from the list and rejects unknown ones', () => {
      expect(isAllowedUnit('kg')).toBe(true);
      expect(isAllowedUnit('books')).toBe(true);
      expect(isAllowedUnit('widgets')).toBe(false);
      expect(isAllowedUnit(undefined)).toBe(true);
      expect(isAllowedUnit(null)).toBe(true);
      expect(GOAL_UNITS.length).toBeGreaterThan(0);
    });
  });

  describe('isValidTargetForUnit', () => {
    it('accepts decimals for measurement units', () => {
      expect(isValidTargetForUnit(0.5, 'kg')).toBe(true);
      expect(isValidTargetForUnit(1.25, 'kg')).toBe(true);
      expect(isValidTargetForUnit(2.5, 'km')).toBe(true);
      expect(isValidTargetForUnit(3, 'L')).toBe(true);
      expect(isValidTargetForUnit(1.5, 'hours')).toBe(true);
      expect(isValidTargetForUnit(5, undefined)).toBe(true);
    });

    it('rejects fractional targets for count/currency units', () => {
      expect(isValidTargetForUnit(2.5, 'books')).toBe(false);
      expect(isValidTargetForUnit(1.5, 'tasks')).toBe(false);
      expect(isValidTargetForUnit(2.25, 'workouts')).toBe(false);
      expect(isValidTargetForUnit(5000.5, '₹')).toBe(false);
    });

    it('accepts whole-number targets for count/currency units', () => {
      expect(isValidTargetForUnit(10, 'books')).toBe(true);
      expect(isValidTargetForUnit(5, 'tasks')).toBe(true);
      expect(isValidTargetForUnit(2, 'workouts')).toBe(true);
      expect(isValidTargetForUnit(50000, '₹')).toBe(true);
    });

    it('rejects negative or non-numeric targets', () => {
      expect(isValidTargetForUnit(-5, 'kg')).toBe(false);
      expect(isValidTargetForUnit('5', 'kg')).toBe(false);
      expect(isValidTargetForUnit(NaN, 'kg')).toBe(false);
      expect(isValidTargetForUnit(Infinity, 'kg')).toBe(false);
    });
  });

  describe('currentValueForProgress / isWholeUnitValue', () => {
    it('computes the implied unit value from a progress ratio', () => {
      expect(currentValueForProgress(0.1, 5)).toBeCloseTo(0.5);
      expect(currentValueForProgress(0.2, 10)).toBeCloseTo(2);
      expect(currentValueForProgress(0.25, 50000)).toBeCloseTo(12500);
      expect(currentValueForProgress(0.5, 0)).toBeNull();
    });

    it('detects whole numbers within floating-point tolerance', () => {
      expect(isWholeUnitValue(2)).toBe(true);
      expect(isWholeUnitValue(2.0)).toBe(true);
      expect(isWholeUnitValue(0.1 * 10)).toBe(true); // 1.0000000000000002
      expect(isWholeUnitValue(2.5)).toBe(false);
      expect(isWholeUnitValue(5000.5)).toBe(false);
    });
  });
});
