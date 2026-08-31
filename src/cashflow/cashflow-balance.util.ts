// ─────────────────────────────────────────────────────────────────────────────
// Cash Flow Tracker — pure balance math.
//
// Closing balances are always COMPUTED, never stored. Each account is tracked
// independently based on the transaction's `account` field:
//
//   closingBank       = openingBank
//                       + INCOME  where account=BANK (or null — legacy compat)
//                       - OUTFLOW where account=BANK (or null — legacy compat)
//
//   closingCash       = openingCash
//                       + INCOME  where account=CASH
//                       - OUTFLOW where account=CASH
//
//   closingCreditCard = openingCreditCard
//                       + OUTFLOW where account=CREDIT_CARD   (debt increases)
//                       - OUTFLOW (category D Debt Repayment) where account=BANK|CASH (debt decreases)
//
//   closingDebt       = openingDebt   (ledger tracked separately in CashFlowDebtService)
//
// A new month's opening balances are simply the previous month's closing
// balances — the caller never re-derives them from scratch.
//
// BACKWARD COMPATIBILITY: Transactions with account=null are treated as BANK.
// ─────────────────────────────────────────────────────────────────────────────

export interface OpeningBalances {
  openingBank: number;
  openingCash: number;
  openingCreditCard: number;
  openingDebt: number;
}

export type TxnLike = {
  kind: string;
  category?: string;
  amount: number;
  /** Which account pocket this entry affects. null = BANK (legacy compat). */
  account?: string | null;
};

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
 * Resolve the effective account for a transaction.
 * null / undefined → BANK (backward compatibility with pre-migration rows).
 */
function effectiveAccount(account: string | null | undefined): string {
  return account ?? 'BANK';
}

/**
 * Compute closing balances for one period from its opening balances and the
 * period's transactions.
 *
 * Each account (Bank, Cash, CreditCard) is computed independently:
 *   - INCOME  to BANK  → increases closingBank
 *   - OUTFLOW from BANK → decreases closingBank
 *   - INCOME  to CASH  → increases closingCash
 *   - OUTFLOW from CASH → decreases closingCash
 *   - OUTFLOW from CREDIT_CARD → increases closingCreditCard (more debt owed)
 *   - OUTFLOW category 'D' (Debt Repayment) from BANK/CASH → decreases closingCreditCard (less debt owed)
 *
 * The starting balances (openingBank/Cash/CreditCard) are NEVER modified;
 * only the closing values change.
 */
export function computeClosingBalances(
  opening: OpeningBalances,
  transactions: TxnLike[],
): ClosingBalances {
  let bankDelta = 0;
  let cashDelta = 0;
  let creditCardDelta = 0;
  let totalIncome = 0;
  let totalOutflow = 0;

  for (const t of transactions) {
    const acct = effectiveAccount(t.account);
    if (t.kind === 'INCOME') {
      totalIncome += t.amount;
      if (acct === 'CASH') {
        cashDelta += t.amount;
      } else {
        // BANK (default) or any other value
        bankDelta += t.amount;
      }
    } else if (t.kind === 'OUTFLOW') {
      totalOutflow += t.amount;
      if (acct === 'CASH') {
        cashDelta -= t.amount;
      } else if (acct === 'CREDIT_CARD') {
        creditCardDelta += t.amount; // debt increases
      } else {
        // BANK (default) or any other value
        bankDelta -= t.amount;
      }

      // Debt Repayment (category 'D') paid from Bank or Cash reduces Credit Card debt owed
      if (t.category === 'D' && acct !== 'CREDIT_CARD') {
        creditCardDelta -= t.amount;
      }
    }
  }

  const netCashFlow = round2(totalIncome - totalOutflow);

  return {
    closingBank: round2(opening.openingBank + bankDelta),
    closingCash: round2(opening.openingCash + cashDelta),
    closingCreditCard: round2(opening.openingCreditCard + creditCardDelta),
    closingDebt: round2(opening.openingDebt),
    totalIncome: round2(totalIncome),
    totalOutflow: round2(totalOutflow),
    netCashFlow,
  };
}

/** Next calendar month after (month 1-12, year). */
export function nextMonth(
  month: number,
  year: number,
): { month: number; year: number } {
  return month === 12
    ? { month: 1, year: year + 1 }
    : { month: month + 1, year };
}

/** Previous calendar month before (month 1-12, year). */
export function prevMonth(
  month: number,
  year: number,
): { month: number; year: number } {
  return month === 1
    ? { month: 12, year: year - 1 }
    : { month: month - 1, year };
}

/** Calendar month/year of a Date (server-local clock). */
export function monthYearOf(date: Date): { month: number; year: number } {
  return { month: date.getMonth() + 1, year: date.getFullYear() };
}
