import { DebtService } from './debt.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';

const debtRow = (over: Partial<any> = {}) => ({
  id: 'd1',
  userId: 'u1',
  name: 'Personal Loan',
  originalAmount: 50000,
  lenderName: 'Bank',
  dueDate: null,
  installmentAmount: 5000,
  description: null,
  status: 'ACTIVE',
  createdAt: new Date('2026-08-01T00:00:00Z'),
  updatedAt: new Date('2026-08-01T00:00:00Z'),
  payments: [],
  ...over,
});

const paymentRow = (over: Partial<any> = {}) => ({
  id: 'p1',
  debtId: 'd1',
  amount: 5000,
  paymentDate: new Date('2026-08-10T00:00:00Z'),
  note: null,
  createdAt: new Date('2026-08-10T00:00:00Z'),
  ...over,
});

describe('DebtService', () => {
  const prisma = {
    debt: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    debtPayment: { create: jest.fn() },
  };
  const service = new DebtService(prisma as any);

  beforeEach(() => {
    jest.resetAllMocks();
  });

  describe('create', () => {
    it('creates a debt with the provided fields and derived totals', async () => {
      prisma.debt.create.mockResolvedValue(
        debtRow({ lenderName: 'Bank', installmentAmount: 5000 }),
      );
      const result = await service.create('u1', {
        name: 'Personal Loan',
        originalAmount: 50000,
        lenderName: 'Bank',
        installmentAmount: 5000,
      });

      expect(prisma.debt.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'u1',
          name: 'Personal Loan',
          originalAmount: 50000,
          lenderName: 'Bank',
          installmentAmount: 5000,
        }),
        include: { payments: { select: { amount: true } } },
      });
      expect(result.status).toBe('ACTIVE');
      expect(result.totalPaid).toBe(0);
      expect(result.remainingBalance).toBe(50000);
    });

    it('normalizes missing optional fields to null', async () => {
      prisma.debt.create.mockResolvedValue(debtRow());
      await service.create('u1', { name: 'Loan', originalAmount: 1000 });
      expect(prisma.debt.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          lenderName: null,
          dueDate: null,
          installmentAmount: null,
          description: null,
        }),
        include: { payments: { select: { amount: true } } },
      });
    });
  });

  describe('findAll', () => {
    it('returns only the user debts with derived totals', async () => {
      prisma.debt.findMany.mockResolvedValue([
        debtRow({ id: 'd1', payments: [{ amount: 15000 }] }),
        debtRow({ id: 'd2', userId: 'u1', name: 'Car Loan', originalAmount: 20000 }),
      ]);
      const result = await service.findAll('u1');

      expect(prisma.debt.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1' },
        orderBy: { createdAt: 'desc' },
        include: { payments: { select: { amount: true } } },
      });
      expect(result).toHaveLength(2);
      expect(result[0].totalPaid).toBe(15000);
      expect(result[0].remainingBalance).toBe(35000);
      expect(result[1].remainingBalance).toBe(20000);
      // payments are stripped from the list payload
      expect(result[0].payments).toBeUndefined();
    });

    it('clamps remaining balance at 0 (never negative)', async () => {
      prisma.debt.findMany.mockResolvedValue([
        debtRow({ payments: [{ amount: 60000 }] }), // over-paid edge from raw data
      ]);
      const result = await service.findAll('u1');
      expect(result[0].remainingBalance).toBe(0);
    });
  });

  describe('findOne', () => {
    it('returns the debt with full payment history ordered newest first', async () => {
      prisma.debt.findFirst.mockResolvedValue(
        debtRow({
          payments: [
            paymentRow({ id: 'p2', amount: 10000, paymentDate: new Date('2026-08-15T00:00:00Z') }),
            paymentRow({ id: 'p1', amount: 5000, paymentDate: new Date('2026-08-10T00:00:00Z') }),
          ],
        }),
      );
      const result = await service.findOne('u1', 'd1');

      expect(prisma.debt.findFirst).toHaveBeenCalledWith({
        where: { id: 'd1', userId: 'u1' },
        include: { payments: { orderBy: { paymentDate: 'desc' } } },
      });
      expect(result.totalPaid).toBe(15000);
      expect(result.remainingBalance).toBe(35000);
      expect(result.payments).toHaveLength(2);
      expect(result.payments[0].id).toBe('p2');
    });

    it('throws 404 for another user debt (ownership)', async () => {
      prisma.debt.findFirst.mockResolvedValue(null);
      await expect(service.findOne('u2', 'd1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('recordPayment', () => {
    it('records a payment and updates totals', async () => {
      prisma.debt.findFirst.mockResolvedValue(
        debtRow({ payments: [{ amount: 15000 }] }),
      );
      prisma.debtPayment.create.mockResolvedValue(paymentRow({ amount: 5000 }));
      prisma.debt.findUnique.mockResolvedValue(
        debtRow({
          payments: [
            paymentRow({ id: 'p2', amount: 5000, paymentDate: new Date('2026-08-17T00:00:00Z') }),
            paymentRow({ id: 'p1', amount: 15000, paymentDate: new Date('2026-08-10T00:00:00Z') }),
          ],
        }),
      );

      const result = await service.recordPayment('u1', 'd1', {
        amount: 5000,
        paymentDate: '2026-08-17',
      });

      expect(prisma.debtPayment.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          debtId: 'd1',
          amount: 5000,
          paymentDate: new Date('2026-08-17'),
          note: null,
        }),
      });
      expect(result.totalPaid).toBe(20000);
      expect(result.remainingBalance).toBe(30000);
      expect(result.status).toBe('ACTIVE');
      expect(prisma.debt.update).not.toHaveBeenCalled(); // not paid off yet
    });

    it('defaults paymentDate to now when omitted', async () => {
      prisma.debt.findFirst.mockResolvedValue(debtRow());
      prisma.debtPayment.create.mockResolvedValue(paymentRow());
      prisma.debt.findUnique.mockResolvedValue(debtRow({ payments: [{ amount: 1000 }] }));
      await service.recordPayment('u1', 'd1', { amount: 1000 });
      const call = prisma.debtPayment.create.mock.calls[0][0];
      expect(call.data.paymentDate).toBeInstanceOf(Date);
    });

    it('rejects a payment larger than the remaining balance', async () => {
      prisma.debt.findFirst.mockResolvedValue(
        debtRow({ payments: [{ amount: 15000 }] }), // remaining 35000
      );
      await expect(
        service.recordPayment('u1', 'd1', { amount: 35001 }),
      ).rejects.toThrow(BadRequestException);
      expect(prisma.debtPayment.create).not.toHaveBeenCalled();
    });

    it('auto-marks the debt PAID when the balance reaches zero and keeps history', async () => {
      prisma.debt.findFirst.mockResolvedValue(
        debtRow({ payments: [{ amount: 15000 }] }), // remaining 35000
      );
      prisma.debtPayment.create.mockResolvedValue(paymentRow({ amount: 35000 }));
      prisma.debt.findUnique.mockResolvedValue(
        debtRow({
          status: 'PAID',
          payments: [
            paymentRow({ id: 'p3', amount: 35000 }),
            paymentRow({ id: 'p2', amount: 5000 }),
            paymentRow({ id: 'p1', amount: 10000 }),
          ],
        }),
      );

      const result = await service.recordPayment('u1', 'd1', { amount: 35000 });

      expect(prisma.debt.update).toHaveBeenCalledWith({
        where: { id: 'd1' },
        data: { status: 'PAID' },
      });
      expect(result.status).toBe('PAID');
      expect(result.totalPaid).toBe(50000);
      expect(result.remainingBalance).toBe(0);
      expect(result.payments).toHaveLength(3); // history preserved
    });

    it('throws 404 when recording a payment on another user debt', async () => {
      prisma.debt.findFirst.mockResolvedValue(null);
      await expect(
        service.recordPayment('u2', 'd1', { amount: 100 }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('update', () => {
    it('updates editable fields only', async () => {
      prisma.debt.findFirst.mockResolvedValue(debtRow());
      prisma.debt.update.mockResolvedValue(
        debtRow({ name: 'Car Loan', lenderName: 'Friend', installmentAmount: 8000 }),
      );
      const result = await service.update('u1', 'd1', {
        name: 'Car Loan',
        lenderName: 'Friend',
        installmentAmount: 8000,
      });

      expect(prisma.debt.update).toHaveBeenCalledWith({
        where: { id: 'd1' },
        data: expect.objectContaining({
          name: 'Car Loan',
          lenderName: 'Friend',
          installmentAmount: 8000,
        }),
        include: { payments: { select: { amount: true } } },
      });
      expect(result.name).toBe('Car Loan');
      expect(result.totalPaid).toBe(0);
    });

    it('rejects lowering originalAmount below total paid', async () => {
      prisma.debt.findFirst.mockResolvedValue(
        debtRow({ payments: [{ amount: 30000 }] }),
      );
      await expect(
        service.update('u1', 'd1', { originalAmount: 20000 }),
      ).rejects.toThrow(BadRequestException);
      expect(prisma.debt.update).not.toHaveBeenCalled();
    });

    it('throws 404 for another user debt', async () => {
      prisma.debt.findFirst.mockResolvedValue(null);
      await expect(
        service.update('u2', 'd1', { name: 'X' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('deletes the debt (cascades payments)', async () => {
      prisma.debt.findFirst.mockResolvedValue(debtRow());
      prisma.debt.delete.mockResolvedValue({ id: 'd1' });
      const result = await service.remove('u1', 'd1');
      expect(prisma.debt.delete).toHaveBeenCalledWith({ where: { id: 'd1' } });
      expect(result).toEqual({ deleted: true });
    });

    it('throws 404 when deleting another user debt', async () => {
      prisma.debt.findFirst.mockResolvedValue(null);
      await expect(service.remove('u2', 'd1')).rejects.toThrow(NotFoundException);
      expect(prisma.debt.delete).not.toHaveBeenCalled();
    });
  });
});
