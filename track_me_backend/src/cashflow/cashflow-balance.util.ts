// ─────────────────────────────────────────────────────────────────────────────
// Cash Flow Tracker — pure balance math.
//
// Closing balances are always COMPUTED, never stored:
//   closingBank       = openingBank + totalIncome - totalOutflow
//   closingCash       = openingCash            (v1: all entries post to bank)
//   closingCreditCard = openingCreditCard      (v1)
//   closingDebt       = openingDebt            (ledger is tracked separately;
//                                               see CashFlowDebtService summary)
//
// A new month's opening balances are simply the previous month's closing
// balances — the caller never re-derives them from scratch.
// ─────────────────────────────────────────────────────────────────────────────

export interface OpeningBalances {
  openingBank: number;
  openingCash: number;
  openingCreditCard: number;
  openingDebt: number;
}

export type TxnLike = { kind: string; amount: number };

export interface ClosingBalances {
  closingBank: number;
  closingCash: number;
  closingCreditCard: number;
  closingDebt: number;
  totalIncome: number;
  totalOutflow: number;
  netCashFlow: number;
}

/** Round to 2 decimals to avoid float drift (₹ paise-level precision). */
export function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

/**
 * Compute closing balances for one period from its opening balances and the
 * period's transactions. Inflow increases bank; outflow decreases it.
 */
export function computeClosingBalances(
  opening: OpeningBalances,
  transactions: TxnLike[],
): ClosingBalances {
  const totalIncome = round2(
    transactions
      .filter((t) => t.kind === 'INCOME')
      .reduce((sum, t) => sum + t.amount, 0),
  );
  const totalOutflow = round2(
    transactions
      .filter((t) => t.kind === 'OUTFLOW')
      .reduce((sum, t) => sum + t.amount, 0),
  );
  const netCashFlow = round2(totalIncome - totalOutflow);

  return {
    closingBank: round2(opening.openingBank + netCashFlow),
    closingCash: round2(opening.openingCash),
    closingCreditCard: round2(opening.openingCreditCard),
    closingDebt: round2(opening.openingDebt),
    totalIncome,
    totalOutflow,
    netCashFlow,
  };
}

/** Next calendar month after (month 1-12, year). */
export function nextMonth(
  month: number,
  year: number,
): { month: number; year: number } {
  return month === 12 ? { month: 1, year: year + 1 } : { month: month + 1, year };
}

/** Previous calendar month before (month 1-12, year). */
export function prevMonth(
  month: number,
  year: number,
): { month: number; year: number } {
  return month === 1 ? { month: 12, year: year - 1 } : { month: month - 1, year };
}

/** Calendar month/year of a Date (server-local clock). */
export function monthYearOf(date: Date): { month: number; year: number } {
  return { month: date.getMonth() + 1, year: date.getFullYear() };
}
