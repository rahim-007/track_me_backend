import {
  IsString,
  IsEnum,
  IsOptional,
  IsDateString,
  IsInt,
  IsNumber,
  MaxLength,
  Min,
  Max,
  IsIn,
  Validate,
  ValidationArguments,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GoalCategory, GoalPriority } from '@prisma/client';
import { GOAL_UNITS, isValidTargetForUnit } from '../goal-units';

/**
 * Rejects fractional `target` values for count-based units (books, tasks, ₹…).
 * Measurement units (kg, km, L, hours) keep decimals: 0.5 kg is fine, 2.5 books
 * is not. Goals without a unit accept any number (legacy behavior).
 */
@ValidatorConstraint({ name: 'isGoalTargetForUnit', async: false })
export class IsGoalTargetForUnit implements ValidatorConstraintInterface {
  validate(value: unknown, args: ValidationArguments): boolean {
    const unit: string | undefined = (args.object as any)?.unit;
    return isValidTargetForUnit(value, unit);
  }

  defaultMessage(args: ValidationArguments): string {
    const unit: string | undefined = (args.object as any)?.unit;
    return unit
      ? `target must be a whole number for the unit "${unit}"`
      : 'target must be a non-negative number';
  }
}

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

  @ApiPropertyOptional({
    example: 5,
    description:
      'Target amount in the goal unit (e.g. 5 for a 5 kg weight-loss goal). ' +
      'Decimals allowed for measurement units (kg, km, L, hours), whole numbers ' +
      'only for count/currency units (books, tasks, ₹).',
  })
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(0)
  @Max(1000000000)
  @Validate(IsGoalTargetForUnit)
  target?: number;

  @ApiPropertyOptional({
    enum: GOAL_UNITS,
    example: 'kg',
    description: 'Unit the target/progress values are expressed in.',
  })
  @IsOptional()
  @IsString()
  @IsIn(GOAL_UNITS as unknown as string[])
  unit?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}

