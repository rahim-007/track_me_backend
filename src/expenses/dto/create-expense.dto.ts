import {
  IsString, IsNumber, IsOptional, IsEnum, IsDateString, MaxLength, Min
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ExpenseCategory, PaymentMethod } from '@prisma/client';

export class CreateExpenseDto {
  @ApiProperty({ example: 'Lunch at cafe' })
  @IsString()
  @MaxLength(200)
  title: string;

  @ApiProperty({ example: 250 })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiPropertyOptional({ enum: ExpenseCategory, default: ExpenseCategory.OTHER })
  @IsEnum(ExpenseCategory)
  @IsOptional()
  category?: ExpenseCategory;

  @ApiPropertyOptional({ enum: PaymentMethod, default: PaymentMethod.CASH })
  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ example: '2026-08-04', description: 'Date in YYYY-MM-DD format' })
  @IsDateString()
  @IsOptional()
  date?: string;

  @ApiPropertyOptional({ example: '14:30', description: 'Time in HH:mm format' })
  @IsString()
  @IsOptional()
  time?: string;

  @ApiPropertyOptional({ example: 'Team lunch' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;
}
