import {
  IsNumber, IsOptional, IsInt, Min, Max
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateBudgetDto {
  @ApiProperty({ example: 20000, description: 'Monthly income amount' })
  @IsNumber()
  @Min(0)
  monthlyIncome: number;

  @ApiProperty({ example: 5000, description: 'Monthly savings target' })
  @IsNumber()
  @Min(0)
  savingsTarget: number;

  @ApiPropertyOptional({ example: 8, description: 'Month (1-12), defaults to current month' })
  @IsInt()
  @Min(1)
  @Max(12)
  @IsOptional()
  month?: number;

  @ApiPropertyOptional({ example: 2026, description: 'Year, defaults to current year' })
  @IsInt()
  @IsOptional()
  year?: number;
}
