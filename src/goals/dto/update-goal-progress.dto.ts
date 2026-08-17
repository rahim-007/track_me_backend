import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Body for `PATCH /goals/:id/progress`.
 *
 * `progress` is the 0.0 – 1.0 completion ratio (1.0 = 100%). Whether the implied
 * unit value (progress × target) may be fractional is enforced in the service,
 * which knows the goal's unit (e.g. 2.5 books is rejected, 2.5 km is allowed).
 */
export class UpdateGoalProgressDto {
  @ApiProperty({ example: 0.5, description: 'Goal progress as a 0.0 - 1.0 ratio' })
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(0)
  @Max(1)
  progress: number;

  @ApiPropertyOptional({ example: 'Ran 5 km today' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;
}
