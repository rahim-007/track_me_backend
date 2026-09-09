import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsDateString,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateTransactionDto {
  @ApiPropertyOptional({
    enum: ['INCOME', 'OUTFLOW'],
    description: 'Direction of the entry',
  })
  @IsOptional()
  @IsEnum(['INCOME', 'OUTFLOW'])
  kind?: 'INCOME' | 'OUTFLOW';

  @ApiPropertyOptional({
    enum: ['E', 'S', 'B', 'I', 'G', 'D', 'DO'],
    description:
      'Category letter. Income: E employee salary / S self-employed / B business / I investor / G gift. Outflow: E expense / S savings / D debt repayment / I investing / DO donation.',
  })
  @IsOptional()
  @IsEnum(['E', 'S', 'B', 'I', 'G', 'D', 'DO'])
  category?: 'E' | 'S' | 'B' | 'I' | 'G' | 'D' | 'DO';

  @ApiPropertyOptional({ example: 1250.5 })
  @IsOptional()
  @IsNumber()
  @Min(0.01)
  amount?: number;

  @ApiPropertyOptional({ example: 'Groceries at the corner store' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @ApiPropertyOptional({
    example: '2026-08-22',
    description: 'Date in YYYY-MM-DD format',
  })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional({
    enum: ['BANK', 'CASH', 'CREDIT_CARD'],
    description:
      'Account pocket this entry posts to (INCOME) or from (OUTFLOW). ' +
      'INCOME + CREDIT_CARD is not allowed.',
  })
  @IsOptional()
  @IsEnum(['BANK', 'CASH', 'CREDIT_CARD'])
  account?: 'BANK' | 'CASH' | 'CREDIT_CARD';
}
