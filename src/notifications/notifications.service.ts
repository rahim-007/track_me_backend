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

  async clearAllNotifications(userId: string) {
    return this.prisma.notification.deleteMany({
      where: { userId },
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
   * Send a push notification to all the user's registered devices (if any).
   * Automatically prunes unregistered/dead tokens.
   * Public so other modules can push without creating an in-app row (e.g.
   * habit reminders fired directly). Returns true when at least one device was reached.
   */
  async sendPush(
    userId: string,
    title: string,
    body: string,
    data?: object,
  ): Promise<boolean> {
    const devices = await this.prisma.device.findMany({
      where: { userId },
      select: { fcmToken: true },
    });

    let tokens = devices.map((d) => d.fcmToken);

    if (tokens.length === 0) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true },
      });
      if (user?.fcmToken) {
        tokens = [user.fcmToken];
      }
    }

    if (tokens.length === 0) return false;

    const payload = data ? this.flattenData(data) : undefined;
    const sendResults = await Promise.all(
      tokens.map(async (token) => {
        const res = await this.fcm.sendPush({
          token,
          title,
          body,
          data: payload,
        });

        const success = typeof res === 'boolean' ? res : res.success;
        const isUnregistered = typeof res === 'object' && res.isUnregistered;

        if (isUnregistered) {
          // Auto-prune dead token from Device table and User.fcmToken
          await this.prisma.device.deleteMany({
            where: { fcmToken: token },
          });
          await this.prisma.user.updateMany({
            where: { id: userId, fcmToken: token },
            data: { fcmToken: null },
          });
        }

        return success;
      }),
    );

    return sendResults.some((s) => s === true);
  }

  /** Register (or refresh) the device token for the current user. */
  async registerDeviceToken(
    userId: string,
    fcmToken: string,
    platform = 'android',
  ) {
    await this.prisma.device.upsert({
      where: { fcmToken },
      create: {
        userId,
        fcmToken,
        platform: platform || 'android',
      },
      update: {
        userId,
        platform: platform || 'android',
      },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });

    return { registered: true };
  }

  /** Clear the registered device token(s) (e.g. after logout). */
  async clearDeviceToken(userId: string, fcmToken?: string) {
    if (fcmToken) {
      await this.prisma.device.deleteMany({
        where: { userId, fcmToken },
      });
      await this.prisma.user.updateMany({
        where: { id: userId, fcmToken },
        data: { fcmToken: null },
      });
    } else {
      await this.prisma.device.deleteMany({
        where: { userId },
      });
      await this.prisma.user.update({
        where: { id: userId },
        data: { fcmToken: null },
      });
    }

    return { registered: false };
  }

  /** Send an immediate test push to the authenticated user's device(s) for diagnostics. */
  async sendTestPush(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, name: true, fcmToken: true },
    });

    if (!user) {
      return { success: false, message: 'User not found' };
    }

    const devices = await this.prisma.device.findMany({
      where: { userId },
      select: { fcmToken: true },
    });

    let tokens = devices.map((d) => d.fcmToken);
    if (tokens.length === 0 && user.fcmToken) {
      tokens = [user.fcmToken];
    }

    if (tokens.length === 0) {
      return {
        success: false,
        message:
          'No FCM device token registered for this user yet. Open the app on your phone to register your token.',
      };
    }

    const title = '🎉 Test Notification';
    const body = `Hi ${user.name || 'there'}! Push notifications are working perfectly on your device.`;

    const delivered = await this.sendPush(userId, title, body, {
      type: 'test',
      category: 'general',
    });

    // Also write an in-app notification row
    await this.prisma.notification.create({
      data: {
        userId,
        type: 'MOTIVATION',
        title,
        body,
        data: { type: 'test' },
      },
    });

    return {
      success: delivered,
      deliveredToFCM: delivered,
      deviceCount: tokens.length,
      message: delivered
        ? `Test push notification sent successfully to ${tokens.length} device(s)!`
        : 'FCM push could not be delivered. Check backend Firebase credentials or FCM token validity.',
    };
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
