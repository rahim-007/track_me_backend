import {
  Controller, Get, Post, Body, Query, Request, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { MissedReasonsService } from './missed-reasons.service';
import { CreateMissedReasonDto } from './dto/create-missed-reason.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Missed Reasons')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('missed-reasons')
export class MissedReasonsController {
  constructor(private readonly missedReasonsService: MissedReasonsService) {}

  /**
   * Batch-save reasons for all missed habits on a given date.
   * Uses upsert so calling twice for same date is safe.
   */
  @Post()
  @ApiOperation({ summary: 'Save missed habit reasons (batch)' })
  createMany(@Request() req: any, @Body() dtos: CreateMissedReasonDto[]) {
    return this.missedReasonsService.createMany(req.user.id, dtos);
  }

  /**
   * List all missed reasons for the authenticated user.
   * Optionally filter by a specific date (YYYY-MM-DD).
   */
  @Get()
  @ApiOperation({ summary: 'Get missed habit reasons' })
  @ApiQuery({ name: 'date', required: false, description: 'Filter by date (YYYY-MM-DD)' })
  findAll(@Request() req: any, @Query('date') date?: string) {
    return this.missedReasonsService.findAll(req.user.id, date);
  }

  /**
   * Check whether reasons have already been submitted for a given date.
   * Used by the Flutter app to decide whether to show the popup.
   */
  @Get('check')
  @ApiOperation({ summary: 'Check if reasons already submitted for a date' })
  @ApiQuery({ name: 'date', required: true, description: 'Date to check (YYYY-MM-DD)' })
  check(@Request() req: any, @Query('date') date: string) {
    return this.missedReasonsService.hasSubmittedForDate(req.user.id, date);
  }
}
