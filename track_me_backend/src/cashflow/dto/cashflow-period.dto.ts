import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePeriodDto {
  @ApiProperty({ example: 8, minimum: 1, maximum: 12 })
  @IsInt()
  @Min(1)
  @Max(12)
  month: number;

  @ApiProperty({ example: 2026 })
  @IsInt()
  @Min(2000)
  year: number;

  @ApiProperty({ example: 50000, description: 'Opening bank balance' })
  @IsNumber()
  openingBank: number;

  @ApiProperty({ example: 3000, description: 'Opening cash-in-hand balance' })
  @IsNumber()
  openingCash: number;

  @ApiProperty({ example: -12000, description: 'Opening credit-card balance (use negative for amount owed)' })
  @IsNumber()
  openingCreditCard: number;

  @ApiProperty({
    example: 0,
    description:
      'Opening net debt position. Positive = others owe you more than you owe them.',
  })
  @IsNumber()
  openingDebt: number;
}

export class UpdateBalancesDto {
  @ApiPropertyOptional({ example: 52000 })
  @IsOptional()
  @IsNumber()
  openingBank?: number;

  @ApiPropertyOptional({ example: 2500 })
  @IsOptional()
  @IsNumber()
  openingCash?: number;

  @ApiPropertyOptional({ example: -11000 })
  @IsOptional()
  @IsNumber()
  openingCreditCard?: number;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsNumber()
  openingDebt?: number;
}
