import { Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('AI')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Get('insights')
  @ApiOperation({ summary: 'Get AI-powered productivity insights' })
  getInsights(@Request() req: any) {
    return this.aiService.getInsights(req.user.id);
  }

  @Post('weekly-report')
  @ApiOperation({ summary: 'Generate and store weekly AI report' })
  generateWeeklyReport(@Request() req: any) {
    return this.aiService.generateWeeklyReport(req.user.id);
  }
}
