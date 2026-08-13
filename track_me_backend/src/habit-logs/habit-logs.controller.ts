import {
  Controller, Post, Delete, Get, Body, Param, Request, UseGuards, HttpCode, HttpStatus
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { HabitLogsService } from './habit-logs.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Habit Logs')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('habit-logs')
export class HabitLogsController {
  constructor(private readonly habitLogsService: HabitLogsService) {}

  @Post()
  @ApiOperation({ summary: 'Mark habit as complete for a date' })
  complete(
    @Request() req: any,
    @Body() dto: { habitId: string; date: string },
  ) {
    return this.habitLogsService.completeHabit(req.user.id, dto.habitId, dto.date);
  }

  @Post('skip')
  @ApiOperation({ summary: 'Skip a habit with reason' })
  skip(
    @Request() req: any,
    @Body() dto: { habitId: string; date: string; reason: string },
  ) {
    return this.habitLogsService.skipHabit(req.user.id, dto.habitId, dto.date, dto.reason);
  }
  

  @Delete(':habitId/:date')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Uncomplete a habit for a date' })
  uncomplete(
    @Request() req: any,
    @Param('habitId') habitId: string,
    @Param('date') date: string,
  ) {
    return this.habitLogsService.uncomplete(req.user.id, habitId, date);
  }

  @Get('weekly-stats')
  @ApiOperation({ summary: 'Get weekly habit statistics' })
  getWeeklyStats(@Request() req: any) {
    return this.habitLogsService.getWeeklyStats(req.user.id);
  }
}
