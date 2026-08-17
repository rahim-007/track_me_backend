import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDebtDto } from './dto/create-debt.dto';
import { UpdateDebtDto } from './dto/update-debt.dto';
import { CreatePaymentDto } from './dto/create-payment.dto';

type DebtRow = {
  id: string;
  userId: string;
  name: string;
  originalAmount: number;
  lenderName: string | null;
  dueDate: Date | null;
  installmentAmount: number | null;
  description: string | null;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  payments?: { amount: number; id?: string; paymentDate?: Date; note?: string | null; createdAt?: Date }[];
};

/**
 * Debt / Loan tracker — a fully standalone feature.
 *
 * Totals are always derived, never stored:
 *   totalPaid        = SUM(DebtPayment.amount)
 *   remainingBalance = originalAmount - totalPaid   (clamped at 0)
 *
 * Ownership is enforced on every operation (users can only see/edit their own
 * debts). A debt is automatically marked PAID when its balance reaches 0;
 * overpayments are rejected so the balance can never go negative.
 *
 * This service never touches Cash Flow (expenses/budget/extra income) — a debt
 * payment is a Debt Tracker payment only.
 */
@Injectable()
export class DebtService {
  constructor(private readonly prisma: PrismaService) {}

  /** All debts for the user, newest first, with derived totals. */
  async findAll(userId: string) {
    const debts = await this.prisma.debt.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { payments: { select: { amount: true } } },
    });
    return debts.map((d) => this.serialize(d));
  }

  /** One debt + full payment history (newest payment first). */
  async findOne(userId: string, id: string) {
    const debt = await this.prisma.debt.findFirst({
      where: { id, userId },
      include: { payments: { orderBy: { paymentDate: 'desc' } } },
    });
    if (!debt) throw new NotFoundException('Debt not found');
    return this.serialize(debt, true);
  }

  async create(userId: string, dto: CreateDebtDto) {
    const debt = await this.prisma.debt.create({
      data: {
        userId,
        name: dto.name,
        originalAmount: dto.originalAmount,
        lenderName: dto.lenderName ?? null,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        installmentAmount: dto.installmentAmount ?? null,
        description: dto.description ?? null,
      },
      include: { payments: { select: { amount: true } } },
    });
    return this.serialize(debt);
  }

  async update(userId: string, id: string, dto: UpdateDebtDto) {
    const existing = await this.prisma.debt.findFirst({
      where: { id, userId },
      include: { payments: { select: { amount: true } } },
    });
    if (!existing) throw new NotFoundException('Debt not found');

    const totalPaid = this.sumPayments(existing.payments ?? []);
    if (dto.originalAmount != null && dto.originalAmount < totalPaid) {
      throw new BadRequestException(
        'Original amount cannot be less than the total already paid',
      );
    }

    const updated = await this.prisma.debt.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.originalAmount !== undefined && { originalAmount: dto.originalAmount }),
        ...(dto.lenderName !== undefined && { lenderName: dto.lenderName }),
        ...(dto.dueDate !== undefined && {
          dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        }),
        ...(dto.installmentAmount !== undefined && { installmentAmount: dto.installmentAmount }),
        ...(dto.description !== undefined && { description: dto.description }),
      },
      include: { payments: { select: { amount: true } } },
    });
    return this.serialize(updated);
  }

  /**
   * Record a payment against a debt. Rejects payments that exceed the remaining
   * balance and auto-flips the debt to PAID when the balance reaches 0.
   */
  async recordPayment(userId: string, debtId: string, dto: CreatePaymentDto) {
    const debt = await this.prisma.debt.findFirst({
      where: { id: debtId, userId },
      include: { payments: { select: { amount: true } } },
    });
    if (!debt) throw new NotFoundException('Debt not found');

    const totalPaid = this.sumPayments(debt.payments ?? []);
    const remaining = this.round2(debt.originalAmount - totalPaid);
    if (dto.amount > remaining + 0.001) {
      throw new BadRequestException(
        `Payment of ₹${dto.amount} exceeds the remaining balance of ₹${remaining}`,
      );
    }

    await this.prisma.debtPayment.create({
      data: {
        debtId,
        amount: dto.amount,
        paymentDate: dto.paymentDate ? new Date(dto.paymentDate) : new Date(),
        note: dto.note ?? null,
      },
    });

    const newTotalPaid = this.round2(totalPaid + dto.amount);
    const isPaidOff = newTotalPaid >= this.round2(debt.originalAmount) - 0.001;
    if (isPaidOff) {
      await this.prisma.debt.update({
        where: { id: debtId },
        data: { status: 'PAID' },
      });
    }

    const updated = await this.prisma.debt.findUnique({
      where: { id: debtId },
      include: { payments: { orderBy: { paymentDate: 'desc' } } },
    });
    if (!updated) throw new NotFoundException('Debt not found');
    return this.serialize(updated, true);
  }

  async remove(userId: string, id: string) {
    const existing = await this.prisma.debt.findFirst({ where: { id, userId } });
    if (!existing) throw new NotFoundException('Debt not found');
    await this.prisma.debt.delete({ where: { id } });
    return { deleted: true };
  }

  private sumPayments(payments: { amount: number }[]): number {
    return payments.reduce((sum, p) => sum + p.amount, 0);
  }

  private round2(n: number): number {
    return Math.round(n * 100) / 100;
  }

  /**
   * Attach derived totals. `payments` is stripped unless explicitly requested
   * (list responses stay lean; the detail response carries history).
   */
  private serialize(debt: DebtRow, includePayments = false) {
    const totalPaid = this.round2(this.sumPayments(debt.payments ?? []));
    const remainingBalance = Math.max(this.round2(debt.originalAmount - totalPaid), 0);
    const { payments, ...rest } = debt;
    return {
      ...rest,
      totalPaid,
      remainingBalance,
      ...(includePayments ? { payments } : {}),
    };
  }
}
