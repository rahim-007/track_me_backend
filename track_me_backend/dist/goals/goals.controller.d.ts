import { GoalsService } from './goals.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalDto } from './dto/update-goal.dto';
export declare class GoalsController {
    private readonly goalsService;
    constructor(goalsService: GoalsService);
    findAll(req: any): Promise<{
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
    findOne(req: any, id: string): Promise<({
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
    create(req: any, dto: CreateGoalDto): Promise<{
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
    update(req: any, id: string, dto: UpdateGoalDto): Promise<import(".prisma/client").Prisma.BatchPayload>;
    updateProgress(req: any, id: string, dto: {
        progress: number;
        notes?: string;
    }): Promise<import(".prisma/client").Prisma.BatchPayload>;
    remove(req: any, id: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
}
