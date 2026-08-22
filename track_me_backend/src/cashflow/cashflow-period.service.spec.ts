import { NotFoundException, BadRequestException } from '@nestjs/common';
import { CashFlowPeriodService } from './cashflow-period.service';

/**
 * Minimal Prisma mock: in-memory store keyed like the real unique constraints.
 * Only the operations the service actually uses are modelled.
 */
function makePrismaMock(now = new Date(2026, 7, 15)) {
  let seq = 0;
  const periods: any[] = [];
  const txns: any[] = [];

  const mkPeriod = (p: Partial<any> & { userId: string; month: number; year: number }) => {
    const row = {
      id: `p${++seq}`,
      openingBank: 0,
      openingCash: 0,
      openingCreditCard: 0,
      openingDebt: 0,
      createdAt: now,
      ...p,
    };
    periods.push(row);
    return row;
  };

  const sumTxns = (periodId: string) =>
    txns
      .filter((t) => t.periodId === periodId)
      .reduce((s, t) => s + (t.kind === 'INCOME' ? t.amount : -t.amount), 0);

  return {
    periods,
    txns,
    mkPeriod,
    cashFlowPeriod: {
      findFirst: async ({ where }: any) => {
        if (where.id && where.userId) {
          return periods.find((p) => p.id === where.id && p.userId === where.userId) ?? null;
        }
        if (where.id !== undefined && where.userId === undefined) {
          return periods.find((p) => p.id === where.id) ?? null;
        }
        // latest-period query shape: { where: { userId }, orderBy: year desc, month desc }
        return (
          periods
            .filter((p) => p.userId === where.userId)
            .sort((a, b) => b.year - a.year || b.month - a.month)[0] ?? null
        );
      },
      findMany: async ({ where, orderBy }: any) => {
        const rows = periods.filter((p) => p.userId === where.userId);
        return rows.sort((a, b) =>
          orderBy?.[0]?.year === 'asc' ? a.year - b.year || a.month - b.month : b.year - a.year || b.month - a.month,
        );
      },
      create: async ({ data }: any) => {
        if (periods.some((p) => p.userId === data.userId && p.month === data.month && p.year === data.year)) {
          throw new Error('Unique constraint failed');
        }
        return mkPeriod(data);
      },
      update: async ({ where, data }: any) => {
        const row = periods.find((p) => p.id === where.id);
        if (!row) throw new Error('not found');
        Object.assign(row, data);
        return row;
      },
      upsert: async ({ where, create }: any) => {
        const key = where.userId_month_year;
        const existing = periods.find(
          (p) => p.userId === key.userId && p.month === key.month && p.year === key.year,
        );
        if (existing) return existing;
        return mkPeriod({ userId: key.userId, ...create });
      },
    },
    cashFlowTransaction: {
      findFirst: async ({ where }: any) => {
        const txn = txns.find((t) => t.id === where.id);
        if (!txn) return null;
        if (where.period && where.period.userId) {
          const owner = periods.find((p) => p.id === txn.periodId);
          if (!owner || owner.userId !== where.period.userId) return null;
        }
        return txn;
      },
      findMany: async ({ where, select }: any) => {
        const rows = txns
          .filter((t) => (where.periodId ? t.periodId === where.periodId : true))
          .map((t) => (select ? ((t as any).__picked = true, t) : t));
        return rows;
      },
      create: async ({ data }: any) => {
        const row = { id: `t${++seq}`, createdAt: now, note: null, ...data };
        txns.push(row);
        return row;
      },
      delete: async ({ where }: any) => {
        const i = txns.findIndex((t) => t.id === where.id);
        if (i < 0) throw new Error('not found');
        txns.splice(i, 1);
        return { deleted: true };
      },
      deleteMany: async () => undefined,
    },
  };
}

const FIXED_AUG_2026 = new Date(2026, 7, 15);

