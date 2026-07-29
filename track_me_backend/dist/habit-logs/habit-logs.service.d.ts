import { PrismaService } from '../prisma/prisma.service';
export declare class HabitLogsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    completeHabit(userId: string, habitId: string, date: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        isSkipped: boolean;
        notes: string | null;
        date: Date;
        habitId: string;
        completedAt: Date | null;
        skipReason: string | null;
    }>;
    skipHabit(userId: string, habitId: string, date: string, reason: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        isSkipped: boolean;
        notes: string | null;
        date: Date;
        habitId: string;
        completedAt: Date | null;
        skipReason: string | null;
    }>;
    uncomplete(userId: string, habitId: string, date: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    getWeeklyStats(userId: string): Promise<{
        totalHabits: number;
        completedThisWeek: number;
        skippedThisWeek: number;
        completionRate: number;
    }>;
    private getWeekStart;
    private getWeekEnd;
}
