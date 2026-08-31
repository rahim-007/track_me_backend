import {
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
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

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}
