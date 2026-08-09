import {
  IsString, IsOptional, IsBoolean, IsArray, IsEnum, MaxLength
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { HabitCategory } from '@prisma/client';

export class CreateHabitDto {
  @ApiProperty({ example: 'Morning Run' })
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiProperty({ enum: HabitCategory, default: HabitCategory.OTHER })
  @IsEnum(HabitCategory)
  @IsOptional()
  category?: HabitCategory;

  @ApiPropertyOptional({ example: '🏃' })
  @IsString()
  @IsOptional()
  emoji?: string;

  @ApiPropertyOptional({ example: '#7C3AED' })
  @IsString()
  @IsOptional()
  color?: string;

  @ApiPropertyOptional({ example: [true, true, true, true, true, false, false] })
  @IsArray()
  @IsOptional()
  repeatDays?: boolean[];

  @ApiPropertyOptional({ example: '07:00' })
  @IsString()
  @IsOptional()
  reminderTime?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}
