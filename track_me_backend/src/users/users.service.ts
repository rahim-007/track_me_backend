import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        currentStreak: true,
        longestStreak: true,
        createdAt: true,
        _count: {
          select: {
            habits: true,
            goals: { where: { status: 'COMPLETED' } },
          },
        },
      },
    });
  }

  async updateProfile(userId: string, data: { name?: string; avatarUrl?: string }) {
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
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
    const [user, completedHabitsCount, activeGoals] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { currentStreak: true, longestStreak: true },
      }),
      this.prisma.habitLog.count({
        where: { userId, isSkipped: false },
      }),
      this.prisma.goal.count({
        where: { userId, status: 'IN_PROGRESS' },
      }),
    ]);

    return {
      currentStreak: user?.currentStreak ?? 0,
      longestStreak: user?.longestStreak ?? 0,
      totalCompletedHabits: completedHabitsCount,
      activeGoals,
    };
  }
}
