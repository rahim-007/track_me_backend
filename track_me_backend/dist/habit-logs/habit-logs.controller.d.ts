import { HabitLogsService } from './habit-logs.service';
export declare class HabitLogsController {
    private readonly habitLogsService;
    constructor(habitLogsService: HabitLogsService);
    complete(req: any, dto: {
        habitId: string;
        date: string;
    }): Promise<{
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
    skip(req: any, dto: {
        habitId: string;
        date: string;
        reason: string;
    }): Promise<{
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
    uncomplete(req: any, habitId: string, date: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    getWeeklyStats(req: any): Promise<{
        totalHabits: number;
        completedThisWeek: number;
        skippedThisWeek: number;
        completionRate: number;
    }>;
}
