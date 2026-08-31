import { UsersService } from './users.service';

describe('UsersService', () => {
  const prisma: Record<string, any> = {
    habit: { findMany: jest.fn().mockResolvedValue([]) },
    habitLog: { findMany: jest.fn().mockResolvedValue([]) },
    user: { update: jest.fn(), findUnique: jest.fn() },
    device: {
      upsert: jest.fn().mockResolvedValue({}),
      deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
    goal: { count: jest.fn().mockResolvedValue(0) },
    $transaction: jest.fn(),
  };

  beforeEach(() => {
    jest.resetAllMocks();
    prisma.habit.findMany.mockResolvedValue([]);
    prisma.habitLog.findMany.mockResolvedValue([]);
    prisma.goal.count.mockResolvedValue(0);
    prisma.device.upsert.mockResolvedValue({});
    prisma.device.deleteMany.mockResolvedValue({ count: 1 });
  });

  it('updateProfile persists the timezone and returns it', async () => {
    prisma.user.update.mockResolvedValue({
      id: 'u1',
      email: 'a@b.c',
      name: 'A',
      avatarUrl: null,
      timezone: 'Asia/Kolkata',
    });
    const service = new UsersService(prisma as any);

    const result = await service.updateProfile('u1', {
      timezone: 'Asia/Kolkata',
    });

    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'u1' },
      data: { timezone: 'Asia/Kolkata' },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        timezone: true,
      },
    });
    expect(result.timezone).toBe('Asia/Kolkata');
  });

  it('getProfile selects the stored timezone', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: 'u1',
      email: 'a@b.c',
      name: 'A',
      avatarUrl: null,
      timezone: 'America/New_York',
      createdAt: new Date(),
      _count: { habits: 0, goals: 0 },
    });
    const service = new UsersService(prisma as any);

    const result = await service.getProfile('u1');

    expect(prisma.user.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        select: expect.objectContaining({ timezone: true }),
      }),
    );
    expect(result?.timezone).toBe('America/New_York');
  });

  describe('updateFcmToken', () => {
    it('upserts device and updates user when fcmToken provided', async () => {
      prisma.user.update.mockResolvedValue({ id: 'u1', fcmToken: 'tok123' });
      const service = new UsersService(prisma as any);

      await service.updateFcmToken('u1', 'tok123', 'ios');

      expect(prisma.device.upsert).toHaveBeenCalledWith({
        where: { fcmToken: 'tok123' },
        create: { userId: 'u1', fcmToken: 'tok123', platform: 'ios' },
        update: { userId: 'u1', platform: 'ios' },
      });
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: { fcmToken: 'tok123' },
      });
    });

    it('clears devices and nulls user fcmToken when empty', async () => {
      prisma.user.update.mockResolvedValue({ id: 'u1', fcmToken: null });
      const service = new UsersService(prisma as any);

      await service.updateFcmToken('u1', '');

      expect(prisma.device.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'u1' },
      });
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: { fcmToken: null },
      });
    });
  });

  // ─── deleteAccount ──────────────────────────────────────────────────────────

  describe('deleteAccount', () => {
    let tx: Record<string, any>;

    beforeEach(() => {
      tx = {
        user: {
          findUnique: jest.fn(),
          update: jest.fn(),
          delete: jest.fn(),
        },
        device: {
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
      };
      prisma.$transaction = jest.fn((cb: (t: any) => any) => cb(tx));
    });

    it('deletes the user and returns true', async () => {
      tx.user.findUnique.mockResolvedValue({
        id: 'u1',
        email: 'a@b.c',
        name: 'A',
        fcmToken: 'some-token',
      });
      tx.user.update.mockResolvedValue({});
      tx.user.delete.mockResolvedValue({});

      const service = new UsersService(prisma as any);
      const result = await service.deleteAccount('u1');

      expect(result).toBe(true);
      // FCM token and devices should be cleared before deletion
      expect(tx.device.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'u1' },
      });
      expect(tx.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: { fcmToken: null },
      });
      expect(tx.user.delete).toHaveBeenCalledWith({ where: { id: 'u1' } });
    });

    it('returns null for a nonexistent user', async () => {
      tx.user.findUnique.mockResolvedValue(null);

      const service = new UsersService(prisma as any);
      const result = await service.deleteAccount('nonexistent');

      expect(result).toBeNull();
      expect(tx.user.delete).not.toHaveBeenCalled();
    });

    it('skips fcmToken update when token is already null', async () => {
      tx.user.findUnique.mockResolvedValue({
        id: 'u1',
        email: 'a@b.c',
        name: 'A',
        fcmToken: null,
      });
      tx.user.delete.mockResolvedValue({});

      const service = new UsersService(prisma as any);
      const result = await service.deleteAccount('u1');

      expect(result).toBe(true);
      expect(tx.user.update).not.toHaveBeenCalled();
      expect(tx.user.delete).toHaveBeenCalledWith({ where: { id: 'u1' } });
    });

    it('uses a Prisma transaction for atomicity', async () => {
      tx.user.findUnique.mockResolvedValue({
        id: 'u1',
        email: 'a@b.c',
        name: 'A',
        fcmToken: null,
      });
      tx.user.delete.mockResolvedValue({});

      const service = new UsersService(prisma as any);
      await service.deleteAccount('u1');

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    });
  });
});
