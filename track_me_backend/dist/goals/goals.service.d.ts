import { PrismaService } from '../prisma/prisma.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalDto } from './dto/update-goal.dto';
export declare class GoalsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findAll(userId: string): Promise<{
        description: string | null;
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        status: import(".prisma/client").$Enums.GoalStatus;
        category: import(".prisma/client").$Enums.GoalCategory;
        notes: string | null;
        targetDate: Date;
        priority: import(".prisma/client").$Enums.GoalPriority;
        progress: number;
    }[]>;
    findOne(userId: string, id: string): Promise<({
        progressHistory: {
            id: string;
            notes: string | null;
            progress: number;
            recordedAt: Date;
            goalId: string;
        }[];
    } & {
        description: string | null;
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        status: import(".prisma/client").$Enums.GoalStatus;
        category: import(".prisma/client").$Enums.GoalCategory;
        notes: string | null;
        targetDate: Date;
        priority: import(".prisma/client").$Enums.GoalPriority;
        progress: number;
    }) | null>;
    create(userId: string, dto: CreateGoalDto): Promise<{
        description: string | null;
        name: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        status: import(".prisma/client").$Enums.GoalStatus;
        category: import(".prisma/client").$Enums.GoalCategory;
        notes: string | null;
        targetDate: Date;
        priority: import(".prisma/client").$Enums.GoalPriority;
        progress: number;
    }>;
    update(userId: string, id: string, dto: UpdateGoalDto): Promise<import(".prisma/client").Prisma.BatchPayload>;
    updateProgress(userId: string, id: string, progress: number, notes?: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    remove(userId: string, id: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
}
