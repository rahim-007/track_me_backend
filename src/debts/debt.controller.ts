import {
  Controller, Get, Post, Patch, Delete, Body, Param, Request, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DebtService } from './debt.service';
import { CreateDebtDto } from './dto/create-debt.dto';
import { UpdateDebtDto } from './dto/update-debt.dto';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Debt / Loan')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('debts')
export class DebtController {
  constructor(private readonly debtService: DebtService) {}

  @Get()
  @ApiOperation({ summary: 'Get all debts for the current user' })
  findAll(@Request() req: any) {
    return this.debtService.findAll(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one debt with its payment history' })
  findOne(@Request() req: any, @Param('id') id: string) {
    return this.debtService.findOne(req.user.id, id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new debt / loan' })
  create(@Request() req: any, @Body() dto: CreateDebtDto) {
    return this.debtService.create(req.user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a debt' })
  update(@Request() req: any, @Param('id') id: string, @Body() dto: UpdateDebtDto) {
    return this.debtService.update(req.user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a debt (and its payment history)' })
  remove(@Request() req: any, @Param('id') id: string) {
    return this.debtService.remove(req.user.id, id);
  }

  @Post(':id/payments')
  @ApiOperation({ summary: 'Record a payment against a debt' })
  recordPayment(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: CreatePaymentDto,
  ) {
    return this.debtService.recordPayment(req.user.id, id, dto);
  }
}
