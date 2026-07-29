import { UsersService } from './users.service';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    getProfile(req: any): Promise<{
        name: string;
        email: string;
        id: string;
        avatarUrl: string | null;
        currentStreak: number;
        longestStreak: number;
        createdAt: Date;
        _count: {
            habits: number;
            goals: number;
        };
    } | null>;
    getStats(req: any): Promise<{
        currentStreak: number;
        longestStreak: number;
        totalCompletedHabits: number;
        activeGoals: number;
    }>;
    updateProfile(req: any, dto: {
        name?: string;
        avatarUrl?: string;
    }): Promise<{
        name: string;
        email: string;
        id: string;
        avatarUrl: string | null;
    }>;
    updateFcmToken(req: any, dto: {
        fcmToken: string;
    }): Promise<{
        name: string;
        email: string;
        id: string;
        googleId: string | null;
        appleId: string | null;
        passwordHash: string | null;
        avatarUrl: string | null;
        fcmToken: string | null;
        currentStreak: number;
        longestStreak: number;
        isEmailVerified: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
}
