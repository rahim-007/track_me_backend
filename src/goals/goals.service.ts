import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalDto } from './dto/update-goal.dto';

@Injectable()
export class GoalsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    return this.prisma.goal.findMany({
      where: { userId },
      orderBy: [{ status: 'asc' }, { targetDate: 'asc' }],
    });
  }

  async findOne(userId: string, id: string) {
    const goal = await this.prisma.goal.findFirst({
      where: { id, userId },
      include: {
        progressHistory: { orderBy: { recordedAt: 'desc' }, take: 10 },
      },
    });
    if (!goal) {
      throw new NotFoundException('Goal not found');
    }
    return goal;
  }

  async create(userId: string, dto: CreateGoalDto) {
    return this.prisma.goal.create({
      data: {
        ...dto,
        targetDate: new Date(dto.targetDate),
        userId,
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateGoalDto) {
    const data: any = { ...dto };
    if (dto.targetDate) {
      data.targetDate = new Date(dto.targetDate);
    }
    const result = await this.prisma.goal.updateMany({
      where: { id, userId },
      data,
    });
    if (result.count === 0) {
      throw new NotFoundException('Goal not found');
    }
    return result;
  }

  async updateProgress(userId: string, id: string, progress: number, notes?: string) {
    // Clamp progress to a valid 0.0 – 1.0 range
    const safeProgress = Math.min(1, Math.max(0, progress));

    const goal = await this.prisma.goal.findFirst({
      where: { id, userId },
      select: { id: true },
    });

    // Never record history for goals the user doesn't own (or that don't exist)
    if (!goal) {
      throw new NotFoundException('Goal not found');
    }

    // Keep progress + history atomic
    return this.prisma.$transaction(async (tx) => {
      await tx.goal.update({
        where: { id },
        data: {
          progress: safeProgress,
          status: safeProgress >= 1.0 ? 'COMPLETED' : 'IN_PROGRESS',
        },
      });

      await tx.goalProgress.create({
        data: { goalId: id, progress: safeProgress, notes },
      });

      return { count: 1 };
    });
  }

  async remove(userId: string, id: string) {
    const result = await this.prisma.goal.deleteMany({ where: { id, userId } });
    if (result.count === 0) {
      throw new NotFoundException('Goal not found');
    }
    return result;
  }
}
