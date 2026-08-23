import { Injectable, Optional, NotFoundException, BadRequestException } from '@nestjs/common';
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
  private readonly now: () => Date;

  constructor(
    private readonly prisma: PrismaService,
    /** Injectable clock so month-rollover logic can be tested deterministically. */
    @Optional() now?: () => Date,
  ) {
    this.now = now ?? (() => new Date());
  }

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

  /** Manual first-month setup or initial balance configuration. */
  async createFirstPeriod(userId: string, dto: CreatePeriodDto) {
    const openingCash = dto.openingCash ?? 0;
    const existingForMonth = await this.prisma.cashFlowPeriod.findFirst({
      where: { userId, month: dto.month, year: dto.year },
    });

    let period: PeriodRow;
    if (existingForMonth) {
      period = await this.prisma.cashFlowPeriod.update({
        where: { id: existingForMonth.id },
        data: {
          openingBank: dto.openingBank,
          openingCash,
          openingCreditCard: dto.openingCreditCard,
          openingDebt: dto.openingDebt,
        },
      });
    } else {
      period = await this.prisma.cashFlowPeriod.create({
        data: {
          userId,
          month: dto.month,
          year: dto.year,
          openingBank: dto.openingBank,
          openingCash,
          openingCreditCard: dto.openingCreditCard,
          openingDebt: dto.openingDebt,
        },
      });
    }

    await this.recalculateFuturePeriods(userId, dto.month, dto.year);
    return this.serialize(period);
  }

  private async recalculateFuturePeriods(userId: string, fromMonth?: number, fromYear?: number) {
    const periods = await this.prisma.cashFlowPeriod.findMany({
      where: { userId },
      orderBy: [{ year: 'asc' }, { month: 'asc' }],
    });

    for (let i = 1; i < periods.length; i++) {
      const prev = periods[i - 1];
      const curr = periods[i];

      if (fromMonth !== undefined && fromYear !== undefined) {
        if (curr.year < fromYear || (curr.year === fromYear && curr.month <= fromMonth)) {
          continue;
        }
      }

      const closing = await this.computeClosing(userId, prev);

      if (
        curr.openingBank !== closing.closingBank ||
        curr.openingCash !== closing.closingCash ||
        curr.openingCreditCard !== closing.closingCreditCard ||
        curr.openingDebt !== closing.closingDebt
      ) {
        const updated = await this.prisma.cashFlowPeriod.update({
          where: { id: curr.id },
          data: {
            openingBank: closing.closingBank,
            openingCash: closing.closingCash,
            openingCreditCard: closing.closingCreditCard,
            openingDebt: closing.closingDebt,
          },
        });
        periods[i] = updated;
      }
    }
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
    await this.recalculateFuturePeriods(userId, updated.month, updated.year);
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
    if (dto.kind === 'INCOME' && !['E', 'S', 'B', 'I', 'G'].includes(dto.category)) {
      throw new BadRequestException(`Invalid category '${dto.category}' for INCOME entry`);
    }
    if (dto.kind === 'OUTFLOW' && !['E', 'S', 'D', 'I', 'DO'].includes(dto.category)) {
      throw new BadRequestException(`Invalid category '${dto.category}' for OUTFLOW entry`);
    }

    // INCOME cannot post to a credit card — that doesn't make financial sense
    // and would corrupt the credit-card balance calculation.
    if (dto.kind === 'INCOME' && dto.account === 'CREDIT_CARD') {
      throw new BadRequestException(
        'INCOME transactions cannot post to CREDIT_CARD. Use BANK or CASH.',
      );
    }

    const dateParts = dto.date.split('T')[0].split('-').map((p) => parseInt(p, 10));
    const year = dateParts[0];
    const month = dateParts[1];
    const day = dateParts[2] || 1;

    let period = await this.prisma.cashFlowPeriod.findFirst({
      where: { userId, month, year },
    });

    if (!period) {
      const current = await this.ensureCurrentPeriod(userId);
      if (current.month === month && current.year === year) {
        period = current;
      } else {
        throw new BadRequestException(
          `Entry date must fall inside a valid period (${current.month}/${current.year})`,
        );
      }
    }

    // Resolve the effective account (default BANK keeps legacy behaviour).
    const account = dto.account ?? 'BANK';

    const date = new Date(Date.UTC(year, month - 1, day));
    const txn = await this.prisma.cashFlowTransaction.create({
      data: {
        periodId: period.id,
        kind: dto.kind,
        category: dto.category,
        amount: dto.amount,
        note: dto.note ?? null,
        date,
        account,
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
      // Include `category` and `account` so per-pocket math is correct.
      select: { kind: true, amount: true, category: true, account: true },
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
      select: { kind: true, amount: true, category: true, account: true },
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
    account: string | null;
    createdAt: Date;
  }) {
    return {
      ...t,
      date: t.date.toISOString().slice(0, 10),
      // Normalise null → 'BANK' so clients always receive an explicit value.
      account: t.account ?? 'BANK',
    };
  }
}
