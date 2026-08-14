import {
  IsString, IsNumber, IsDateString, MaxLength, Min
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateExtraIncomeDto {
  @ApiProperty({ example: 'Freelance Work', description: 'Name of the extra income source' })
  @IsString()
  @MaxLength(200)
  title: string;

  @ApiProperty({ example: 5000 })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiProperty({ example: '2026-08-14', description: 'Date in YYYY-MM-DD format' })
  @IsDateString()
  date: string;
}
