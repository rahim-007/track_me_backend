import {
  Controller, Get, Post, Patch, Delete,
  Body, Param, Request, UseGuards
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { GoalsService } from './goals.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalDto } from './dto/update-goal.dto';
import { UpdateGoalProgressDto } from './dto/update-goal-progress.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Goals')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('goals')
export class GoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all goals' })
  findAll(@Request() req: any) {
    return this.goalsService.findAll(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single goal with progress history' })
  findOne(@Request() req: any, @Param('id') id: string) {
    return this.goalsService.findOne(req.user.id, id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new goal' })
  create(@Request() req: any, @Body() dto: CreateGoalDto) {
    return this.goalsService.create(req.user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a goal' })
  update(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateGoalDto,
  ) {
    return this.goalsService.update(req.user.id, id, dto);
  }

  @Patch(':id/progress')
  @ApiOperation({ summary: 'Update goal progress (0.0 - 1.0)' })
  updateProgress(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateGoalProgressDto,
  ) {
    return this.goalsService.updateProgress(req.user.id, id, dto.progress, dto.notes);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a goal' })
  remove(@Request() req: any, @Param('id') id: string) {
    return this.goalsService.remove(req.user.id, id);
  }
}
