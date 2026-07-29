import { PrismaService } from '../prisma/prisma.service';
export declare class UsersService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getProfile(userId: string): Promise<{
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
    updateProfile(userId: string, data: {
        name?: string;
        avatarUrl?: string;
    }): Promise<{
        name: string;
        email: string;
        id: string;
        avatarUrl: string | null;
    }>;
    updateFcmToken(userId: string, fcmToken: string): Promise<{
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
    getStats(userId: string): Promise<{
        currentStreak: number;
        longestStreak: number;
        totalCompletedHabits: number;
        activeGoals: number;
    }>;
}
