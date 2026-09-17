import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { AppService } from './app.service';

@ApiTags('Health')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @SkipThrottle()
  @ApiOperation({ summary: 'API root health ping' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  getRoot() {
    return this.appService.getHealth();
  }

  @Get('health')
  @SkipThrottle()
  @ApiOperation({ summary: 'Health check endpoint for monitoring (UptimeRobot, etc.)' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  getHealth() {
    return this.appService.getHealth();
  }
}
