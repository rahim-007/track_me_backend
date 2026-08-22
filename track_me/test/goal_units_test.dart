import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/goals/data/models/goal_units.dart';

void main() {
  group('unitAllowsDecimals', () {
    test('measurement units allow decimals', () {
      expect(unitAllowsDecimals('kg'), isTrue);
      expect(unitAllowsDecimals('km'), isTrue);
      expect(unitAllowsDecimals('L'), isTrue);
      expect(unitAllowsDecimals('hours'), isTrue);
      expect(unitAllowsDecimals('ml'), isTrue);
    });

    test('count and currency units reject decimals', () {
      expect(unitAllowsDecimals('₹'), isFalse);
      expect(unitAllowsDecimals(r'$'), isFalse);
      expect(unitAllowsDecimals('books'), isFalse);
      expect(unitAllowsDecimals('tasks'), isFalse);
      expect(unitAllowsDecimals('workouts'), isFalse);
      expect(unitAllowsDecimals('reps'), isFalse);
    });

    test('empty or unknown units stay permissive (legacy goals)', () {
      expect(unitAllowsDecimals(''), isTrue);
      expect(unitAllowsDecimals('widgets'), isTrue);
    });
  });

  test('isCurrencyUnitSymbol identifies currency units', () {
    expect(isCurrencyUnitSymbol('₹'), isTrue);
    expect(isCurrencyUnitSymbol(r'$'), isTrue);
    expect(isCurrencyUnitSymbol('€'), isTrue);
    expect(isCurrencyUnitSymbol('£'), isTrue);
    expect(isCurrencyUnitSymbol('books'), isFalse);
    expect(isCurrencyUnitSymbol('kg'), isFalse);
    expect(isCurrencyUnitSymbol(''), isFalse);
  });

  test('defaultUnitForCategory maps categories to sensible units', () {
    expect(defaultUnitForCategory('Fitness'), 'kg');
    expect(defaultUnitForCategory('Finance'), '₹');
    expect(defaultUnitForCategory('Education'), 'hours');
    expect(defaultUnitForCategory('Health'), 'L');
    expect(defaultUnitForCategory('Career'), 'tasks');
    expect(defaultUnitForCategory('Personal'), '');
    expect(defaultUnitForCategory('Other'), '');
  });

  group('formatGoalValue', () {
    test('trims trailing zeros and whole numbers', () {
      expect(formatGoalValue(0.5), '0.5');
      expect(formatGoalValue(1.25), '1.25');
      expect(formatGoalValue(2.5), '2.5');
      expect(formatGoalValue(2.75), '2.75');
      expect(formatGoalValue(5), '5');
      expect(formatGoalValue(50000), '50000');
      expect(formatGoalValue(0.0), '0');
    });
  });

  group('input patterns', () {
    test('decimal pattern allows integers and up to two decimals', () {
      expect(decimalValuePattern.hasMatch(''), isTrue);
      expect(decimalValuePattern.hasMatch('5'), isTrue);
      expect(decimalValuePattern.hasMatch('0.5'), isTrue);
      expect(decimalValuePattern.hasMatch('1.25'), isTrue);
      expect(decimalValuePattern.hasMatch('2.75'), isTrue);
      expect(decimalValuePattern.hasMatch('50000'), isTrue);
      expect(decimalValuePattern.hasMatch('12.'), isTrue); // mid-typing
      expect(decimalValuePattern.hasMatch('1.234'), isFalse);
      expect(decimalValuePattern.hasMatch('abc'), isFalse);
    });

    test('integer pattern blocks decimal points', () {
      expect(integerValuePattern.hasMatch(''), isTrue);
      expect(integerValuePattern.hasMatch('10'), isTrue);
      expect(integerValuePattern.hasMatch('50000'), isTrue);
      expect(integerValuePattern.hasMatch('2.5'), isFalse);
      expect(integerValuePattern.hasMatch('0.5'), isFalse);
      expect(integerValuePattern.hasMatch('12.'), isFalse);
    });
  });
}
