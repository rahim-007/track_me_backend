import { Module } from '@nestjs/common';
import { HabitLogsController } from './habit-logs.controller';
import { HabitLogsService } from './habit-logs.service';

@Module({
  controllers: [HabitLogsController],
  providers: [HabitLogsService],
})
export class HabitLogsModule {}
