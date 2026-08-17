import { NotificationsService } from './notifications.service';
import { FcmService } from './fcm.service';

describe('NotificationsService', () => {
  const notification = {
    id: 'n1',
    userId: 'u1',
    type: 'HABIT_REMINDER',
    title: 'Drink water',
    body: 'Time for a glass',
    data: null,
    isRead: false,
    sentAt: new Date(),
    readAt: null,
  };

  const prisma = {
    notification: {
      create: jest.fn().mockResolvedValue(notification),
    },
    user: {
      findUnique: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
    },
  };
  const fcm = { sendPush: jest.fn().mockResolvedValue(true) };

  const service = new NotificationsService(prisma as any, fcm as any);

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.notification.create.mockResolvedValue(notification);
    prisma.user.findUnique.mockResolvedValue({ fcmToken: 'tok' });
  });

  it('create() writes the in-app row and pushes to the user token', async () => {
    const result = await service.create({
      userId: 'u1',
      type: 'HABIT_REMINDER',
      title: 'Drink water',
      body: 'Time for a glass',
    });

    expect(prisma.notification.create).toHaveBeenCalled();
    expect(prisma.user.findUnique).toHaveBeenCalledWith({
      where: { id: 'u1' },
      select: { fcmToken: true },
    });
    expect(fcm.sendPush).toHaveBeenCalledWith({
      token: 'tok',
      title: 'Drink water',
      body: 'Time for a glass',
      data: undefined,
    });
    expect(result).toEqual(notification);
  });

  it('create() still returns the row when push fails (best-effort)', async () => {
    fcm.sendPush.mockResolvedValueOnce(false);
    const result = await service.create({
      userId: 'u1',
      type: 'HABIT_REMINDER',
      title: 't',
      body: 'b',
    });
    expect(result).toEqual(notification);
  });

  it('create() skips push when the user has no device token', async () => {
    prisma.user.findUnique.mockResolvedValue({ fcmToken: null });
    const result = await service.create({
      userId: 'u1',
      type: 'HABIT_REMINDER',
      title: 't',
      body: 'b',
    });
    expect(fcm.sendPush).not.toHaveBeenCalled();
    expect(result).toEqual(notification);
  });

  it('registerDeviceToken() saves the token on the user', async () => {
    const result = await service.registerDeviceToken('u1', 'new-token');
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'u1' },
      data: { fcmToken: 'new-token' },
    });
    expect(result).toEqual({ registered: true });
  });

  it('clearDeviceToken() nulls the token on the user', async () => {
    const result = await service.clearDeviceToken('u1');
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'u1' },
      data: { fcmToken: null },
    });
    expect(result).toEqual({ registered: false });
  });
});
