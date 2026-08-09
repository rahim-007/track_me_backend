import { Injectable } from '@nestjs/common';
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
    return this.prisma.goal.findFirst({
      where: { id, userId },
      include: {
        progressHistory: { orderBy: { recordedAt: 'desc' }, take: 10 },
      },
    });
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
    return this.prisma.goal.updateMany({
      where: { id, userId },
      data,
    });
  }

  async updateProgress(userId: string, id: string, progress: number, notes?: string) {
    const goal = await this.prisma.goal.updateMany({
      where: { id, userId },
      data: {
        progress,
        status: progress >= 1.0 ? 'COMPLETED' : 'IN_PROGRESS',
      },
    });

    // Record progress history
    await this.prisma.goalProgress.create({
      data: { goalId: id, progress, notes },
    });

    return goal;
  }

  async remove(userId: string, id: string) {
    return this.prisma.goal.deleteMany({ where: { id, userId } });
  }
}
