import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    super({
      log:
        process.env.NODE_ENV === 'development'
          ? ['query', 'info', 'warn', 'error']
          : ['warn', 'error'],
    });
  }

  async onModuleInit() {
    await this.$connect();
    const alterStatements = [
      // Habits auto-migration
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "isInterval" BOOLEAN NOT NULL DEFAULT false',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "intervalMinutes" INTEGER',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "windowStartTime" TEXT',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "windowEndTime" TEXT',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "targetValue" DOUBLE PRECISION',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "unit" TEXT',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "rollingInterval" BOOLEAN NOT NULL DEFAULT false',
      'ALTER TABLE "habit_logs" ADD COLUMN IF NOT EXISTS "currentValue" DOUBLE PRECISION NOT NULL DEFAULT 0',

      // Cash Flow Enums
      `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'CashFlowTxnKind') THEN
          CREATE TYPE "CashFlowTxnKind" AS ENUM ('INCOME', 'OUTFLOW');
        END IF;
      END $$;`,
      `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'CashFlowAccount') THEN
          CREATE TYPE "CashFlowAccount" AS ENUM ('BANK', 'CASH', 'CREDIT_CARD');
        END IF;
      END $$;`,
      `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'CashFlowDebtDirection') THEN
          CREATE TYPE "CashFlowDebtDirection" AS ENUM ('GIVE', 'RECEIVE');
        END IF;
      END $$;`,

      // Cash Flow Tables
      `CREATE TABLE IF NOT EXISTS "cashflow_periods" (
        "id" TEXT NOT NULL,
        "userId" TEXT NOT NULL,
        "month" INTEGER NOT NULL,
        "year" INTEGER NOT NULL,
        "openingBank" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "openingCash" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "openingCreditCard" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "openingDebt" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "cashflow_periods_pkey" PRIMARY KEY ("id")
      )`,
      `CREATE TABLE IF NOT EXISTS "cashflow_transactions" (
        "id" TEXT NOT NULL,
        "periodId" TEXT NOT NULL,
        "kind" "CashFlowTxnKind" NOT NULL,
        "category" TEXT NOT NULL,
        "amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "note" TEXT,
        "date" DATE NOT NULL,
        "account" "CashFlowAccount" DEFAULT 'BANK',
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "cashflow_transactions_pkey" PRIMARY KEY ("id")
      )`,
      `CREATE TABLE IF NOT EXISTS "cashflow_debts" (
        "id" TEXT NOT NULL,
        "userId" TEXT NOT NULL,
        "direction" "CashFlowDebtDirection" NOT NULL,
        "person" TEXT NOT NULL,
        "amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
        "note" TEXT,
        "date" DATE NOT NULL,
        "settled" BOOLEAN NOT NULL DEFAULT false,
        "settledAt" TIMESTAMP(3),
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "cashflow_debts_pkey" PRIMARY KEY ("id")
      )`,

      // Cash Flow Column additions & type alignment
      'ALTER TABLE "cashflow_periods" ADD COLUMN IF NOT EXISTS "openingBank" DECIMAL(12,2) NOT NULL DEFAULT 0',
      'ALTER TABLE "cashflow_periods" ADD COLUMN IF NOT EXISTS "openingCash" DECIMAL(12,2) NOT NULL DEFAULT 0',
      'ALTER TABLE "cashflow_periods" ADD COLUMN IF NOT EXISTS "openingCreditCard" DECIMAL(12,2) NOT NULL DEFAULT 0',
      'ALTER TABLE "cashflow_periods" ADD COLUMN IF NOT EXISTS "openingDebt" DECIMAL(12,2) NOT NULL DEFAULT 0',
      'ALTER TABLE "cashflow_periods" ALTER COLUMN "openingBank" TYPE DECIMAL(12,2) USING "openingBank"::numeric',
      'ALTER TABLE "cashflow_periods" ALTER COLUMN "openingCash" TYPE DECIMAL(12,2) USING "openingCash"::numeric',
      'ALTER TABLE "cashflow_periods" ALTER COLUMN "openingCreditCard" TYPE DECIMAL(12,2) USING "openingCreditCard"::numeric',
      'ALTER TABLE "cashflow_periods" ALTER COLUMN "openingDebt" TYPE DECIMAL(12,2) USING "openingDebt"::numeric',
      'ALTER TABLE "cashflow_transactions" ADD COLUMN IF NOT EXISTS "account" "CashFlowAccount" DEFAULT \'BANK\'',
      'ALTER TABLE "cashflow_transactions" ALTER COLUMN "amount" TYPE DECIMAL(12,2) USING "amount"::numeric',
      'ALTER TABLE "cashflow_debts" ALTER COLUMN "amount" TYPE DECIMAL(12,2) USING "amount"::numeric',

      // Cash Flow Indexes & Constraints
      'CREATE UNIQUE INDEX IF NOT EXISTS "cashflow_periods_userId_month_year_key" ON "cashflow_periods"("userId", "month", "year")',
      'CREATE INDEX IF NOT EXISTS "cashflow_periods_userId_idx" ON "cashflow_periods"("userId")',
      'CREATE INDEX IF NOT EXISTS "cashflow_transactions_periodId_idx" ON "cashflow_transactions"("periodId")',
      'CREATE INDEX IF NOT EXISTS "cashflow_transactions_periodId_date_idx" ON "cashflow_transactions"("periodId", "date")',
      'CREATE INDEX IF NOT EXISTS "cashflow_debts_userId_idx" ON "cashflow_debts"("userId")',
      'CREATE INDEX IF NOT EXISTS "cashflow_debts_userId_direction_settled_idx" ON "cashflow_debts"("userId", "direction", "settled")',

      // Foreign Keys
      `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cashflow_periods_userId_fkey') THEN
          ALTER TABLE "cashflow_periods" ADD CONSTRAINT "cashflow_periods_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
      END $$;`,
      `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cashflow_transactions_periodId_fkey') THEN
          ALTER TABLE "cashflow_transactions" ADD CONSTRAINT "cashflow_transactions_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES "cashflow_periods"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
      END $$;`,
      `DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cashflow_debts_userId_fkey') THEN
          ALTER TABLE "cashflow_debts" ADD CONSTRAINT "cashflow_debts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
      END $$;`,
    ];

    for (const sql of alterStatements) {
      try {
        await this.$executeRawUnsafe(sql);
      } catch (err) {
        console.warn(`[PrismaService] Column check note for [${sql}]:`, (err as Error).message);
      }
    }
    console.log('[PrismaService] Auto-migration check completed successfully.');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
