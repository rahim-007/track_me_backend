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
      expect(r.closingCash).toBe(500);
      expect(r.closingCreditCard).toBe(-200);
      expect(r.totalIncome).toBe(0);
      expect(r.totalOutflow).toBe(0);
      expect(r.netCashFlow).toBe(0);
    });

    // ─── Backward compatibility ───────────────────────────────────────────────

    it('null account INCOME posts to Bank (legacy compat)', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'INCOME', amount: 250, account: null },
      ]);
      expect(r.closingBank).toBe(1250);
      expect(r.closingCash).toBe(500); // unchanged
    });

    it('null account OUTFLOW deducts from Bank (legacy compat)', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'OUTFLOW', amount: 100, account: null },
      ]);
      expect(r.closingBank).toBe(900);
      expect(r.closingCash).toBe(500); // unchanged
    });

    it('undefined account OUTFLOW deducts from Bank', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'OUTFLOW', amount: 50 }, // no account property
      ]);
      expect(r.closingBank).toBe(950);
    });

    // ─── BANK account ────────────────────────────────────────────────────────

    it('INCOME to BANK increases closingBank, leaves Cash unchanged', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'INCOME', amount: 5000, account: 'BANK' },
      ]);
      expect(r.closingBank).toBe(6000);
      expect(r.closingCash).toBe(500);
      expect(r.closingCreditCard).toBe(-200);
    });

    it('OUTFLOW from BANK decreases closingBank, leaves Cash unchanged', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'OUTFLOW', amount: 500, account: 'BANK' },
      ]);
      expect(r.closingBank).toBe(500);
      expect(r.closingCash).toBe(500);
      expect(r.closingCreditCard).toBe(-200);
    });

    // ─── CASH account ─────────────────────────────────────────────────────────

    it('INCOME to CASH increases closingCash, leaves Bank unchanged', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'INCOME', amount: 3000, account: 'CASH' },
      ]);
      expect(r.closingBank).toBe(1000); // unchanged
      expect(r.closingCash).toBe(3500);
      expect(r.closingCreditCard).toBe(-200);
    });

    it('OUTFLOW from CASH decreases closingCash, leaves Bank unchanged', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'OUTFLOW', amount: 200, account: 'CASH' },
      ]);
      expect(r.closingBank).toBe(1000); // unchanged
      expect(r.closingCash).toBe(300);
      expect(r.closingCreditCard).toBe(-200);
    });

    // ─── CREDIT_CARD account ──────────────────────────────────────────────────

    it('OUTFLOW from CREDIT_CARD increases closingCreditCard (more debt), Bank and Cash unchanged', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'OUTFLOW', amount: 1000, account: 'CREDIT_CARD' },
      ]);
      expect(r.closingBank).toBe(1000); // unchanged
      expect(r.closingCash).toBe(500); // unchanged
      expect(r.closingCreditCard).toBe(800); // -200 + 1000 = 800 (more owed)
    });

    // ─── Mixed transactions ───────────────────────────────────────────────────

    it('mixed accounts update each pocket independently', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'INCOME', amount: 5000, account: 'BANK' }, // +5000 bank
        { kind: 'OUTFLOW', amount: 1000, account: 'CASH' }, // -1000 cash
        { kind: 'OUTFLOW', amount: 2000, account: 'CREDIT_CARD' }, // +2000 CC debt
        { kind: 'OUTFLOW', amount: 1000, account: 'BANK' }, // -1000 bank
      ]);
      expect(r.closingBank).toBe(5000); // 1000 + 5000 - 1000
      expect(r.closingCash).toBe(-500); // 500 - 1000
      expect(r.closingCreditCard).toBe(1800); // -200 + 2000
      expect(r.totalIncome).toBe(5000);
      expect(r.totalOutflow).toBe(4000);
      expect(r.netCashFlow).toBe(1000);
    });

    it('carries forward the exact closing balance as the next opening (Bank)', () => {
      // The core carry-forward invariant for Bank.
      const julyTxns = [
        { kind: 'INCOME', amount: 30000, account: 'BANK' },
        { kind: 'OUTFLOW', amount: 12500.75, account: 'BANK' },
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
        { kind: 'INCOME', amount: 0.1, account: 'BANK' },
        { kind: 'INCOME', amount: 0.2, account: 'BANK' },
      ]);
      expect(r.totalIncome).toBe(0.3);
      expect(r.closingBank).toBe(0.3);
    });

    it('ignores unknown kinds in totals', () => {
      const r = computeClosingBalances(opening, [
        { kind: 'WEIRD', amount: 999, account: 'BANK' },
      ]);
      expect(r.closingBank).toBe(1000);
      expect(r.closingCash).toBe(500);
    });

    // ─── Starting balance preservation ────────────────────────────────────────

    it('opening balances are never modified, only closing changes', () => {
      // This is the core invariant: starting balances remain fixed.
      const openingSnapshot = { ...opening };
      computeClosingBalances(opening, [
        { kind: 'INCOME', amount: 5000, account: 'BANK' },
        { kind: 'OUTFLOW', amount: 500, account: 'CASH' },
        { kind: 'OUTFLOW', amount: 1000, account: 'CREDIT_CARD' },
      ]);
      // The `opening` object must be unchanged.
      expect(opening.openingBank).toBe(openingSnapshot.openingBank);
      expect(opening.openingCash).toBe(openingSnapshot.openingCash);
      expect(opening.openingCreditCard).toBe(openingSnapshot.openingCreditCard);
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
