import {
  Controller, Get, Post, Patch, Delete,
  Body, Param, Query, Request, UseGuards
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ExpensesService } from './expenses.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Expenses')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('expenses')
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) {}

  // ─── Budget ──────────────────────────────────────────────────────────────────

  @Post('budget')
  @ApiOperation({ summary: 'Create or update monthly budget' })
  upsertBudget(@Request() req: any, @Body() dto: CreateBudgetDto) {
    return this.expensesService.upsertBudget(req.user.id, dto);
  }

  @Get('budget')
  @ApiOperation({ summary: 'Get budget for a specific month' })
  @ApiQuery({ name: 'month', required: false, type: Number })
  @ApiQuery({ name: 'year', required: false, type: Number })
  getBudget(
    @Request() req: any,
    @Query('month') month?: number,
    @Query('year') year?: number,
  ) {
    const now = new Date();
    const m = month ?? now.getMonth() + 1;
    const y = year ?? now.getFullYear();
    return this.expensesService.getBudget(req.user.id, m, y);
  }

  @Get('budget/current')
  @ApiOperation({ summary: 'Get current month budget' })
  getCurrentBudget(@Request() req: any) {
    return this.expensesService.getCurrentBudget(req.user.id);
  }

  // ─── Dashboard ───────────────────────────────────────────────────────────────

  @Get('dashboard')
  @ApiOperation({ summary: 'Get expense dashboard data' })
  @ApiQuery({ name: 'today', required: false, type: String })
  @ApiQuery({ name: 'filter', required: false, type: String })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  getDashboard(
    @Request() req: any,
    @Query('today') today?: string,
    @Query('filter') filter?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.expensesService.getDashboard(req.user.id, today, filter, startDate, endDate);
  }

  // ─── Analytics ───────────────────────────────────────────────────────────────

  @Get('analytics')
  @ApiOperation({ summary: 'Get expense analytics' })
  @ApiQuery({ name: 'period', required: false, type: String })
  @ApiQuery({ name: 'today', required: false, type: String })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  getAnalytics(
    @Request() req: any,
    @Query('period') period?: string,
    @Query('today') today?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.expensesService.getAnalytics(req.user.id, period ?? 'thisMonth', today, startDate, endDate);
  }

  // ─── Expenses CRUD ───────────────────────────────────────────────────────────

  @Get()
  @ApiOperation({ summary: 'Get all expenses (optionally scoped to a month)' })
  @ApiQuery({ name: 'month', required: false, type: Number })
  @ApiQuery({ name: 'year', required: false, type: Number })
  getExpenses(
    @Request() req: any,
    @Query('month') month?: number,
    @Query('year') year?: number,
  ) {
    return this.expensesService.getExpenses(
      req.user.id,
      month ? Number(month) : undefined,
      year ? Number(year) : undefined,
    );
  }

  @Post()
  @ApiOperation({ summary: 'Add a new expense' })
  createExpense(@Request() req: any, @Body() dto: CreateExpenseDto) {
    return this.expensesService.createExpense(req.user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an expense' })
  updateExpense(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateExpenseDto,
  ) {
    return this.expensesService.updateExpense(req.user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an expense' })
  deleteExpense(@Request() req: any, @Param('id') id: string) {
    return this.expensesService.deleteExpense(req.user.id, id);
  }
}
