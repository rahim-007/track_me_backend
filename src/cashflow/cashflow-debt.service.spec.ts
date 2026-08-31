import { NotFoundException } from '@nestjs/common';
import { CashFlowDebtService } from './cashflow-debt.service';

function makePrismaMock() {
  let seq = 0;
  const debts: any[] = [];
  return {
    debts,
    cashFlowDebt: {
      findMany: async ({ where }: any) =>
        debts.filter((d) => d.userId === where.userId),
      aggregate: async ({ where }: any) => ({
        _sum: {
          amount: debts
            .filter(
              (d) =>
                d.userId === where.userId &&
                d.direction === where.direction &&
                d.settled === where.settled,
            )
            .reduce((s, d) => s + d.amount, 0),
        },
      }),
      create: async ({ data }: any) => {
        const row = {
          id: `d${++seq}`,
          settled: false,
          settledAt: null,
          note: null,
          ...data,
        };
        debts.push(row);
        return row;
      },
      findFirst: async ({ where }: any) =>
        debts.find((d) => d.id === where.id && d.userId === where.userId) ??
        null,
      update: async ({ where, data }: any) => {
        const row = debts.find((d) => d.id === where.id);
        if (!row) throw new Error('not found');
        Object.assign(row, data);
        return row;
      },
      delete: async ({ where }: any) => {
        const i = debts.findIndex((d) => d.id === where.id);
        if (i < 0) throw new Error('not found');
        debts.splice(i, 1);
        return { deleted: true };
      },
    },
  };
}

describe('CashFlowDebtService', () => {
  it('summarizes yet-to-give and yet-to-receive ignoring settled entries', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowDebtService(prisma as any);

    await svc.create('u1', {
      direction: 'GIVE',
      person: 'Bank A',
      amount: 5000,
      date: '2026-08-01',
    });
    await svc.create('u1', {
      direction: 'RECEIVE',
      person: 'Amit',
      amount: 2000,
      date: '2026-08-02',
    });
    const third = await svc.create('u1', {
      direction: 'RECEIVE',
      person: 'Priya',
      amount: 700,
      date: '2026-08-03',
    });
    await svc.update('u1', third.id, { settled: true });

    const summary = await svc.getSummary('u1');
    expect(summary).toEqual({ yetToGive: 5000, yetToReceive: 2000 });
  });

  it('keeps ledger entries across month boundaries (no reset)', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowDebtService(prisma as any);

    await svc.create('u1', {
      direction: 'RECEIVE',
      person: 'Amit',
      amount: 1000,
      date: '2026-07-15',
    });

    // A month rollover never touches the debt table — entries persist.
    const all = await svc.findAll('u1');
    expect(all).toHaveLength(1);
    expect(all[0].settled).toBe(false);
  });

  it('marks settled with a timestamp and can reopen', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowDebtService(prisma as any);
    const d = await svc.create('u1', {
      direction: 'GIVE',
      person: 'X',
      amount: 300,
      date: '2026-08-01',
    });

    const settled = await svc.update('u1', d.id, { settled: true });
    expect(settled.settled).toBe(true);
    expect(settled.settledAt).toBeDefined();

    const reopened = await svc.update('u1', d.id, { settled: false });
    expect(reopened.settled).toBe(false);
    expect(reopened.settledAt).toBeNull();
  });

  it('enforces ownership on update and delete', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowDebtService(prisma as any);
    const d = await svc.create('u1', {
      direction: 'GIVE',
      person: 'X',
      amount: 300,
      date: '2026-08-01',
    });

    await expect(svc.update('u2', d.id, { amount: 1 })).rejects.toThrow(
      NotFoundException,
    );
    await expect(svc.remove('u2', d.id)).rejects.toThrow(NotFoundException);
  });

  it('serializes dates as YYYY-MM-DD strings', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowDebtService(prisma as any);
    const d = await svc.create('u1', {
      direction: 'RECEIVE',
      person: 'Amit',
      amount: 100,
      date: '2026-08-05',
    });
    expect(d.date).toBe('2026-08-05');
  });

  it('correctly parses Decimal objects in aggregates and serialization', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowDebtService(prisma as any);

    prisma.debts.push({
      id: 'd1',
      userId: 'u1',
      direction: 'GIVE',
      person: 'Bank',
      amount: '1250.75' as any,
      settled: false,
      settledAt: null,
      date: new Date('2026-08-01'),
      createdAt: new Date(),
    });

    const summary = await svc.getSummary('u1');
    expect(typeof summary.yetToGive).toBe('number');
    expect(summary.yetToGive).toBe(1250.75);

    const all = await svc.findAll('u1');
    expect(typeof all[0].amount).toBe('number');
    expect(all[0].amount).toBe(1250.75);
  });
});
