import {
  computeClosingBalances,
  nextMonth,
  prevMonth,
  monthYearOf,
  round2,
} from './cashflow-balance.util';

describe('cashflow-balance.util', () => {
  const opening = {
    openingBank: 1000,
    openingCash: 500,
    openingCreditCard: -200,
    openingDebt: 0,
  };

  describe('computeClosingBalances', () => {
    it('returns opening balances unchanged with no transactions', () => {
      const r = computeClosingBalances(opening, []);
      expect(r.closingBank).toBe(1000);
      expect(r.totalIncome).toBe(0);
      expect(r.totalOutflow).toBe(0);
      expect(r.netCashFlow).toBe(0);
    });

    it('adds income and subtracts outflow from bank', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'INCOME', amount: 250.5 },
        { kind: 'OUTFLOW', amount: 100 },
        { kind: 'OUTFLOW', amount: 50.25 },
      ]);
      expect(r.totalIncome).toBe(250.5);
      expect(r.totalOutflow).toBe(150.25);
      expect(r.netCashFlow).toBe(100.25);
      expect(r.closingBank).toBe(1100.25);
    });

    it('carries forward the exact closing balance as the next opening', () => {
      // The core carry-forward invariant: next month's opening equals this
      // month's closing, computed purely from transactions.
      const julyTxns = [
        { kind: 'INCOME', amount: 30000 },
        { kind: 'OUTFLOW', amount: 12500.75 },
      ];
      const july = computeClosingBalances(
        { ...opening, openingBank: 40000 },
        julyTxns,
      );
      const august = computeClosingBalances(
        { ...opening, openingBank: july.closingBank },
        [],
      );
      expect(august.closingBank).toBe(july.closingBank);
      expect(august.closingBank).toBeCloseTo(57499.25, 2); // 40000+30000-12500.75
    });

    it('rounds to 2 decimals to avoid float drift', () => {
      const r = computeClosingBalances({ ...opening, openingBank: 0 }, [
        { kind: 'INCOME', amount: 0.1 },
        { kind: 'INCOME', amount: 0.2 },
      ]);
      expect(r.totalIncome).toBe(0.3);
      expect(r.closingBank).toBe(0.3);
    });

    it('ignores unknown kinds in totals', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'WEIRD' as any, amount: 999 },
      ]);
      expect(r.closingBank).toBe(1000);
    });
  });

  describe('month arithmetic', () => {
    it('rolls December to January of next year', () => {
      expect(nextMonth(12, 2026)).toEqual({ month: 1, year: 2027 });
      expect(prevMonth(1, 2026)).toEqual({ month: 12, year: 2025 });
    });

    it('steps normal months', () => {
      expect(nextMonth(8, 2026)).toEqual({ month: 9, year: 2026 });
      expect(prevMonth(3, 2026)).toEqual({ month: 2, year: 2026 });
    });

    it('derives month/year from a date', () => {
      expect(monthYearOf(new Date(2026, 11, 31))).toEqual({
        month: 12,
        year: 2026,
      });
      expect(monthYearOf(new Date(2027, 0, 1))).toEqual({
        month: 1,
        year: 2027,
      });
    });
  });

  it('round2 keeps paise precision on binary-exact halves', () => {
    // 10.125 is exactly representable in binary floating point.
    expect(round2(10.125)).toBe(10.13);
    expect(round2(0.1 + 0.2)).toBe(0.3);
  });
});
