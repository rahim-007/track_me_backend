import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  computeClosingBalances,
  nextMonth,
  monthYearOf,
  OpeningBalances,
} from './cashflow-balance.util';
import { CreatePeriodDto, UpdateBalancesDto } from './dto/cashflow-period.dto';
import {
  CreateTransactionDto,
} from './dto/create-transaction.dto';

type PeriodRow = {
  id: string;
  userId: string;
  month: number;
  year: number;
  openingBank: number;
  openingCash: number;
  openingCreditCard: number;
  openingDebt: number;
  createdAt: Date;
};

/**
 * Cash Flow periods — one per calendar month per user.
 *
 * The first period is created manually (POST /periods) with user-entered
 * opening balances. Every later period is opened lazily by ensureCurrentPeriod
 * (called on every read of the current period): its opening balances are the
 * previous period's computed closing balances. Closing balances themselves are
 * always derived, never stored.
 */
@Injectable()
export class CashFlowPeriodService {
  constructor(
    private readonly prisma: PrismaService,
    /** Injectable clock so month-rollover logic can be tested deterministically. */
    private readonly now: () => Date = () => new Date(),
  ) {}

  /** All periods for the user, oldest first. */
  async listPeriods(userId: string) {
    await this.ensureCurrentPeriod(userId);
    const periods = await this.prisma.cashFlowPeriod.findMany({
      where: { userId },
      orderBy: [{ year: 'asc' }, { month: 'asc' }],
    });
    return Promise.all(periods.map((p) => this.serialize(p)));
  }

  /**
   * The current calendar month's period. Opens it on demand (first read after
   * a month rollover), carrying forward the previous period's closing balances.
   */
  async getCurrentPeriod(userId: string) {
    const period = await this.ensureCurrentPeriod(userId);
    return this.serialize(period);
  }

  /** Manual first-month setup. Only allowed when no period exists yet. */
  async createFirstPeriod(userId: string, dto: CreatePeriodDto) {
    const existing = await this.prisma.cashFlowPeriod.findFirst({
      where: { userId },
    });
    if (existing) {
      throw new BadRequestException(
        'A period already exists — subsequent periods open automatically at month rollover',
      );
    }
    const period = await this.prisma.cashFlowPeriod.create({
      data: {
        userId,
        month: dto.month,
        year: dto.year,
        openingBank: dto.openingBank,
        openingCash: 0,
        openingCreditCard: dto.openingCreditCard,
        openingDebt: dto.openingDebt,
      },
    });
    // Normalize cash so a first entry can't be lost: v1 posts everything to
    // bank, but keep whatever cash value the user entered via openingCash.
    if (dto.openingCash !== undefined) {
      return this.serialize(
        await this.prisma.cashFlowPeriod.update({
          where: { id: period.id },
          data: { openingCash: dto.openingCash },
        }),
      );
    }
    return this.serialize(period);
  }

  /** Edit the current period's opening balances. Past periods are immutable. */
  async updateOpeningBalances(
    userId: string,
    periodId: string,
    dto: UpdateBalancesDto,
  ) {
    const current = await this.ensureCurrentPeriod(userId);
    if (current.id !== periodId) {
      throw new BadRequestException('Past periods are read-only');
    }
    const updated = await this.prisma.cashFlowPeriod.update({
      where: { id: periodId },
      data: {
        ...(dto.openingBank !== undefined && { openingBank: dto.openingBank }),
        ...(dto.openingCash !== undefined && { openingCash: dto.openingCash }),
        ...(dto.openingCreditCard !== undefined && {
          openingCreditCard: dto.openingCreditCard,
        }),
        ...(dto.openingDebt !== undefined && { openingDebt: dto.openingDebt }),
      },
    });
    return this.serialize(updated);
  }

  async listTransactions(userId: string, periodId: string) {
    const period = await this.getOwnedPeriod(userId, periodId);
    const txns = await this.prisma.cashFlowTransaction.findMany({
      where: { periodId: period.id },
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });
    return txns.map((t) => this.serializeTxn(t));
  }

  async createTransaction(userId: string, dto: CreateTransactionDto) {
    const period = await this.ensureCurrentPeriod(userId);
    const date = new Date(dto.date);
    if (
      date.getMonth() + 1 !== period.month ||
      date.getFullYear() !== period.year
    ) {
      throw new BadRequestException(
        `Entry date must fall inside the current period (${period.month}/${period.year})`,
      );
    }
    const txn = await this.prisma.cashFlowTransaction.create({
      data: {
        periodId: period.id,
        kind: dto.kind,
        category: dto.category,
        amount: dto.amount,
        note: dto.note ?? null,
        date,
      },
    });
    return this.serializeTxn(txn);
  }

