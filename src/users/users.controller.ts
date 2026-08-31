import { Controller, Get, Patch, Delete, Body, Request, UseGuards, HttpCode, HttpStatus, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
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
  updateProfile(@Request() req: any, @Body() dto: UpdateUserDto) {
    return this.usersService.updateProfile(req.user.id, dto);
  }

  @Patch('me/fcm-token')
  @ApiOperation({ summary: 'Update FCM token' })
  updateFcmToken(@Request() req: any, @Body() dto: { fcmToken: string }) {
    return this.usersService.updateFcmToken(req.user.id, dto.fcmToken);
  }

  @Delete('me')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Permanently delete the authenticated user\'s account and all data' })
  @ApiResponse({ status: 200, description: 'Account deleted successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Account not found' })
  async deleteAccount(@Request() req: any) {
    const result = await this.usersService.deleteAccount(req.user.id);
    if (result === null) {
      throw new NotFoundException('Account not found');
    }
    return { message: 'Account deleted successfully' };
  }
}
