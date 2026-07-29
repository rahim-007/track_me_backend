import { PrismaService } from '../prisma/prisma.service';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';
export declare class HabitsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findAll(userId: string): Promise<any[]>;
    findOne(userId: string, id: string): Promise<({
        logs: {
            id: string;
            createdAt: Date;
            userId: string;
            isSkipped: boolean;
            notes: string | null;
            date: Date;
            habitId: string;
            completedAt: Date | null;
            skipReason: string | null;
        }[];
    } & {
        name: string;
        id: string;
        currentStreak: number;
        longestStreak: number;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        category: import(".prisma/client").$Enums.HabitCategory;
        emoji: string | null;
        color: string | null;
        repeatDays: boolean[];
        reminderTime: string | null;
        notes: string | null;
        isActive: boolean;
        totalCompleted: number;
    }) | null>;
    create(userId: string, dto: CreateHabitDto): Promise<{
        name: string;
        id: string;
        currentStreak: number;
        longestStreak: number;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        category: import(".prisma/client").$Enums.HabitCategory;
        emoji: string | null;
        color: string | null;
        repeatDays: boolean[];
        reminderTime: string | null;
        notes: string | null;
        isActive: boolean;
        totalCompleted: number;
    }>;
    update(userId: string, id: string, dto: UpdateHabitDto): Promise<import(".prisma/client").Prisma.BatchPayload>;
    remove(userId: string, id: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    getStreak(userId: string, habitId: string): Promise<{
        currentStreak: number;
    }>;
    private formatHabitWithDates;
    private getWeekStart;
    private getWeekEnd;
}
