import {
  IsString,
  IsEnum,
  IsOptional,
  IsDateString,
  IsInt,
  MaxLength,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GoalCategory, GoalPriority } from '@prisma/client';

export class CreateGoalDto {
  @ApiProperty({ example: 'Run a Marathon' })
  @IsString()
  @MaxLength(200)
  name: string;

  @ApiProperty({ enum: GoalCategory })
  @IsEnum(GoalCategory)
  @IsOptional()
  category?: GoalCategory;

  @ApiProperty({ example: '2025-12-31' })
  @IsDateString()
  targetDate: string;

  @ApiProperty({ enum: GoalPriority })
  @IsEnum(GoalPriority)
  @IsOptional()
  priority?: GoalPriority;

  @ApiPropertyOptional({ example: 90, description: 'Goal duration in days (1 - 365)' })
  @IsInt()
  @Min(1)
  @Max(365)
  @IsOptional()
  durationDays?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}
