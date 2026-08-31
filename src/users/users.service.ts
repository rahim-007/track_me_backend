import { Injectable, Logger } from '@nestjs/common';
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
    const scanStart =
      earliestHabitDate < windowStart ? windowStart : earliestHabitDate;

    const logs = await this.prisma.habitLog.findMany({
      where: {
        userId,
        date: {
          gte: new Date(
            Date.UTC(
              scanStart.getUTCFullYear(),
              scanStart.getUTCMonth(),
              scanStart.getUTCDate(),
            ),
          ),
        },
      },
    });

    const { currentStreak, longestStreak } = computeOverallStreaks(
      habits,
      logs,
    );

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

  async updateFcmToken(userId: string, fcmToken: string, platform = 'android') {
    if (!fcmToken || fcmToken.trim().length === 0) {
      await this.prisma.device.deleteMany({ where: { userId } });
      return this.prisma.user.update({
        where: { id: userId },
        data: { fcmToken: null },
      });
    }

    await this.prisma.device.upsert({
      where: { fcmToken: fcmToken.trim() },
      create: {
        userId,
        fcmToken: fcmToken.trim(),
        platform: platform || 'android',
      },
      update: {
        userId,
        platform: platform || 'android',
      },
    });

    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: fcmToken.trim() },
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Account Deletion
  // ─────────────────────────────────────────────────────────────────────────────

  private readonly logger = new Logger(UsersService.name);

  /**
   * Permanently delete the authenticated user's account and all associated data.
   *
   * Wrapped in a Prisma interactive transaction so that a partial failure cannot
   * leave the account in a half-deleted state. All child records (habits, goals,
   * cash-flow, notifications, tokens, etc.) cascade automatically via the
   * schema's `onDelete: Cascade` constraints.
   *
   * @returns `true` if the account was deleted, `null` if it did not exist.
   */
  async deleteAccount(userId: string): Promise<boolean | null> {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findUnique({ where: { id: userId } });
      if (!user) return null;

      // Defensive: clear FCM token and devices before cascade so no stale push
      // can be attempted between the moment the delete starts and when the row is gone.
      if (user.fcmToken) {
        await tx.device.deleteMany({ where: { userId } });
        await tx.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });
      }

      await tx.user.delete({ where: { id: userId } });

      this.logger.log(`Account deleted: ${userId}`);
      return true;
    });
  }
}
