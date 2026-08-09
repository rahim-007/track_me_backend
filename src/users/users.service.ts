import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async calculateUserStreak(userId: string) {
    const [habits, logs] = await Promise.all([
      this.prisma.habit.findMany({
        where: { userId },
      }),
      this.prisma.habitLog.findMany({
        where: { userId },
      }),
    ]);

    if (habits.length === 0) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { currentStreak: 0, longestStreak: 0 },
      });
      return { currentStreak: 0, longestStreak: 0 };
    }

    const getLocalDateString = (d: Date): string => {
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };

    // Group logs by date string (yyyy-MM-dd)
    const logsByDate = new Map<string, typeof logs>();
    for (const log of logs) {
      const dateStr = log.date.toISOString().split('T')[0];
      if (!logsByDate.has(dateStr)) {
        logsByDate.set(dateStr, []);
      }
      logsByDate.get(dateStr)!.push(log);
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
    const earliestDateStr = getLocalDateString(earliestHabitDate);

    const today = new Date();
    const todayStr = getLocalDateString(today);
    
    const dateStrings: string[] = [];
    const checkDate = new Date();
    let checkDateStr = getLocalDateString(checkDate);

    while (checkDateStr >= earliestDateStr) {
      dateStrings.push(checkDateStr);
      checkDate.setDate(checkDate.getDate() - 1);
      checkDateStr = getLocalDateString(checkDate);
    }

    const dayStatus = new Map<string, 'success' | 'failure' | 'neutral'>();

    for (const dateStr of dateStrings) {
      const parts = dateStr.split('-');
      const y = parseInt(parts[0], 10);
      const m = parseInt(parts[1], 10) - 1;
      const d = parseInt(parts[2], 10);
      const dateObj = new Date(y, m, d, 12, 0, 0);
      const dayOfWeek = dateObj.getDay();
      const repeatDaysIndex = dayOfWeek === 0 ? 6 : dayOfWeek - 1;

      const scheduledHabits = habits.filter((h) => {
        const createdStr = getLocalDateString(h.createdAt);
        return h.repeatDays[repeatDaysIndex] && createdStr <= dateStr;
      });

      if (scheduledHabits.length === 0) {
        dayStatus.set(dateStr, 'neutral');
        continue;
      }

      const dayLogs = logsByDate.get(dateStr) ?? [];
      let allDone = true;

      for (const h of scheduledHabits) {
        const log = dayLogs.find((l) => l.habitId === h.id);
        if (!log) {
          allDone = false;
          break;
        }
      }

      if (allDone) {
        dayStatus.set(dateStr, 'success');
      } else {
        dayStatus.set(dateStr, 'failure');
      }
    }

    let currentStreak = 0;
    for (const dateStr of dateStrings) {
      const status = dayStatus.get(dateStr);
      if (status === 'success') {
        currentStreak++;
      } else if (status === 'failure') {
        if (dateStr === todayStr) {
          continue;
        } else {
          break;
        }
      } else {
        continue;
      }
    }

    let longestStreak = 0;
    let tempStreak = 0;
    const chronologicalDates = [...dateStrings].reverse();
    for (const dateStr of chronologicalDates) {
      const status = dayStatus.get(dateStr);
      if (status === 'success') {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (status === 'failure') {
        if (dateStr === todayStr) {
          // ignore
        } else {
          tempStreak = 0;
        }
      } else {
        // ignore
      }
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

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

