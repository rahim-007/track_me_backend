import { UsersService } from './users.service';

describe('UsersService', () => {
  const prisma = {
    habit: { findMany: jest.fn().mockResolvedValue([]) },
    habitLog: { findMany: jest.fn().mockResolvedValue([]) },
    user: { update: jest.fn(), findUnique: jest.fn() },
    goal: { count: jest.fn().mockResolvedValue(0) },
  };

  beforeEach(() => {
    jest.resetAllMocks();
    prisma.habit.findMany.mockResolvedValue([]);
    prisma.habitLog.findMany.mockResolvedValue([]);
    prisma.goal.count.mockResolvedValue(0);
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

    const result = await service.updateProfile('u1', { timezone: 'Asia/Kolkata' });

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
});
