import { NotificationsService } from './notifications.service';

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
      findMany: jest.fn().mockResolvedValue([]),
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      count: jest.fn().mockResolvedValue(0),
    },
    user: {
      findUnique: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
    device: {
      findMany: jest.fn().mockResolvedValue([]),
      upsert: jest.fn().mockResolvedValue({}),
      deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
  };
  const fcm = {
    sendPush: jest
      .fn()
      .mockResolvedValue({ success: true, isUnregistered: false }),
  };

  const service = new NotificationsService(prisma as any, fcm as any);

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.notification.create.mockResolvedValue(notification);
    prisma.device.findMany.mockResolvedValue([]);
    prisma.user.findUnique.mockResolvedValue({
      id: 'u1',
      name: 'User 1',
      fcmToken: 'tok',
    });
  });

  it('create() writes the in-app row and pushes to user devices', async () => {
    prisma.device.findMany.mockResolvedValue([{ fcmToken: 'tok' }]);

    const result = await service.create({
      userId: 'u1',
      type: 'HABIT_REMINDER',
      title: 'Drink water',
      body: 'Time for a glass',
    });

    expect(prisma.notification.create).toHaveBeenCalled();
    expect(prisma.device.findMany).toHaveBeenCalledWith({
      where: { userId: 'u1' },
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

  it('broadcasts push to all registered user devices', async () => {
    prisma.device.findMany.mockResolvedValue([
      { fcmToken: 'tok1' },
      { fcmToken: 'tok2' },
    ]);

    const result = await service.sendPush('u1', 'Title', 'Body');

    expect(fcm.sendPush).toHaveBeenCalledTimes(2);
    expect(fcm.sendPush).toHaveBeenCalledWith({
      token: 'tok1',
      title: 'Title',
      body: 'Body',
      data: undefined,
    });
    expect(fcm.sendPush).toHaveBeenCalledWith({
      token: 'tok2',
      title: 'Title',
      body: 'Body',
      data: undefined,
    });
    expect(result).toBe(true);
  });

  it('auto-prunes dead/unregistered tokens from Device and User tables', async () => {
    prisma.device.findMany.mockResolvedValue([{ fcmToken: 'dead-tok' }]);
    fcm.sendPush.mockResolvedValueOnce({
      success: false,
      isUnregistered: true,
    });

    const result = await service.sendPush('u1', 'Title', 'Body');

    expect(prisma.device.deleteMany).toHaveBeenCalledWith({
      where: { fcmToken: 'dead-tok' },
    });
    expect(prisma.user.updateMany).toHaveBeenCalledWith({
      where: { id: 'u1', fcmToken: 'dead-tok' },
      data: { fcmToken: null },
    });
    expect(result).toBe(false);
  });

  it('create() still returns the row when push fails (best-effort)', async () => {
    prisma.device.findMany.mockResolvedValue([{ fcmToken: 'tok' }]);
    fcm.sendPush.mockResolvedValueOnce({
      success: false,
      isUnregistered: false,
    });
    const result = await service.create({
      userId: 'u1',
      type: 'HABIT_REMINDER',
      title: 't',
      body: 'b',
    });
    expect(result).toEqual(notification);
  });

  it('create() skips push when user has no devices and no fcmToken', async () => {
    prisma.device.findMany.mockResolvedValue([]);
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

  it('registerDeviceToken() upserts device and updates user', async () => {
    const result = await service.registerDeviceToken('u1', 'new-token', 'ios');
    expect(prisma.device.upsert).toHaveBeenCalledWith({
      where: { fcmToken: 'new-token' },
      create: { userId: 'u1', fcmToken: 'new-token', platform: 'ios' },
      update: { userId: 'u1', platform: 'ios' },
    });
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'u1' },
      data: { fcmToken: 'new-token' },
    });
    expect(result).toEqual({ registered: true });
  });

  it('clearDeviceToken() deletes specific device and nulls matching user token', async () => {
    const result = await service.clearDeviceToken('u1', 'token-to-remove');
    expect(prisma.device.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'u1', fcmToken: 'token-to-remove' },
    });
    expect(prisma.user.updateMany).toHaveBeenCalledWith({
      where: { id: 'u1', fcmToken: 'token-to-remove' },
      data: { fcmToken: null },
    });
    expect(result).toEqual({ registered: false });
  });

  it('clearDeviceToken() without token clears all user devices and nulls user token', async () => {
    const result = await service.clearDeviceToken('u1');
    expect(prisma.device.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'u1' },
    });
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'u1' },
      data: { fcmToken: null },
    });
    expect(result).toEqual({ registered: false });
  });

  it('sendTestPush() broadcasts test push and writes MOTIVATION notification', async () => {
    prisma.device.findMany.mockResolvedValue([{ fcmToken: 'tok1' }]);
    prisma.user.findUnique.mockResolvedValue({
      id: 'u1',
      name: 'Alice',
      fcmToken: 'tok1',
    });

    const result = await service.sendTestPush('u1');

    expect(fcm.sendPush).toHaveBeenCalled();
    expect(prisma.notification.create).toHaveBeenCalledWith({
      data: {
        userId: 'u1',
        type: 'MOTIVATION',
        title: expect.stringContaining('Test Notification'),
        body: expect.stringContaining('Alice'),
        data: { type: 'test' },
      },
    });
    expect(result.success).toBe(true);
    expect(result.deviceCount).toBe(1);
  });
});
