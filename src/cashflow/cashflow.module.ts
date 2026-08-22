import { Module } from '@nestjs/common';
import { CashFlowController } from './cashflow.controller';
import { CashFlowPeriodService } from './cashflow-period.service';
import { CashFlowDebtService } from './cashflow-debt.service';

@Module({
  controllers: [CashFlowController],
  providers: [CashFlowPeriodService, CashFlowDebtService],
})
export class CashFlowModule {}
