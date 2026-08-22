import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { HabitsModule } from './habits/habits.module';
import { HabitLogsModule } from './habit-logs/habit-logs.module';
import { GoalsModule } from './goals/goals.module';
import { AiModule } from './ai/ai.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PrismaModule } from './prisma/prisma.module';
import { MissedReasonsModule } from './missed-reasons/missed-reasons.module';
import { ExpensesModule } from './expenses/expenses.module';
import { ExtraIncomeModule } from './extra-income/extra-income.module';
import { DebtsModule } from './debts/debts.module';

@Module({
  imports: [
    // Config
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Rate Limiting
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),

    // Database
    PrismaModule,

    // Feature Modules
    AuthModule,
    UsersModule,
    HabitsModule,
    HabitLogsModule,
    GoalsModule,
    AiModule,
    NotificationsModule,
    MissedReasonsModule,
    ExpensesModule,
    ExtraIncomeModule,
    DebtsModule,
  ],
  providers: [
    // Global rate limiting — the ThrottlerModule config did nothing before
    // because no guard was ever registered to enforce it.
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
