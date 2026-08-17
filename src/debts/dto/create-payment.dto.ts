import {
  IsString, IsNumber, IsOptional, IsDateString, MaxLength, Min,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePaymentDto {
  @ApiProperty({ example: 5000, description: 'Payment amount' })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiProperty({ required: false, example: '2026-08-17', description: 'Payment date in YYYY-MM-DD format (defaults to now)' })
  @IsOptional()
  @IsDateString()
  paymentDate?: string;

  @ApiProperty({ required: false, description: 'Optional note for this payment' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}
