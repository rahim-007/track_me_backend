import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsDateString,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateTransactionDto {
  @ApiProperty({
    enum: ['INCOME', 'OUTFLOW'],
    description: 'Direction of the entry',
  })
  @IsEnum(['INCOME', 'OUTFLOW'])
  kind: 'INCOME' | 'OUTFLOW';

  @ApiProperty({
    enum: ['E', 'S', 'B', 'I', 'G', 'D'],
    description:
      'Category letter. Income: E employee salary / S self-employed / B business / I investor / G gift. Outflow: E expense / S savings / D debt repayment / I investing.',
  })
  @IsEnum(['E', 'S', 'B', 'I', 'G'])
  category: 'E' | 'S' | 'B' | 'I' | 'G';

  @ApiProperty({ example: 1250.5 })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiPropertyOptional({ example: 'Groceries at the corner store' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @ApiProperty({
    example: '2026-08-22',
    description: 'Date in YYYY-MM-DD format; must fall inside the period',
  })
  @IsDateString()
  date: string;
}
