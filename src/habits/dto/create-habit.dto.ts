import {
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
  IsNumber,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateHabitDto {
  @ApiProperty({ example: 'Morning Run' })
  @IsString()
  @MaxLength(100)
  name: string;

  // Free-form so users can pick Health/Wealth/Peace/Others plus any custom
  // category name typed under "Others". Legacy categories (Fitness, Learning,
  // …) remain valid values stored in existing rows.
  @ApiProperty({ example: 'Health', default: 'OTHER' })
  @IsString()
  @IsOptional()
  @MaxLength(50)
  category?: string;

  @ApiPropertyOptional({ example: '🏃' })
  @IsString()
  @IsOptional()
  emoji?: string;

  @ApiPropertyOptional({ example: '#7C3AED' })
  @IsString()
  @IsOptional()
  color?: string;

  @ApiPropertyOptional({
    example: [true, true, true, true, true, false, false],
  })
  @IsArray()
  @IsOptional()
  repeatDays?: boolean[];

  @ApiPropertyOptional({ example: '07:00' })
  @IsString()
  @IsOptional()
  reminderTime?: string;

  @ApiPropertyOptional({ example: true })
  @IsBoolean()
  @IsOptional()
  isInterval?: boolean;

  @ApiPropertyOptional({ example: 60 })
  @IsNumber()
  @IsOptional()
  intervalMinutes?: number;

  @ApiPropertyOptional({ example: '08:00' })
  @IsString()
  @IsOptional()
  windowStartTime?: string;

  @ApiPropertyOptional({ example: '22:00' })
  @IsString()
  @IsOptional()
  windowEndTime?: string;

  @ApiPropertyOptional({ example: 4000 })
  @IsNumber()
  @IsOptional()
  targetValue?: number;

  @ApiPropertyOptional({ example: 'ml' })
  @IsString()
  @IsOptional()
  @MaxLength(20)
  unit?: string;

  @ApiPropertyOptional({ example: false })
  @IsBoolean()
  @IsOptional()
  rollingInterval?: boolean;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}
