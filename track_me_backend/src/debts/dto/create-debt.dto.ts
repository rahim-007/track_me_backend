import {
  IsString, IsNumber, IsOptional, IsDateString, MaxLength, Min,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateDebtDto {
  @ApiProperty({ example: 'Personal Loan', description: 'Loan/Debt name' })
  @IsString()
  @MaxLength(200)
  name: string;

  @ApiProperty({ example: 50000, description: 'Original borrowed amount' })
  @IsNumber()
  @Min(0.01)
  originalAmount: number;

  @ApiProperty({ required: false, example: 'Bank', description: 'Lender / person name' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  lenderName?: string;

  @ApiProperty({ required: false, example: '2026-12-31', description: 'Due date in YYYY-MM-DD format' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiProperty({ required: false, example: 5000, description: 'Planned installment amount' })
  @IsOptional()
  @IsNumber()
  @Min(0.01)
  installmentAmount?: number;

  @ApiProperty({ required: false, description: 'Free-text description' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}
