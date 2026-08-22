import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateUserDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiProperty({
    required: false,
    description: 'IANA timezone name (e.g. "Asia/Kolkata") used to schedule reminders at the user\'s local clock',
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  timezone?: string;
}
