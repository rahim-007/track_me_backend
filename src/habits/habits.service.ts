import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  computeHabitStreaks,
  getUserNow,
  StreakHabitInput,
} from '../streaks/streaks.util';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';

@Injectable()
export class HabitsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { timezone: true },
    });
    const userNow = getUserNow(user?.timezone);

    const yesterday = new Date(userNow);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    yesterday.setUTCHours(0, 0, 0, 0);

    const weekStart = this.getWeekStart(userNow);
    const gteDate = yesterday < weekStart ? yesterday : weekStart;

    // Scan up to 366 days of logs to compute per-habit streaks accurately
    const scanStart = new Date(userNow);
    scanStart.setUTCDate(scanStart.getUTCDate() - 366);

    const [habits, allYearLogs] = await Promise.all([
      this.prisma.habit.findMany({
        where: { userId, isActive: true },
        include: {
          logs: {
            where: {
              date: {
                gte: gteDate,
                lte: this.getWeekEnd(userNow),
              },
            },
            orderBy: { date: 'asc' },
          },
        },
        orderBy: { createdAt: 'asc' },
      }),
      this.prisma.habitLog.findMany({
        where: {
          userId,
          isSkipped: false,
          date: { gte: scanStart },
        },
        select: {
          habitId: true,
          date: true,
        },
      }),
    ]);

    // Group completion dates by habitId
    const completedByHabit = new Map<string, Set<string>>();
    for (const log of allYearLogs) {
      const dateStr = log.date.toISOString().split('T')[0];
      const existing = completedByHabit.get(log.habitId);
      if (existing) {
        existing.add(dateStr);
      } else {
        completedByHabit.set(log.habitId, new Set([dateStr]));
      }
    }

    return habits.map((habit: any) => {
      const habitCompletedSet = completedByHabit.get(habit.id) ?? new Set<string>();
      const { currentStreak, longestStreak } = computeHabitStreaks(
        habit,
        habitCompletedSet,
        userNow,
      );

      return this.formatHabitWithDates({
        ...habit,
        currentStreak,
        longestStreak,
      });
    });
  }

  async findOne(userId: string, id: string) {
    const habit = await this.prisma.habit.findFirst({
      where: { id, userId, isActive: true },
      include: {
        logs: {
          orderBy: { date: 'desc' },
          take: 30,
        },
      },
    });
    if (!habit) {
      // Never reveal whether the id exists but belongs to someone else.
      throw new NotFoundException('Habit not found');
    }
    return habit;
  }

  async create(userId: string, dto: CreateHabitDto) {
    return this.prisma.habit.create({
      data: {
        ...dto,
        userId,
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateHabitDto) {
    const result = await this.prisma.habit.updateMany({
      where: { id, userId },
      data: dto,
    });
    if (result.count === 0) {
      throw new NotFoundException('Habit not found');
    }
    return result;
  }

  async remove(userId: string, id: string) {
    // Soft delete
    const result = await this.prisma.habit.updateMany({
      where: { id, userId },
      data: { isActive: false },
    });
    if (result.count === 0) {
      throw new NotFoundException('Habit not found');
    }
    return result;
  }

  async getStreak(userId: string, habitId: string) {
    const [user, habit] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { timezone: true },
      }),
      this.prisma.habit.findFirst({
        where: { id: habitId, userId, isActive: true },
        include: {
          // Only valid non-skipped completions can extend a streak.
          logs: {
            where: { isSkipped: false },
            orderBy: { date: 'desc' },
          },
        },
      }),
    ]);

    if (!habit) {
      // Never reveal whether the id exists but belongs to someone else.
      throw new NotFoundException('Habit not found');
    }

    const userNow = getUserNow(user?.timezone);
    const completedDates = new Set(
      habit.logs.map((l: any) => l.date.toISOString().split('T')[0]),
    );
    const { currentStreak, longestStreak } = computeHabitStreaks(
      habit,
      completedDates,
      userNow,
    );

    return { currentStreak, longestStreak };
  }

  private formatHabitWithDates(habit: any) {
    const completedDates = habit.logs
      .filter((l: any) => !l.isSkipped)
      .map((l: any) => l.date.toISOString().split('T')[0]);

    const skippedDates = habit.logs
      .filter((l: any) => l.isSkipped)
      .map((l: any) => l.date.toISOString().split('T')[0]);

    return {
      ...habit,
      completedDates,
      skippedDates,
      logs: undefined,
    };
  }

  private getWeekStart(now: Date = new Date()) {
    const d = new Date(now);
    const day = d.getUTCDay();
    const diff = d.getUTCDate() - day + (day === 0 ? -6 : 1);
    const monday = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), diff));
    monday.setUTCHours(0, 0, 0, 0);
    return monday;
  }

  private getWeekEnd(now: Date = new Date()) {
    const start = this.getWeekStart(now);
    const end = new Date(start);
    end.setUTCDate(start.getUTCDate() + 6);
    end.setUTCHours(23, 59, 59, 999);
    return end;
  }
}
