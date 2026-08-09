import {
  Controller, Get, Post, Patch, Delete,
  Body, Param, Request, UseGuards
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { HabitsService } from './habits.service';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Habits')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('habits')
export class HabitsController {
  constructor(private readonly habitsService: HabitsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all habits with weekly logs' })
  findAll(@Request() req: any) {
    return this.habitsService.findAll(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single habit' })
  findOne(@Request() req: any, @Param('id') id: string) {
    return this.habitsService.findOne(req.user.id, id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new habit' })
  create(@Request() req: any, @Body() dto: CreateHabitDto) {
    return this.habitsService.create(req.user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a habit' })
  update(@Request() req: any, @Param('id') id: string, @Body() dto: UpdateHabitDto) {
    return this.habitsService.update(req.user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete (soft) a habit' })
  remove(@Request() req: any, @Param('id') id: string) {
    return this.habitsService.remove(req.user.id, id);
  }

  @Get(':id/streak')
  @ApiOperation({ summary: 'Get habit streak' })
  getStreak(@Request() req: any, @Param('id') id: string) {
    return this.habitsService.getStreak(req.user.id, id);
  }
}
