import {
  Controller, Get, Post, Patch, Delete, Body, Param, Request, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CashFlowPeriodService } from './cashflow-period.service';
import { CashFlowDebtService } from './cashflow-debt.service';
import { CreatePeriodDto, UpdateBalancesDto } from './dto/cashflow-period.dto';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import {
  CreateCashFlowDebtDto,
  UpdateCashFlowDebtDto,
} from './dto/cashflow-debt.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Cash Flow')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('cashflow')
export class CashFlowController {
  constructor(
    private readonly periodService: CashFlowPeriodService,
    private readonly debtService: CashFlowDebtService,
  ) {}

  // ── Periods ────────────────────────────────────────────────────────────────

  @Get('periods')
  @ApiOperation({ summary: 'List all cash flow periods (opens the current month on demand)' })
  listPeriods(@Request() req: any) {
    return this.periodService.listPeriods(req.user.id);
  }

  @Get('periods/current')
  @ApiOperation({ summary: 'Current month period with computed totals and closing balances' })
  getCurrentPeriod(@Request() req: any) {
    return this.periodService.getCurrentPeriod(req.user.id);
  }

  @Post('periods')
  @ApiOperation({ summary: 'First-month setup — create the initial period with opening balances' })
  createFirstPeriod(@Request() req: any, @Body() dto: CreatePeriodDto) {
    return this.periodService.createFirstPeriod(req.user.id, dto);
  }

  @Patch('periods/:id/balances')
  @ApiOperation({ summary: 'Edit the CURRENT period opening balances (past periods are read-only)' })
  updateBalances(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateBalancesDto,
  ) {
    return this.periodService.updateOpeningBalances(req.user.id, id, dto);
  }

  // ── Transactions ───────────────────────────────────────────────────────

  @Get('transactions')
  @ApiOperation({ summary: 'All transactions of a period' })
  listTransactions(@Request() req: any) {
    const periodId = new URLSearchParams(req.query?.periodId ? { periodId: String(req.query.periodId) } : {}).get('periodId');
    if (!periodId) {
      return this.periodService.listTransactions(req.user.id, '');
    }
    return this.periodService.listTransactions(req.user.id, periodId);
  }

  @Post('transactions')
  @ApiOperation({ summary: 'Add an income or outflow entry to the current period' })
  createTransaction(@Request() req: any, @Body() dto: CreateTransactionDto) {
    return this.periodService.createTransaction(req.user.id, dto);
  }

  @Delete('transactions/:id')
  @ApiOperation({ summary: 'Delete a transaction entry' })
  deleteTransaction(@Request() req: any, @Param('id') id: string) {
    return this.periodService.deleteTransaction(req.user.id, id);
  }

  // ── Debt Ledger ────────────────────────────────────────────────────────

  @Get('debts')
  @ApiOperation({ summary: 'Full give/receive debt ledger (not reset monthly)' })
  listDebts(@Request() req: any) {
    return this.debtService.findAll(req.user.id);
  }

  @Get('debts/summary')
  @ApiOperation({ summary: 'Yet-to-Receive / Yet-to-Give totals for the dashboard tiles' })
  getDebtSummary(@Request() req: any) {
    return this.debtService.getSummary(req.user.id);
  }

  @Post('debts')
  @ApiOperation({ summary: 'Add a ledger entry (who owes whom)' })
  createDebt(@Request() req: any, @Body() dto: CreateCashFlowDebtDto) {
    return this.debtService.create(req.user.id, dto);
  }

  @Patch('debts/:id')
  @ApiOperation({ summary: 'Edit or settle a ledger entry' })
  updateDebt(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateCashFlowDebtDto,
  ) {
    return this.debtService.update(req.user.id, id, dto);
  }

  @Delete('debts/:id')
  @ApiOperation({ summary: 'Delete a ledger entry' })
  removeDebt(@Request() req: any, @Param('id') id: string) {
    return this.debtService.remove(req.user.id, id);
  }
}
