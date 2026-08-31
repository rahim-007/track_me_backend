import {
  Body, Controller, Delete, Get, Patch, Post, Param, Query, Request, UseGuards
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@ApiTags('Notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Get user notifications (paginated)' })
  getNotifications(
    @Request() req: any,
    @Query('take') take?: string,
    @Query('skip') skip?: string,
  ) {
    return this.notificationsService.getNotifications(
      req.user.id,
      take ? parseInt(take, 10) : 50,
      skip ? parseInt(skip, 10) : 0,
    );
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  getUnreadCount(@Request() req: any) {
    return this.notificationsService.getUnreadCount(req.user.id);
  }

  @Post('device-token')
  @ApiOperation({ summary: 'Register (or refresh) the user\'s FCM device token' })
  registerDeviceToken(@Request() req: any, @Body() dto: RegisterDeviceTokenDto) {
    if (!dto.token || dto.token.trim().length === 0) {
      return this.notificationsService.clearDeviceToken(req.user.id);
    }
    return this.notificationsService.registerDeviceToken(
      req.user.id,
      dto.token.trim(),
    );
  }

  @Post('test-push')
  @ApiOperation({ summary: 'Send an immediate test push notification to the authenticated user\'s device' })
  sendTestPush(@Request() req: any) {
    return this.notificationsService.sendTestPush(req.user.id);
  }

  @Delete('device-token')
  @ApiOperation({ summary: 'Clear the registered FCM device token' })
  clearDeviceToken(@Request() req: any) {
    return this.notificationsService.clearDeviceToken(req.user.id);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark notification as read' })
  markAsRead(@Request() req: any, @Param('id') id: string) {
    return this.notificationsService.markAsRead(req.user.id, id);
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  markAllAsRead(@Request() req: any) {
    return this.notificationsService.markAllAsRead(req.user.id);
  }

  @Delete('clear-all')
  @ApiOperation({ summary: 'Clear all notifications for the user' })
  clearAllNotifications(@Request() req: any) {
    return this.notificationsService.clearAllNotifications(req.user.id);
  }

  @Delete()
  @ApiOperation({ summary: 'Clear all notifications for the user' })
  clearAllNotificationsRoot(@Request() req: any) {
    return this.notificationsService.clearAllNotifications(req.user.id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a notification' })
  deleteNotification(@Request() req: any, @Param('id') id: string) {
    return this.notificationsService.deleteNotification(req.user.id, id);
  }
}
