import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { FinanceCalculator } from './finance-calculator';

@Injectable()
export class ExpensesService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Budget ──────────────────────────────────────────────────────────────────

  private getDaysInMonth(month: number, year: number): number {
    return new Date(year, month, 0).getDate();
  }

  async calculateMonthlyProfitLoss(
    userId: string,
    month: number,
    year: number,
    dailyGoal: number,
    referenceDate: Date = new Date(),
  ) {
    const startDate = new Date(Date.UTC(year, month - 1, 1));
    const endDate = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));

    const expenses = await this.prisma.expense.findMany({
      where: {
        userId,
        category: { not: 'SALARY' },
        date: { gte: startDate, lte: endDate },
      },
    });

    const dailySpendingMap: Record<string, number> = {};
    for (const exp of expenses) {
      const dateStr = exp.date.toISOString().split('T')[0];
      dailySpendingMap[dateStr] = (dailySpendingMap[dateStr] || 0) + exp.amount;
    }

    let monthlyProfit = 0;
    let monthlyLoss = 0;

    const daysInMonth = this.getDaysInMonth(month, year);
    const isCurrentMonth = referenceDate.getUTCMonth() + 1 === month && referenceDate.getUTCFullYear() === year;
    const maxDay = isCurrentMonth ? referenceDate.getUTCDate() - 1 : daysInMonth;

    for (let day = 1; day <= maxDay; day++) {
      const currentDayDate = new Date(Date.UTC(year, month - 1, day));
      const dateKey = currentDayDate.toISOString().split('T')[0];
      const spentToday = dailySpendingMap[dateKey] ?? 0;

      const difference = dailyGoal - spentToday;
      if (difference > 0) {
        monthlyProfit += difference;
      } else if (difference < 0) {
        monthlyLoss += Math.abs(difference);
      }
    }

    return { monthlyProfit, monthlyLoss };
  }

  async recalculateCurrentBudgetProfitLoss(userId: string, month: number, year: number, referenceDate: Date = new Date()) {
    const budget = await this.prisma.monthlyBudget.findUnique({
      where: { userId_month_year: { userId, month, year } }
    });
    if (!budget) return;

    const { monthlyProfit, monthlyLoss } = await this.calculateMonthlyProfitLoss(
      userId,
      month,
      year,
      budget.dailyGoal,
      referenceDate
    );

    await this.prisma.monthlyBudget.update({
      where: { id: budget.id },
      data: {
        monthlyProfit,
        monthlyLoss
      }
    });
  }

  async processPendingSettlements(userId: string, referenceDate: Date = new Date()) {
    const currentMonth = referenceDate.getUTCMonth() + 1;
    const currentYear = referenceDate.getUTCFullYear();

    const unsettledPastBudgets = await this.prisma.monthlyBudget.findMany({
      where: {
        userId,
        settled: false,
        OR: [
          { year: { lt: currentYear } },
          { year: currentYear, month: { lt: currentMonth } }
        ]
      },
      orderBy: [
        { year: 'asc' },
        { month: 'asc' }
      ]
    });

    for (const budget of unsettledPastBudgets) {
      const { monthlyProfit, monthlyLoss } = await this.calculateMonthlyProfitLoss(
        userId,
        budget.month,
        budget.year,
        budget.dailyGoal
      );

      const netResult = monthlyProfit - monthlyLoss;

      const user = await this.prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) continue;

      const savingsBeforeSettlement = user.savingsBalance;
      const savingsAfterSettlement = savingsBeforeSettlement + netResult;

      await this.prisma.$transaction(async (tx) => {
        await tx.user.update({
          where: { id: userId },
          data: { savingsBalance: savingsAfterSettlement }
        });

        const endOfMonth = new Date(Date.UTC(budget.year, budget.month, 0, 23, 59, 59, 999));
        
        const expensesSumAggregate = await tx.expense.aggregate({
          where: {
            userId,
            category: { not: 'SALARY' },
            date: {
              gte: new Date(Date.UTC(budget.year, budget.month - 1, 1)),
              lte: endOfMonth
            }
          },
          _sum: { amount: true }
        });
        const totalExpenses = expensesSumAggregate._sum.amount ?? 0;

        await tx.monthlyBudget.update({
          where: { id: budget.id },
          data: {
            monthlyProfit,
            monthlyLoss,
            settled: true
          }
        });

        await tx.monthlySettlement.create({
          data: {
            userId,
            month: budget.month,
            year: budget.year,
            totalBudget: budget.spendableBudget,
            totalExpenses,
            totalProfit: monthlyProfit,
            totalLoss: monthlyLoss,
            netResult,
            savingsBeforeSettlement,
            savingsAfterSettlement,
            settlementDate: new Date()
          }
        });
      });
    }
  }

  async upsertBudget(userId: string, dto: CreateBudgetDto) {
    const now = new Date();
    const month = dto.month ?? now.getMonth() + 1;
    const year = dto.year ?? now.getFullYear();
    const daysInMonth = this.getDaysInMonth(month, year);
    const spendableBudget = dto.monthlyIncome - dto.savingsTarget;
    const dailyGoal = daysInMonth > 0 ? spendableBudget / daysInMonth : 0;

    const budget = await this.prisma.monthlyBudget.upsert({
      where: {
        userId_month_year: { userId, month, year },
      },
      create: {
        userId,
        month,
        year,
        monthlyIncome: dto.monthlyIncome,
        savingsTarget: dto.savingsTarget,
        spendableBudget,
        dailyGoal,
        daysInMonth,
      },
      update: {
        monthlyIncome: dto.monthlyIncome,
        savingsTarget: dto.savingsTarget,
        spendableBudget,
        dailyGoal,
        daysInMonth,
      },
    });

    await this.processPendingSettlements(userId);
    await this.recalculateCurrentBudgetProfitLoss(userId, month, year);

    return budget;
  }

  async getBudget(userId: string, month: number, year: number) {
    const budget = await this.prisma.monthlyBudget.findUnique({
      where: {
        userId_month_year: { userId, month, year },
      },
    });

    if (budget) {
      return budget;
    }

    // Fallback: check if salary transactions exist for this month to construct a virtual budget
    const startOfMonth = new Date(Date.UTC(year, month - 1, 1));
    const endOfMonth = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));

    const salarySumAggregate = await this.prisma.expense.aggregate({
      where: {
        userId,
        category: 'SALARY',
        date: { gte: startOfMonth, lte: endOfMonth },
      },
      _sum: { amount: true },
    });

    const salarySum = salarySumAggregate._sum.amount ?? 0;

    if (salarySum > 0) {
      const daysInMonth = this.getDaysInMonth(month, year);
      const savingsTarget = salarySum * 0.20; // default 20%
      const spendableBudget = salarySum - savingsTarget;
      const dailyGoal = daysInMonth > 0 ? spendableBudget / daysInMonth : 0;

      return {
        id: `virtual_${userId}_${month}_${year}`,
        userId,
        month,
        year,
        monthlyIncome: salarySum,
        savingsTarget,
        spendableBudget,
        dailyGoal,
        daysInMonth,
        monthlyProfit: 0.0,
        monthlyLoss: 0.0,
        settled: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    }

    return null;
  }

  async getCurrentBudget(userId: string) {
    const now = new Date();
    return this.getBudget(userId, now.getMonth() + 1, now.getFullYear());
  }

  // ─── Expenses ────────────────────────────────────────────────────────────────

  async createExpense(userId: string, dto: CreateExpenseDto) {
    let date: Date;
    if (dto.date) {
      date = new Date(`${dto.date}T00:00:00.000Z`);
    } else {
      date = new Date();
      date.setUTCHours(0, 0, 0, 0);
    }

    const time = dto.time ?? `${new Date().getHours().toString().padStart(2, '0')}:${new Date().getMinutes().toString().padStart(2, '0')}`;

    const expense = await this.prisma.expense.create({
      data: {
        userId,
        title: dto.title,
        amount: dto.amount,
        category: dto.category ?? 'OTHER',
        paymentMethod: dto.paymentMethod ?? 'CASH',
        date,
        time,
        notes: dto.notes,
      },
    });

    await this.processPendingSettlements(userId);
    if (expense.category !== 'SALARY') {
      const month = date.getUTCMonth() + 1;
      const year = date.getUTCFullYear();
      await this.recalculateCurrentBudgetProfitLoss(userId, month, year);
    }

    return expense;
  }

  async updateExpense(userId: string, id: string, dto: UpdateExpenseDto) {
    const data: any = { ...dto };
    if (dto.date) {
      data.date = new Date(`${dto.date}T00:00:00.000Z`);
    }

    const originalExpense = await this.prisma.expense.findFirst({
      where: { id, userId }
    });

    const result = await this.prisma.expense.updateMany({
      where: { id, userId },
      data,
    });

    if (originalExpense) {
      await this.processPendingSettlements(userId);
      const origMonth = originalExpense.date.getUTCMonth() + 1;
      const origYear = originalExpense.date.getUTCFullYear();
      await this.recalculateCurrentBudgetProfitLoss(userId, origMonth, origYear);

      if (dto.date) {
        const newDate = new Date(`${dto.date}T00:00:00.000Z`);
        const newMonth = newDate.getUTCMonth() + 1;
        const newYear = newDate.getUTCFullYear();
        if (newMonth !== origMonth || newYear !== origYear) {
          await this.recalculateCurrentBudgetProfitLoss(userId, newMonth, newYear);
        }
      }
    }

    return result;
  }

  async deleteExpense(userId: string, id: string) {
    const originalExpense = await this.prisma.expense.findFirst({
      where: { id, userId }
    });

    const result = await this.prisma.expense.deleteMany({
      where: { id, userId },
    });

    if (originalExpense) {
      await this.processPendingSettlements(userId);
      const month = originalExpense.date.getUTCMonth() + 1;
      const year = originalExpense.date.getUTCFullYear();
      await this.recalculateCurrentBudgetProfitLoss(userId, month, year);
    }

    return result;
  }

  async getExpenses(userId: string, month?: number, year?: number) {
    // When a specific month/year is provided, scope the query to that month.
    // Otherwise return ALL transactions for the user (newest first) so the
    // "All Transactions" screen and the dashboard share the same source of truth.
    if (month && year) {
      const startDate = new Date(Date.UTC(year, month - 1, 1));
      const endDate = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));

      return this.prisma.expense.findMany({
        where: {
          userId,
          date: { gte: startDate, lte: endDate },
        },
        orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
      });
    }

    return this.prisma.expense.findMany({
      where: {
        userId,
      },
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });
  }

  // ─── Dashboard ───────────────────────────────────────────────────────────────

  private calculatePeriodBoundaries(todayStr?: string, filter?: string, startDateStr?: string, endDateStr?: string) {
    const referenceDate = todayStr ? new Date(`${todayStr}T00:00:00.000Z`) : new Date();
    const todayStart = new Date(referenceDate);
    todayStart.setUTCHours(0, 0, 0, 0);
    const todayEnd = new Date(referenceDate);
    todayEnd.setUTCHours(23, 59, 59, 999);

    let periodStart = new Date(todayStart);
    let periodEnd = new Date(todayEnd);
    let daysInPeriod = 1;
    let elapsedDays = 1;
    let remainingDays = 1;

    const selectedFilter = filter ?? 'thisMonth';

    if (selectedFilter === 'today') {
      periodStart = new Date(todayStart);
      periodEnd = new Date(todayEnd);
      daysInPeriod = 1;
      elapsedDays = 1;
      remainingDays = 1;
    } else if (selectedFilter === 'yesterday') {
      const yesterday = new Date(todayStart);
      yesterday.setUTCDate(todayStart.getUTCDate() - 1);
      periodStart = new Date(yesterday);
      periodStart.setUTCHours(0, 0, 0, 0);
      periodEnd = new Date(yesterday);
      periodEnd.setUTCHours(23, 59, 59, 999);
      daysInPeriod = 1;
      elapsedDays = 1;
      remainingDays = 1;
    } else if (selectedFilter === 'thisWeek') {
      const dayOfWeek = referenceDate.getUTCDay(); // 0 (Sunday) to 6 (Saturday)
      const diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
      const monday = new Date(referenceDate);
      monday.setUTCDate(referenceDate.getUTCDate() + diffToMonday);
      monday.setUTCHours(0, 0, 0, 0);
      
      periodStart = new Date(monday);
      periodEnd = new Date(monday);
      periodEnd.setUTCDate(monday.getUTCDate() + 6);
      periodEnd.setUTCHours(23, 59, 59, 999);
      
      daysInPeriod = 7;
      elapsedDays = Math.floor((todayStart.getTime() - periodStart.getTime()) / (24 * 60 * 60 * 1000)) + 1;
      if (elapsedDays < 1) elapsedDays = 1;
      if (elapsedDays > 7) elapsedDays = 7;
      remainingDays = 7 - elapsedDays + 1;
    } else if (selectedFilter === 'thisMonth') {
      const month = referenceDate.getUTCMonth() + 1;
      const year = referenceDate.getUTCFullYear();
      periodStart = new Date(Date.UTC(year, month - 1, 1));
      periodEnd = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));
      
      daysInPeriod = this.getDaysInMonth(month, year);
      elapsedDays = referenceDate.getUTCDate();
      remainingDays = daysInPeriod - elapsedDays + 1;
    } else if (selectedFilter === 'lastMonth') {
      let prevMonth = referenceDate.getUTCMonth();
      let prevYear = referenceDate.getUTCFullYear();
      if (prevMonth === 0) {
        prevMonth = 12;
        prevYear--;
      }
      periodStart = new Date(Date.UTC(prevYear, prevMonth - 1, 1));
      periodEnd = new Date(Date.UTC(prevYear, prevMonth, 0, 23, 59, 59, 999));
      
      daysInPeriod = this.getDaysInMonth(prevMonth, prevYear);
      elapsedDays = daysInPeriod;
      remainingDays = 1;
    } else if (selectedFilter === 'custom' && startDateStr && endDateStr) {
      periodStart = new Date(`${startDateStr}T00:00:00.000Z`);
      periodEnd = new Date(`${endDateStr}T23:59:59.999Z`);
      
      daysInPeriod = Math.floor((periodEnd.getTime() - periodStart.getTime()) / (24 * 60 * 60 * 1000)) + 1;
      if (daysInPeriod < 1) daysInPeriod = 1;
      
      if (todayStart.getTime() >= periodEnd.getTime()) {
        elapsedDays = daysInPeriod;
        remainingDays = 1;
      } else if (todayStart.getTime() <= periodStart.getTime()) {
        elapsedDays = 1;
        remainingDays = daysInPeriod;
      } else {
        elapsedDays = Math.floor((todayStart.getTime() - periodStart.getTime()) / (24 * 60 * 60 * 1000)) + 1;
        remainingDays = daysInPeriod - elapsedDays + 1;
      }
    }

    return {
      referenceDate,
      todayStart,
      todayEnd,
      periodStart,
      periodEnd,
      daysInPeriod,
      elapsedDays,
      remainingDays,
    };
  }

  async getDashboard(userId: string, today?: string, filter?: string, startDate?: string, endDate?: string) {
    const {
      referenceDate,
      todayStart,
      todayEnd,
      periodStart,
      periodEnd,
      daysInPeriod,
      elapsedDays,
      remainingDays,
    } = this.calculatePeriodBoundaries(today, filter, startDate, endDate);

    await this.processPendingSettlements(userId, referenceDate);

    const month = periodStart.getUTCMonth() + 1;
    const year = periodStart.getUTCFullYear();

    await this.recalculateCurrentBudgetProfitLoss(userId, month, year, referenceDate);

    const budget = await this.getBudget(userId, month, year);

    // Today's non-salary expenses
    const todayExpenses = await this.prisma.expense.findMany({
      where: {
        userId,
        category: { not: 'SALARY' },
        date: { gte: todayStart, lte: todayEnd },
      },
      orderBy: { createdAt: 'desc' },
    });

    const todayExpensesSum = todayExpenses.reduce((sum, e) => sum + e.amount, 0);

    // Period's salary sum
    const salarySumAggregate = await this.prisma.expense.aggregate({
      where: {
        userId,
        category: 'SALARY',
        date: { gte: periodStart, lte: periodEnd },
      },
      _sum: { amount: true },
    });
    const salarySum = salarySumAggregate._sum.amount ?? 0;

    // Period's non-salary expenses sum
    const expensesSumAggregate = await this.prisma.expense.aggregate({
      where: {
        userId,
        category: { not: 'SALARY' },
        date: { gte: periodStart, lte: periodEnd },
      },
      _sum: { amount: true },
      _count: true,
    });
    const expensesSum = expensesSumAggregate._sum.amount ?? 0;
    const expensesCount = expensesSumAggregate._count ?? 0;

    // Run dynamic calculations using centralized calculator
    const baseIncome = budget?.monthlyIncome ?? 0;
    const baseSavingsTarget = budget?.savingsTarget ?? 0;

    const calc = FinanceCalculator.calculate({
      baseIncome,
      baseSavingsTarget,
      salarySum,
      expensesSum,
      todayExpensesSum,
      daysInPeriod,
      elapsedDays,
      remainingDays,
    });

    // Recent transactions in the period (last 10, including SALARY)
    const recentTransactions = await this.prisma.expense.findMany({
      where: {
        userId,
        date: { gte: periodStart, lte: periodEnd },
      },
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
      take: 10,
    });

    const dynamicBudget = budget ? {
      ...budget,
      monthlyIncome: calc.monthlyIncome,
      savingsTarget: calc.savingsTarget,
      spendableBudget: calc.spendableBudget,
      dailyGoal: calc.dailyGoal,
      daysInMonth: daysInPeriod,
    } : null;

    return {
      budget: dynamicBudget,
      today: {
        expenses: todayExpenses,
        total: calc.todaySpending,
        dailyGoal: calc.dailyGoal,
        profitLoss: calc.profit > 0 ? calc.profit : -calc.loss,
        status: calc.todaySpending <= calc.dailyGoal ? 'PROFIT' : 'LOSS',
      },
      month: {
        totalExpenses: expensesSum,
        transactionCount: expensesCount,
        remainingBudget: calc.remainingBudget,
        currentSavings: calc.currentSavings,
        savingsProgress: calc.savingsProgress,
        averageDailyExpense: calc.averageDailyExpense,
        monthlyProfit: budget ? (budget as any).monthlyProfit : 0.0,
        monthlyLoss: budget ? (budget as any).monthlyLoss : 0.0,
      },
      recentTransactions,
    };
  }

  // ─── Analytics ───────────────────────────────────────────────────────────────

  async getAnalytics(userId: string, period: string, today?: string, startDate?: string, endDate?: string) {
    const {
      referenceDate,
      periodStart,
      periodEnd,
      daysInPeriod,
      elapsedDays,
    } = this.calculatePeriodBoundaries(today, period, startDate, endDate);

    const expenses = await this.prisma.expense.findMany({
      where: {
        userId,
        category: { not: 'SALARY' },
        date: { gte: periodStart, lte: periodEnd },
      },
      orderBy: { date: 'asc' },
    });

    // Category breakdown
    const categoryBreakdown: Record<string, number> = {};
    for (const exp of expenses) {
      categoryBreakdown[exp.category] = (categoryBreakdown[exp.category] || 0) + exp.amount;
    }

    // Daily breakdown
    const dailyBreakdown: Record<string, number> = {};
    for (const exp of expenses) {
      const key = exp.date.toISOString().split('T')[0];
      dailyBreakdown[key] = (dailyBreakdown[key] || 0) + exp.amount;
    }

    const totalAmount = expenses.reduce((sum, e) => sum + e.amount, 0);
    const days = Object.keys(dailyBreakdown).length || 1;
    const dailyAverage = totalAmount / days;

    // Sort categories by amount
    const sortedCategories = Object.entries(categoryBreakdown)
      .sort(([, a], [, b]) => b - a);

    // Top transactions
    const topTransactions = [...expenses]
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 5);

    // Payment method breakdown
    const paymentBreakdown: Record<string, number> = {};
    for (const exp of expenses) {
      paymentBreakdown[exp.paymentMethod] = (paymentBreakdown[exp.paymentMethod] || 0) + exp.amount;
    }

    return {
      period,
      startDate: periodStart,
      endDate: periodEnd,
      totalAmount,
      transactionCount: expenses.length,
      dailyAverage,
      categoryBreakdown: sortedCategories.map(([category, amount]) => ({
        category,
        amount,
        percentage: totalAmount > 0 ? (amount / totalAmount) * 100 : 0,
      })),
      dailyBreakdown: Object.entries(dailyBreakdown).map(([date, amount]) => ({
        date,
        amount,
      })),
      highestCategory: sortedCategories[0]?.[0] ?? null,
      lowestCategory: sortedCategories[sortedCategories.length - 1]?.[0] ?? null,
      topTransactions,
      paymentBreakdown: Object.entries(paymentBreakdown).map(([method, amount]) => ({
        method,
        amount,
        percentage: totalAmount > 0 ? (amount / totalAmount) * 100 : 0,
      })),
    };
  }
}
