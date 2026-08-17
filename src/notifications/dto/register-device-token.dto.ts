import { IsString, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDeviceTokenDto {
  @ApiProperty({ description: 'FCM device token (empty string clears it)' })
  @IsString()
  @IsOptional()
  token?: string;
}
