import { HabitCategory } from '@prisma/client';
export declare class CreateHabitDto {
    name: string;
    category?: HabitCategory;
    emoji?: string;
    color?: string;
    repeatDays?: boolean[];
    reminderTime?: string;
    notes?: string;
}
