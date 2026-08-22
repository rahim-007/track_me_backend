import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { computeHabitStreak } from '../streaks/streaks.util';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';

@Injectable()
export class HabitsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const weekStart = this.getWeekStart();
    const gteDate = yesterday < weekStart ? yesterday : weekStart;

    const habits = await this.prisma.habit.findMany({
      where: { userId, isActive: true },
      include: {
        logs: {
          where: {
            date: {
              gte: gteDate,
              lte: this.getWeekEnd(),
            },
          },
          orderBy: { date: 'asc' },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    return habits.map((habit: any) => this.formatHabitWithDates(habit));
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
    const habit = await this.prisma.habit.findFirst({
      where: { id: habitId, userId, isActive: true },
      include: {
        // Only valid non-skipped completions can extend a streak.
        logs: {
          where: { isSkipped: false },
          orderBy: { date: 'desc' },
        },
      },
    });
    if (!habit) {
      // Never reveal whether the id exists but belongs to someone else.
      throw new NotFoundException('Habit not found');
    }

    // Per-habit streak is schedule-aware: unscheduled days are ignored and
    // never break the streak; a scheduled day that is skipped or missing does.
    const completedDates = new Set(
      habit.logs.map((l: any) => l.date.toISOString().split('T')[0]),
    );
    const currentStreak = computeHabitStreak(habit, completedDates);

    return { currentStreak };
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
