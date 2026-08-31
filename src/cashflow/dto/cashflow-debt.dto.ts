import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateCashFlowDebtDto {
  @ApiProperty({
    enum: ['GIVE', 'RECEIVE'],
    description: '"GIVE" = I owe them; "RECEIVE" = they owe me',
  })
  @IsEnum(['GIVE', 'RECEIVE'])
  direction: 'GIVE' | 'RECEIVE';

  @ApiProperty({ example: 'Amit' })
  @IsString()
  @MaxLength(120)
  person: string;

  @ApiProperty({ example: 5000 })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiPropertyOptional({ example: 'Loan for laptop repair' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @ApiProperty({
    example: '2026-08-22',
    description: 'Date in YYYY-MM-DD format',
  })
  @IsDateString()
  date: string;
}

export class UpdateCashFlowDebtDto {
  @ApiPropertyOptional({ enum: ['GIVE', 'RECEIVE'] })
  @IsOptional()
  @IsEnum(['GIVE', 'RECEIVE'])
  direction?: 'GIVE' | 'RECEIVE';

  @ApiPropertyOptional({ example: 'Amit Sharma' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  person?: string;

  @ApiPropertyOptional({ example: 4500 })
  @IsOptional()
  @IsNumber()
  @Min(0.01)
  amount?: number;

  @ApiPropertyOptional({ example: 'Partially repaid in cash' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @ApiPropertyOptional({ example: '2026-08-01' })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  settled?: boolean;
}
