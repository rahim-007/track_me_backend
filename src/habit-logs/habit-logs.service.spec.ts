import { NotFoundException } from '@nestjs/common';
import { HabitLogsService } from './habit-logs.service';

describe('HabitLogsService', () => {
  let service: HabitLogsService;
  let prisma: any;

  beforeEach(() => {
    prisma = {
      habit: {
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      habitLog: {
        findFirst: jest.fn(),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        count: jest.fn(),
      },
    };
    service = new HabitLogsService(prisma);
  });

  describe('completeHabit', () => {
    it('creates a new completion and increments totalCompleted if no log exists', async () => {
      prisma.habit.findFirst.mockResolvedValue({ id: 'h1' });
      prisma.habitLog.findFirst.mockResolvedValue(null);
      prisma.habitLog.upsert.mockResolvedValue({
        id: 'l1',
        habitId: 'h1',
        isSkipped: false,
      });

      const result = await service.completeHabit('u1', 'h1', '2026-08-12');

      expect(prisma.habitLog.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { habitId_date: { habitId: 'h1', date: new Date('2026-08-12') } },
        }),
      );
      expect(prisma.habit.update).toHaveBeenCalledWith({
        where: { id: 'h1' },
        data: { totalCompleted: { increment: 1 } },
      });
      expect(result.isSkipped).toBe(false);
    });

    it('returns existing record idempotently if already completed', async () => {
      prisma.habit.findFirst.mockResolvedValue({ id: 'h1' });
      prisma.habitLog.findFirst.mockResolvedValue({
        id: 'l1',
        habitId: 'h1',
        isSkipped: false,
      });

      const result = await service.completeHabit('u1', 'h1', '2026-08-12');

      expect(result.id).toBe('l1');
      expect(prisma.habitLog.upsert).not.toHaveBeenCalled();
      expect(prisma.habit.update).not.toHaveBeenCalled();
    });

    it('transitions existing skipped record to completed and increments totalCompleted', async () => {
      prisma.habit.findFirst.mockResolvedValue({ id: 'h1' });
      prisma.habitLog.findFirst.mockResolvedValue({
        id: 'l1',
        habitId: 'h1',
        isSkipped: true,
        skipReason: 'Tired',
      });
      prisma.habitLog.upsert.mockResolvedValue({
        id: 'l1',
        habitId: 'h1',
        isSkipped: false,
        skipReason: null,
      });

      const result = await service.completeHabit('u1', 'h1', '2026-08-12');

      expect(prisma.habitLog.upsert).toHaveBeenCalled();
      expect(prisma.habit.update).toHaveBeenCalledWith({
        where: { id: 'h1' },
        data: { totalCompleted: { increment: 1 } },
      });
      expect(result.isSkipped).toBe(false);
    });

    it('throws NotFoundException if habit does not belong to user', async () => {
      prisma.habit.findFirst.mockResolvedValue(null);

      await expect(service.completeHabit('u1', 'h1', '2026-08-12')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('skipHabit', () => {
    it('decrements totalCompleted when skipping an already completed habit', async () => {
      prisma.habit.findFirst.mockResolvedValue({ id: 'h1' });
      prisma.habitLog.findFirst.mockResolvedValue({
        id: 'l1',
        habitId: 'h1',
        isSkipped: false,
      });
      prisma.habitLog.upsert.mockResolvedValue({
        id: 'l1',
        habitId: 'h1',
        isSkipped: true,
      });

      await service.skipHabit('u1', 'h1', '2026-08-12', 'Rest day');

      expect(prisma.habit.update).toHaveBeenCalledWith({
        where: { id: 'h1' },
        data: { totalCompleted: { decrement: 1 } },
      });
    });
  });

  describe('uncomplete', () => {
    it('deletes log and decrements totalCompleted', async () => {
      prisma.habit.findFirst.mockResolvedValue({ id: 'h1' });
      prisma.habitLog.findFirst.mockResolvedValue({
        id: 'l1',
        habitId: 'h1',
        isSkipped: false,
      });
      prisma.habitLog.deleteMany.mockResolvedValue({ count: 1 });

      await service.uncomplete('u1', 'h1', '2026-08-12');

      expect(prisma.habit.update).toHaveBeenCalledWith({
        where: { id: 'h1' },
        data: { totalCompleted: { decrement: 1 } },
      });
    });
  });
});