describe('CashFlowPeriodService — month rollover & carry-forward', () => {
  it('auto-opens an all-zero current period when none exists', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowPeriodService(prisma as any, () => FIXED_AUG_2026);

    const current = await svc.getCurrentPeriod('u1');
    expect(current.month).toBe(8);
    expect(current.year).toBe(2026);
    expect(current.openingBank).toBe(0);
  });

  it('carries previous closing balances into the new month automatically', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowPeriodService(prisma as any, () => FIXED_AUG_2026);

    const july = prisma.mkPeriod({
      userId: 'u1',
      month: 7,
      year: 2026,
      openingBank: 40000,
    });
    prisma.txns.push(
      { id: 't1', periodId: july.id, kind: 'INCOME', amount: 30000, category: 'E' },
      { id: 't2', periodId: july.id, kind: 'OUTFLOW', amount: 12500.75, category: 'E' },
    );

    const current = await svc.getCurrentPeriod('u1');
    expect(current.month).toBe(8);
    expect(current.year).toBe(2026);
    expect(current.openingBank).toBeCloseTo(57499.25, 2);
  });

  it('opens one bridging period per skipped month so carry-forward stays correct', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowPeriodService(prisma as any, () => FIXED_AUG_2026);

    const may = prisma.mkPeriod({
      userId: 'u1',
      month: 5,
      year: 2026,
      openingBank: 1000,
    });
    prisma.txns.push({
      id: 't1',
      periodId: may.id,
      kind: 'INCOME',
      amount: 500,
      category: 'G',
    });

    await svc.getCurrentPeriod('u1');

    expect(prisma.periods.map((p) => p.month).sort((a, b) => a - b)).toEqual([
      5, 6, 7, 8,
    ]);
    // June opens with May's closing; July with June's closing (no activity).
    const june = prisma.periods.find((p) => p.month === 6)!;
    const july = prisma.periods.find((p) => p.month === 7)!;
    const aug = prisma.periods.find((p) => p.month === 8)!;
    expect(june.openingBank).toBe(1500);
    expect(july.openingBank).toBe(1500);
    expect(aug.openingBank).toBe(1500);
  });

  it('rejects transactions dated outside the current period', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowPeriodService(prisma as any, () => FIXED_AUG_2026);

    await expect(
      svc.createTransaction('u1', {
        kind: 'OUTFLOW',
        category: 'E',
        amount: 100,
        date: '2026-07-20',
      } as any),
    ).rejects.toThrow(BadRequestException);
  });

  it('accepts a transaction dated inside the current period', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowPeriodService(prisma as any, () => FIXED_AUG_2026);

    const txn = await svc.createTransaction('u1', {
      kind: 'INCOME',
      category: 'G',
      amount: 250,
      date: '2026-08-02',
    } as any);
    expect(txn.date).toBe('2026-08-02');
  });

  it('refuses balance edits on past periods but allows the current one', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowPeriodService(prisma as any, () => FIXED_AUG_2026);

    const old = prisma.mkPeriod({ userId: 'u1', month: 6, year: 2026 });

    await expect(
      svc.updateOpeningBalances('u1', old.id, { openingBank: 1 }),
    ).rejects.toThrow(BadRequestException);

    const current = await svc.getCurrentPeriod('u1');
    const updated = await svc.updateOpeningBalances('u1', current.id, {
      openingBank: 777,
    });
    expect(updated.openingBank).toBe(777);
  });

  it('throws NotFound when deleting another user transaction', async () => {
    const prisma = makePrismaMock();
    const svc = new CashFlowPeriodService(prisma as any, () => FIXED_AUG_2026);
    prisma.txns.push({
      id: 'tx',
      periodId: 'p-other-user',
      kind: 'INCOME',
      amount: 10,
      category: 'E',
    });
    await expect(svc.deleteTransaction('u1', 'tx')).rejects.toThrow(
      NotFoundException,
    );
  });
});
