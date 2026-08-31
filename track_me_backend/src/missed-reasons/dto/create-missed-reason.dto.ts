import { IsString, IsDateString, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateMissedReasonDto {
  @ApiProperty({ example: 'clxyz123', description: 'Habit ID' })
  @IsString()
  habitId: string;

  @ApiProperty({ example: '2026-08-02', description: 'The date the habit was missed (YYYY-MM-DD)' })
  @IsDateString()
  missedDate: string;

  @ApiProperty({
    example: 'Had a long day at work and came home exhausted.',
    description: 'Reason for missing the habit (5–250 chars)',
    minLength: 5,
    maxLength: 250,
  })
  @IsString()
  @MinLength(5)
  @MaxLength(250)
  reason: string;
}
