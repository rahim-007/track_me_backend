import { Injectable, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HabitLogsService {
  constructor(private readonly prisma: PrismaService) {}

  async completeHabit(userId: string, habitId: string, date: string) {
    const parsedDate = new Date(date);

    const existing = await this.prisma.habitLog.findUnique({
      where: { habitId_date: { habitId, date: parsedDate } },
    });

    if (existing && !existing.isSkipped) {
      throw new ConflictException('Habit already completed for this date');
    }

    const log = await this.prisma.habitLog.upsert({
      where: { habitId_date: { habitId, date: parsedDate } },
      update: {
        isSkipped: false,
        skipReason: null,
        completedAt: new Date(),
      },
      create: {
        habitId,
        userId,
        date: parsedDate,
        completedAt: new Date(),
        isSkipped: false,
      },
    });

    // Update habit completion count
    await this.prisma.habit.update({
      where: { id: habitId },
      data: { totalCompleted: { increment: 1 } },
    });

    return log;
  }

  async skipHabit(userId: string, habitId: string, date: string, reason: string) {
    const parsedDate = new Date(date);

    return this.prisma.habitLog.upsert({
      where: { habitId_date: { habitId, date: parsedDate } },
      update: {
        isSkipped: true,
        skipReason: reason,
        completedAt: null,
      },
      create: {
        habitId,
        userId,
        date: parsedDate,
        isSkipped: true,
        skipReason: reason,
      },
    });
  }

  async uncomplete(userId: string, habitId: string, date: string) {
    const parsedDate = new Date(date);
    return this.prisma.habitLog.deleteMany({
      where: { habitId, userId, date: parsedDate },
    });
  }

  async getWeeklyStats(userId: string) {
    const weekStart = this.getWeekStart();
    const weekEnd = this.getWeekEnd();

    const [total, completed, skipped] = await Promise.all([
      this.prisma.habit.count({ where: { userId, isActive: true } }),
      this.prisma.habitLog.count({
        where: { userId, isSkipped: false, date: { gte: weekStart, lte: weekEnd } },
      }),
      this.prisma.habitLog.count({
        where: { userId, isSkipped: true, date: { gte: weekStart, lte: weekEnd } },
      }),
    ]);

    return {
      totalHabits: total,
      completedThisWeek: completed,
      skippedThisWeek: skipped,
      completionRate: total > 0 ? Math.round((completed / (total * 7)) * 100) : 0,
    };
  }

  private getWeekStart() {
    const d = new Date();
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    const monday = new Date(d.setDate(diff));
    monday.setHours(0, 0, 0, 0);
    return monday;
  }

  private getWeekEnd() {
    const start = this.getWeekStart();
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    end.setHours(23, 59, 59, 999);
    return end;
  }
}
