import { Controller, Get, Patch, Body, Request, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Users')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  getProfile(@Request() req: any) {
    return this.usersService.getProfile(req.user.id);
  }

  @Get('me/stats')
  @ApiOperation({ summary: 'Get user statistics' })
  getStats(@Request() req: any) {
    return this.usersService.getStats(req.user.id);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update user profile' })
  updateProfile(
    @Request() req: any,
    @Body() dto: { name?: string; avatarUrl?: string },
  ) {
    return this.usersService.updateProfile(req.user.id, dto);
  }

  @Patch('me/fcm-token')
  @ApiOperation({ summary: 'Update FCM token' })
  updateFcmToken(@Request() req: any, @Body() dto: { fcmToken: string }) {
    return this.usersService.updateFcmToken(req.user.id, dto.fcmToken);
  }
}
