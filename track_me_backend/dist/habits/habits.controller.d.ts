import { HabitsService } from './habits.service';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';
export declare class HabitsController {
    private readonly habitsService;
    constructor(habitsService: HabitsService);
    findAll(req: any): Promise<any[]>;
    findOne(req: any, id: string): Promise<({
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
    create(req: any, dto: CreateHabitDto): Promise<{
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
    update(req: any, id: string, dto: UpdateHabitDto): Promise<import(".prisma/client").Prisma.BatchPayload>;
    remove(req: any, id: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    getStreak(req: any, id: string): Promise<{
        currentStreak: number;
    }>;
}
