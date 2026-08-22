import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FcmService } from './fcm.service';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmService,
  ) {}

  async getNotifications(userId: string, take = 50, skip = 0) {
    const cappedTake = Math.min(Math.max(take, 1), 100);
    const safeSkip = Math.max(skip, 0);
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { sentAt: 'desc' },
      take: cappedTake,
      skip: safeSkip,
    });
  }

  async markAsRead(userId: string, notificationId: string) {
    return this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async deleteNotification(userId: string, notificationId: string) {
    return this.prisma.notification.deleteMany({
      where: { id: notificationId, userId },
    });
  }

  async create(data: {
    userId: string;
    type: string;
    title: string;
    body: string;
    data?: object;
  }) {
    const notification = await this.prisma.notification.create({
      data: {
        userId: data.userId,
        type: data.type as any,
        title: data.title,
        body: data.body,
        data: data.data,
      },
    });

    // Best-effort push: a delivery failure must never fail the notification
    // write, so failures are swallowed here (FcmService already logs them).
    await this.sendPush(data.userId, data.title, data.body, data.data);

    return notification;
  }

  /**
   * Send a push notification to the user's registered device (if any).
   * Public so other modules can push without creating an in-app row (e.g.
   * habit reminders fired directly). Returns true when delivered.
   */
  async sendPush(
    userId: string,
    title: string,
    body: string,
    data?: object,
  ): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });
    if (!user?.fcmToken) return false;

    const delivered = await this.fcm.sendPush({
      token: user.fcmToken,
      title,
      body,
      data: data ? this.flattenData(data) : undefined,
    });
    return delivered;
  }

  /** Register (or refresh) the device token for the current user. */
  async registerDeviceToken(userId: string, fcmToken: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
    return { registered: true };
  }

  /** Clear the registered device token (e.g. after logout). */
  async clearDeviceToken(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: null },
    });
    return { registered: false };
  }

  /** FCM data payload values must be strings — coerce primitives/JSON. */
  private flattenData(data: object): Record<string, string> {
    const flat: Record<string, string> = {};
    for (const [key, value] of Object.entries(data)) {
      if (value == null) continue;
      if (typeof value === 'string') {
        flat[key] = value;
      } else if (typeof value === 'object') {
        flat[key] = JSON.stringify(value);
      } else {
        flat[key] = String(value);
      }
    }
    return flat;
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { count };
  }
}
