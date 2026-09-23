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
    try {
      await this.$executeRawUnsafe(`
        ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "isInterval" BOOLEAN NOT NULL DEFAULT false;
        ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "intervalMinutes" INTEGER;
        ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "windowStartTime" TEXT;
        ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "windowEndTime" TEXT;
        ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "targetValue" DOUBLE PRECISION;
        ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "unit" TEXT;
        ALTER TABLE "habits" ADD COLUMN IF NOT EXISTS "rollingInterval" BOOLEAN NOT NULL DEFAULT false;
        ALTER TABLE "habit_logs" ADD COLUMN IF NOT EXISTS "currentValue" DOUBLE PRECISION NOT NULL DEFAULT 0;
      `);
    } catch (err) {
      console.warn('[PrismaService] Auto-migration check warning:', (err as Error).message);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
