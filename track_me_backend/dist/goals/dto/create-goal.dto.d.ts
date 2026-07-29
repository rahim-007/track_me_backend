import { GoalCategory, GoalPriority } from '@prisma/client';
export declare class CreateGoalDto {
    name: string;
    category?: GoalCategory;
    targetDate: string;
    priority?: GoalPriority;
    notes?: string;
}
