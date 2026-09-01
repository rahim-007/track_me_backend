import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HabitLogsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Assert the habit belongs to the authenticated user so users can never
   * create/modify logs (or counters) against someone else's habit.
   */
  private async assertOwnedHabit(userId: string, habitId: string) {
    const habit = await this.prisma.habit.findFirst({
      where: { id: habitId, userId },
      select: { id: true },
    });
    if (!habit) {
      throw new NotFoundException('Habit not found');
    }
  }

  async completeHabit(userId: string, habitId: string, date: string) {
    await this.assertOwnedHabit(userId, habitId);
    const parsedDate = new Date(date);

    const existing = await this.prisma.habitLog.findFirst({
      where: { habitId, date: parsedDate, userId },
    });

    // Idempotent: repeated tap on an already-completed habit is a no-op
    if (existing && !existing.isSkipped) {
      return existing;
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

    // Increment totalCompleted when converting from skip or creating a brand-new completion
    await this.prisma.habit.update({
      where: { id: habitId },
      data: { totalCompleted: { increment: 1 } },
    });

    return log;
  }

  async skipHabit(
    userId: string,
    habitId: string,
    date: string,
    reason: string,
  ) {
    await this.assertOwnedHabit(userId, habitId);
    const parsedDate = new Date(date);

    const existing = await this.prisma.habitLog.findFirst({
      where: { habitId, date: parsedDate, userId },
    });

    const log = await this.prisma.habitLog.upsert({
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

    // Keep totalCompleted in sync when a completion is converted to a skip — a
    // habit/date can only ever be in one state, so the completed count must go
    // down for that day. Re-skipping an already-skipped day is a no-op here.
    if (existing && !existing.isSkipped) {
      await this.prisma.habit.update({
        where: { id: habitId },
        data: { totalCompleted: { decrement: 1 } },
      });
    }

    return log;
  }

  async uncomplete(userId: string, habitId: string, date: string) {
    await this.assertOwnedHabit(userId, habitId);
    const parsedDate = new Date(date);

    const log = await this.prisma.habitLog.findFirst({
      where: { habitId, date: parsedDate, userId },
    });

    const result = await this.prisma.habitLog.deleteMany({
      where: { habitId, userId, date: parsedDate },
    });

    // Keep the completion counter in sync — remove the count only when an
    // actual completed (non-skipped) log was deleted.
    if (log && !log.isSkipped && result.count > 0) {
      await this.prisma.habit.update({
        where: { id: habitId },
        data: { totalCompleted: { decrement: 1 } },
      });
    }

    return result;
  }

  async getWeeklyStats(userId: string) {
    const weekStart = this.getWeekStart();
    const weekEnd = this.getWeekEnd();

    const [total, completed, skipped] = await Promise.all([
      this.prisma.habit.count({ where: { userId, isActive: true } }),
      this.prisma.habitLog.count({
        where: {
          userId,
          isSkipped: false,
          date: { gte: weekStart, lte: weekEnd },
        },
      }),
      this.prisma.habitLog.count({
        where: {
          userId,
          isSkipped: true,
          date: { gte: weekStart, lte: weekEnd },
        },
      }),
    ]);

    return {
      totalHabits: total,
      completedThisWeek: completed,
      skippedThisWeek: skipped,
      completionRate:
        total > 0 ? Math.round((completed / (total * 7)) * 100) : 0,
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