  async deleteTransaction(userId: string, txnId: string) {
    const existing = await this.prisma.cashFlowTransaction.findFirst({
      where: { id: txnId, period: { userId } },
    });
    if (!existing) throw new NotFoundException('Transaction not found');
    await this.prisma.cashFlowTransaction.delete({ where: { id: txnId } });
    return { deleted: true };
  }

  /**
   * Lazy month rollover. If the newest period is older than the current
   * calendar month, open one period per missing month (so skipped months still
   * carry forward correctly). Concurrent requests share one upsert via the
   * unique [userId,month,year] constraint; losers of the race re-read.
   */
  private async ensureCurrentPeriod(userId: string): Promise<PeriodRow> {
    const now = monthYearOf(this.now());
    let latest = await this.latestPeriod(userId);

    while (
      !latest ||
      latest.year < now.year ||
      (latest.year === now.year && latest.month < now.month)
    ) {
      const next = !latest ? null : nextMonth(latest.month, latest.year);
      if (!latest) {
        // No period at all — auto-open an all-zero current month so reads and
        // entries work before manual setup. The user can edit balances after.
        latest = await this.upsertPeriod(userId, {
          month: now.month,
          year: now.year,
          openingBank: 0,
          openingCash: 0,
          openingCreditCard: 0,
          openingDebt: 0,
        });
        break;
      }
      const closing = await this.computeClosing(userId, latest);
      try {
        latest = await this.prisma.cashFlowPeriod.create({
          data: {
            userId,
            month: next!.month,
            year: next!.year,
            openingBank: closing.closingBank,
            openingCash: closing.closingCash,
            openingCreditCard: closing.closingCreditCard,
            openingDebt: closing.closingDebt,
          },
        });
      } catch {
        // Lost a race against another request that already opened this month —
        // re-read and continue from there.
        latest = await this.latestPeriod(userId);
      }
    }
    return latest!;
  }

  private async latestPeriod(userId: string): Promise<PeriodRow | null> {
    return this.prisma.cashFlowPeriod.findFirst({
      where: { userId },
      orderBy: [{ year: 'desc' }, { month: 'desc' }],
    });
  }

  private async upsertPeriod(
    userId: string,
    data: {
      month: number;
      year: number;
      openingBank: number;
      openingCash: number;
      openingCreditCard: number;
      openingDebt: number;
    },
  ): Promise<PeriodRow> {
    return this.prisma.cashFlowPeriod.upsert({
      where: {
        userId_month_year: { userId, month: data.month, year: data.year },
      },
      create: { userId, ...data },
      update: {},
    });
  }

  private async computeClosing(userId: string, period: PeriodRow) {
    const txns = await this.prisma.cashFlowTransaction.findMany({
      where: { periodId: period.id },
      select: { kind: true, amount: true },
    });
    const opening: OpeningBalances = {
      openingBank: period.openingBank,
      openingCash: period.openingCash,
      openingCreditCard: period.openingCreditCard,
      openingDebt: period.openingDebt,
    };
    return computeClosingBalances(opening, txns);
  }

  private async getOwnedPeriod(userId: string, periodId: string) {
    const period = await this.prisma.cashFlowPeriod.findFirst({
      where: { id: periodId, userId },
    });
    if (!period) throw new NotFoundException('Period not found');
    return period;
  }

  /** Attach derived totals + closing balances to a period row. */
  private async serialize(period: PeriodRow) {
    const txns = await this.prisma.cashFlowTransaction.findMany({
      where: { periodId: period.id },
      select: { kind: true, amount: true, category: true },
    });
    const opening: OpeningBalances = {
      openingBank: period.openingBank,
      openingCash: period.openingCash,
      openingCreditCard: period.openingCreditCard,
      openingDebt: period.openingDebt,
    };
    const totals = computeClosingBalances(opening, txns);

    const incomeByCategory: Record<string, number> = {};
    const outflowByCategory: Record<string, number> = {};
    for (const t of txns) {
      if (t.kind === 'INCOME') {
        incomeByCategory[t.category] =
          Math.round(((incomeByCategory[t.category] ?? 0) + t.amount) * 100) / 100;
      } else {
        outflowByCategory[t.category] =
          Math.round(((outflowByCategory[t.category] ?? 0) + t.amount) * 100) / 100;
      }
    }

    return {
      ...period,
      totalIncome: totals.totalIncome,
      totalOutflow: totals.totalOutflow,
      netCashFlow: totals.netCashFlow,
      closingBank: totals.closingBank,
      closingCash: totals.closingCash,
      closingCreditCard: totals.closingCreditCard,
      closingDebt: totals.closingDebt,
      incomeByCategory,
      outflowByCategory,
    };
  }

  private serializeTxn(t: {
    id: string;
    periodId: string;
    kind: string;
    category: string;
    amount: number;
    note: string | null;
    date: Date;
    createdAt: Date;
  }) {
    return { ...t, date: t.date.toISOString().slice(0, 10) };
  }
}
