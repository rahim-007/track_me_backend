export interface FinanceCalculatorInput {
  baseIncome: number;
  baseSavingsTarget: number;
  salarySum: number;
  expensesSum: number;
  todayExpensesSum: number;
  daysInPeriod: number;
  elapsedDays: number;
  remainingDays: number;
  /**
   * When set, uses this as the daily goal instead of dividing the spendable
   * budget by the days in the period. Used to honor a stored budget's
   * remaining-days daily goal (e.g. a budget started on Aug 16).
   */
  dailyGoalOverride?: number;
}

export class FinanceCalculator {
  static calculate(input: FinanceCalculatorInput) {
    const {
      baseIncome,
      baseSavingsTarget,
      salarySum,
      expensesSum,
      todayExpensesSum,
      daysInPeriod,
      elapsedDays,
      remainingDays,
      dailyGoalOverride,
    } = input;

    // 1. Income = Base Income (from budget config) + any salary transactions logged
    const monthlyIncome = baseIncome + salarySum;

    // 2. Savings Target
    const savingsTarget = baseSavingsTarget;

    // 3. Spendable Budget = Monthly Income - Savings Target
    const spendableBudget = monthlyIncome - savingsTarget;

    // 4. Remaining Budget = Spendable Budget - Total Expenses (for the selected period)
    const remainingBudget = spendableBudget - expensesSum;

    // 5. Today's Budget (Daily Budget) = Spendable Budget / Days in Period
    //    (unless the budget was configured with a remaining-days goal).
    const dailyGoal = dailyGoalOverride != null
      ? dailyGoalOverride
      : (daysInPeriod > 0 ? spendableBudget / daysInPeriod : 0);

    // 6. Today's Spending
    const todaySpending = todayExpensesSum;

    // 7. Profit Today = Today's Budget - Today's Spending (only when spending <= Today's Budget)
    const profit = todaySpending <= dailyGoal ? (dailyGoal - todaySpending) : 0;

    // 8. Loss Today = Today's Spending - Today's Budget (only when spending > Today's Budget)
    const loss = todaySpending > dailyGoal ? (todaySpending - dailyGoal) : 0;

    // 9. Current Savings = Monthly Income - Total Expenses
    const currentSavings = monthlyIncome - expensesSum;

    // 10. Savings Progress = (Current Savings / Savings Target) (capped between 0.0 and 1.0)
    const rawProgress = savingsTarget > 0 ? (currentSavings / savingsTarget) : 0;
    const savingsProgress = rawProgress < 0 ? 0 : rawProgress > 1 ? 1 : rawProgress;

    // 11. Savings Rate = (Income - Total Expenses) / Income (capped between 0.0 and 1.0)
    const rawSavingsRate = monthlyIncome > 0 ? (monthlyIncome - expensesSum) / monthlyIncome : 0;
    const savingsRate = rawSavingsRate < 0 ? 0 : rawSavingsRate > 1 ? 1 : rawSavingsRate;

    // 12. Daily Average = Total Spent / Elapsed Days
    const activeElapsedDays = elapsedDays > 0 ? elapsedDays : 1;
    const averageDailyExpense = expensesSum / activeElapsedDays;

    return {
      monthlyIncome,
      savingsTarget,
      spendableBudget,
      remainingBudget,
      dailyGoal,
      todaySpending,
      profit,
      loss,
      currentSavings,
      savingsProgress,
      savingsRate,
      averageDailyExpense,
    };
  }
}
