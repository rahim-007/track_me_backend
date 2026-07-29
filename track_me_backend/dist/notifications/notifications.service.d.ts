import { PrismaService } from '../prisma/prisma.service';
export declare class NotificationsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getNotifications(userId: string): Promise<{
        type: import(".prisma/client").$Enums.NotificationType;
        title: string;
        id: string;
        data: import("@prisma/client/runtime/library").JsonValue | null;
        userId: string;
        body: string;
        isRead: boolean;
        sentAt: Date;
        readAt: Date | null;
    }[]>;
    markAsRead(userId: string, notificationId: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    markAllAsRead(userId: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    create(data: {
        userId: string;
        type: string;
        title: string;
        body: string;
        data?: object;
    }): Promise<{
        type: import(".prisma/client").$Enums.NotificationType;
        title: string;
        id: string;
        data: import("@prisma/client/runtime/library").JsonValue | null;
        userId: string;
        body: string;
        isRead: boolean;
        sentAt: Date;
        readAt: Date | null;
    }>;
    getUnreadCount(userId: string): Promise<{
        count: number;
    }>;
}
