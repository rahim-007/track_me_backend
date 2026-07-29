import { NotificationsService } from './notifications.service';
export declare class NotificationsController {
    private readonly notificationsService;
    constructor(notificationsService: NotificationsService);
    getNotifications(req: any): Promise<{
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
    getUnreadCount(req: any): Promise<{
        count: number;
    }>;
    markAsRead(req: any, id: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    markAllAsRead(req: any): Promise<import(".prisma/client").Prisma.BatchPayload>;
}
