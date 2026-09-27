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
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "isInterval" BOOLEAN NOT NULL DEFAULT false',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "intervalMinutes" INTEGER',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "windowStartTime" TEXT',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "windowEndTime" TEXT',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "targetValue" DOUBLE PRECISION',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "unit" TEXT',
      'ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "rollingInterval" BOOLEAN NOT NULL DEFAULT false',
      'ALTER TABLE "habit_logs" ADD COLUMN IF NOT EXISTS "currentValue" DOUBLE PRECISION NOT NULL DEFAULT 0',
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
