// Unit config for the Goal Tracker.
//
// Every goal can be expressed in a unit (kg, km, L, hours, ₹, books, …) and
// the unit decides whether decimal values are allowed:
//
// - measurement units -> decimals OK (0.5 kg, 1.25 L, 2.5 km, 1.5 hours)
// - count/currency    -> whole numbers only (2 books, 5 tasks, ₹50,000)
//
// This list mirrors `goal-units.ts` on the backend, which enforces the same
// rule server-side so the restriction cannot be bypassed via the API.

class GoalUnit {
  final String symbol;
  final bool allowsDecimals;

  const GoalUnit({required this.symbol, required this.allowsDecimals});
}

/// Units shown in the goal form's unit picker, grouped logically.
const List<GoalUnit> goalUnits = [
  // Measurement — decimals allowed
  GoalUnit(symbol: 'kg', allowsDecimals: true),
  GoalUnit(symbol: 'g', allowsDecimals: true),
  GoalUnit(symbol: 'km', allowsDecimals: true),
  GoalUnit(symbol: 'm', allowsDecimals: true),
  GoalUnit(symbol: 'L', allowsDecimals: true),
  GoalUnit(symbol: 'ml', allowsDecimals: true),
  GoalUnit(symbol: 'hours', allowsDecimals: true),
  GoalUnit(symbol: 'minutes', allowsDecimals: true),
  // Currency — whole numbers only
  GoalUnit(symbol: '₹', allowsDecimals: false),
  GoalUnit(symbol: r'$', allowsDecimals: false),
  GoalUnit(symbol: '€', allowsDecimals: false),
  GoalUnit(symbol: '£', allowsDecimals: false),
  // Count — whole numbers only
  GoalUnit(symbol: 'books', allowsDecimals: false),
  GoalUnit(symbol: 'tasks', allowsDecimals: false),
  GoalUnit(symbol: 'workouts', allowsDecimals: false),
  GoalUnit(symbol: 'reps', allowsDecimals: false),
  GoalUnit(symbol: 'times', allowsDecimals: false),
  GoalUnit(symbol: 'sessions', allowsDecimals: false),
  GoalUnit(symbol: 'days', allowsDecimals: false),
  GoalUnit(symbol: 'pages', allowsDecimals: false),
];

const Set<String> _currencyUnitSymbols = {'₹', r'$', '€', '£'};

/// Whether fractional values are allowed for [unit]. Unknown/empty units
/// default to decimal-allowed so legacy goals (no unit stored) stay permissive.
bool unitAllowsDecimals(String unit) {
  if (unit.isEmpty) return true;
  for (final u in goalUnits) {
    if (u.symbol == unit) return u.allowsDecimals;
  }
  return true;
}

/// True when [unit] is a currency symbol (₹, $, €, £) — displayed as a prefix.
bool isCurrencyUnitSymbol(String unit) => _currencyUnitSymbols.contains(unit);

/// Sensible default unit for a new goal in [category]. Returns '' when the
/// category has no obvious unit (user can pick one explicitly).
String defaultUnitForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'fitness':
      return 'kg';
    case 'finance':
      return '₹';
    case 'education':
      return 'hours';
    case 'health':
      return 'L';
    case 'career':
      return 'tasks';
    default:
      return '';
  }
}

/// Formats a goal value for display, trimming trailing zeros:
/// 0.5 → '0.5', 1.25 → '1.25', 5 → '5', 2.50 → '2.5'.
String formatGoalValue(num value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  var s = value.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return s;
}

/// RegExp for values allowed when [allowsDecimals] is true (max 2 decimals).
final RegExp decimalValuePattern = RegExp(r'^\d{0,9}(\.\d{0,2})?$');

/// RegExp for values allowed when [allowsDecimals] is false (digits only).
final RegExp integerValuePattern = RegExp(r'^\d{0,9}$');
