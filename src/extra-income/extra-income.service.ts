import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateExtraIncomeDto } from './dto/create-extra-income.dto';

@Injectable()
export class ExtraIncomeService {
  constructor(private readonly prisma: PrismaService) {}

  /** All extra-income entries for a user, newest first. */
  findAll(userId: string) {
    return this.prisma.extraIncome.findMany({
      where: { userId },
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });
  }

  /** Total extra income for a user across all entries. */
  async getTotal(userId: string): Promise<number> {
    const agg = await this.prisma.extraIncome.aggregate({
      where: { userId },
      _sum: { amount: true },
    });
    return agg._sum.amount ?? 0;
  }

  create(userId: string, dto: CreateExtraIncomeDto) {
    return this.prisma.extraIncome.create({
      data: {
        userId,
        title: dto.title,
        amount: dto.amount,
        date: new Date(dto.date),
      },
    });
  }

  async remove(userId: string, id: string) {
    // Ownership check — users can only delete their own entries.
    const existing = await this.prisma.extraIncome.findFirst({
      where: { id, userId },
    });
    if (!existing) {
      throw new NotFoundException('Extra income entry not found');
    }
    await this.prisma.extraIncome.delete({ where: { id } });
    return { deleted: true };
  }
}
