import { FinanceCalculator } from './finance-calculator';

describe('FinanceCalculator', () => {
  const base = {
    baseIncome: 20000,
    baseSavingsTarget: 2000,
    salarySum: 0,
    expensesSum: 20,
    todayExpensesSum: 20,
    daysInPeriod: 31,
    elapsedDays: 13,
    remainingDays: 19,
  };

  it('computes income, spendable, and daily goal', () => {
    const r = FinanceCalculator.calculate({ ...base });
    expect(r.monthlyIncome).toBe(20000);
    expect(r.savingsTarget).toBe(2000);
    expect(r.spendableBudget).toBe(18000);
    expect(r.dailyGoal).toBeCloseTo(18000 / 31);
  });

  it('honors the daily goal override (mid-month budget start)', () => {
    const r = FinanceCalculator.calculate({ ...base, dailyGoalOverride: 642.8571428571429 });
    expect(r.dailyGoal).toBeCloseTo(642.8571428571429);
  });

  it('savings rate = (income - expenses) / income, capped at 1', () => {
    const r = FinanceCalculator.calculate({ ...base, expensesSum: 20 });
    expect(r.savingsRate).toBeCloseTo((20000 - 20) / 20000, 6);
  });

  it('savings rate is 0 when expenses exceed income', () => {
    const r = FinanceCalculator.calculate({ ...base, expensesSum: 25000 });
    expect(r.savingsRate).toBe(0);
  });

  it('profit today is positive when under the daily limit', () => {
    const r = FinanceCalculator.calculate({ ...base, todayExpensesSum: 20, dailyGoalOverride: 643 });
    expect(r.profit).toBeCloseTo(623);
    expect(r.loss).toBe(0);
  });

  it('loss today is positive when over the daily limit', () => {
    const r = FinanceCalculator.calculate({ ...base, todayExpensesSum: 800, dailyGoalOverride: 643 });
    expect(r.loss).toBeCloseTo(157);
    expect(r.profit).toBe(0);
  });
});
