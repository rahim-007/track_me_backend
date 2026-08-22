import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { computeOverallStreaks } from '../streaks/streaks.util';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async calculateUserStreak(userId: string) {
    const habits = await this.prisma.habit.findMany({
      where: { userId },
    });

    if (habits.length === 0) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { currentStreak: 0, longestStreak: 0 },
      });
      return { currentStreak: 0, longestStreak: 0 };
    }

    // Earliest habit creation date
    let earliestHabitDate: Date | null = null;
    for (const h of habits) {
      if (!earliestHabitDate || h.createdAt < earliestHabitDate) {
        earliestHabitDate = h.createdAt;
      }
    }
    if (!earliestHabitDate) {
      earliestHabitDate = new Date();
    }

    // Cap the scan window to one year so streak computation stays fast for
    // long-time users instead of walking every day since the first habit.
    const windowStart = new Date();
    windowStart.setUTCDate(windowStart.getUTCDate() - 366);
    const scanStart = earliestHabitDate < windowStart ? windowStart : earliestHabitDate;

    const logs = await this.prisma.habitLog.findMany({
      where: {
        userId,
        date: {
          gte: new Date(
            Date.UTC(scanStart.getUTCFullYear(), scanStart.getUTCMonth(), scanStart.getUTCDate()),
          ),
        },
      },
    });

    const { currentStreak, longestStreak } = computeOverallStreaks(habits, logs);

    await this.prisma.user.update({
      where: { id: userId },
      data: { currentStreak, longestStreak },
    });

    return { currentStreak, longestStreak };
  }

  async getProfile(userId: string) {
    const [user, streaks] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          email: true,
          name: true,
          avatarUrl: true,
          timezone: true,
          createdAt: true,
          _count: {
            select: {
              habits: true,
              goals: { where: { status: 'COMPLETED' } },
            },
          },
        },
      }),
      this.calculateUserStreak(userId),
    ]);

    if (!user) return null;

    return {
      ...user,
      currentStreak: streaks.currentStreak,
      longestStreak: streaks.longestStreak,
    };
  }

  async updateProfile(
    userId: string,
    data: { name?: string; avatarUrl?: string; timezone?: string },
  ) {
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        timezone: true,
      },
    });
  }

  async updateFcmToken(userId: string, fcmToken: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
  }

  async getStats(userId: string) {
    const [completedHabitsCount, activeGoals, streaks] = await Promise.all([
      this.prisma.habitLog.count({
        where: { userId, isSkipped: false },
      }),
      this.prisma.goal.count({
        where: { userId, status: 'IN_PROGRESS' },
      }),
      this.calculateUserStreak(userId),
    ]);

    return {
      currentStreak: streaks.currentStreak,
      longestStreak: streaks.longestStreak,
      totalCompletedHabits: completedHabitsCount,
      activeGoals,
    };
  }
}

