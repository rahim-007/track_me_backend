import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateCashFlowDebtDto,
  UpdateCashFlowDebtDto,
} from './dto/cashflow-debt.dto';

/**
 * Cash Flow Debt Ledger — a continuous give/receive ledger.
 *
 * Unlike transactions, debts are NOT reset at month boundaries: they persist
 * until marked settled or deleted. The dashboard summary (Yet to Receive /
 * Yet to Give) is derived here so the period endpoint and the ledger always
 * agree on the numbers.
 */
@Injectable()
export class CashFlowDebtService {
  constructor(private readonly prisma: PrismaService) {}

  /** All unsettled + settled ledger entries, newest first. */
  async findAll(userId: string) {
    const debts = await this.prisma.cashFlowDebt.findMany({
      where: { userId },
      orderBy: [{ settled: 'asc' }, { date: 'desc' }, { createdAt: 'desc' }],
    });
    return debts.map((d) => this.serialize(d));
  }

  /** Totals for the dashboard summary tiles. */
  async getSummary(userId: string) {
    const [give, receive] = await Promise.all([
      this.prisma.cashFlowDebt.aggregate({
        where: { userId, direction: 'GIVE', settled: false },
        _sum: { amount: true },
      }),
      this.prisma.cashFlowDebt.aggregate({
        where: { userId, direction: 'RECEIVE', settled: false },
        _sum: { amount: true },
      }),
    ]);
    return {
      yetToGive: round2(give._sum.amount ?? 0),
      yetToReceive: round2(receive._sum.amount ?? 0),
    };
  }

  async create(userId: string, dto: CreateCashFlowDebtDto) {
    const debt = await this.prisma.cashFlowDebt.create({
      data: {
        userId,
        direction: dto.direction,
        person: dto.person,
        amount: dto.amount,
        note: dto.note ?? null,
        date: new Date(dto.date),
      },
    });
    return this.serialize(debt);
  }

  async update(userId: string, id: string, dto: UpdateCashFlowDebtDto) {
    const existing = await this.prisma.cashFlowDebt.findFirst({
      where: { id, userId },
    });
    if (!existing) throw new NotFoundException('Ledger entry not found');

    const updated = await this.prisma.cashFlowDebt.update({
      where: { id },
      data: {
        ...(dto.direction !== undefined && { direction: dto.direction }),
        ...(dto.person !== undefined && { person: dto.person }),
        ...(dto.amount !== undefined && { amount: dto.amount }),
        ...(dto.note !== undefined && { note: dto.note ?? null }),
        ...(dto.date !== undefined && { date: new Date(dto.date) }),
        ...(dto.settled !== undefined && {
          settled: dto.settled,
          settledAt: dto.settled ? new Date() : null,
        }),
      },
    });
    return this.serialize(updated);
  }

  async remove(userId: string, id: string) {
    const existing = await this.prisma.cashFlowDebt.findFirst({
      where: { id, userId },
    });
    if (!existing) throw new NotFoundException('Ledger entry not found');
    await this.prisma.cashFlowDebt.delete({ where: { id } });
    return { deleted: true };
  }

  private serialize(d: {
    id: string;
    userId: string;
    direction: string;
    person: string;
    amount: number;
    note: string | null;
    date: Date;
    settled: boolean;
    settledAt: Date | null;
    createdAt: Date;
  }) {
    return {
      ...d,
      date: d.date.toISOString().slice(0, 10),
      ...(d.settledAt ? { settledAt: d.settledAt.toISOString() } : {}),
    };
  }
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
