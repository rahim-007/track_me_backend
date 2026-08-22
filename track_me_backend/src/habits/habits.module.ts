import { Module } from '@nestjs/common';
import { HabitsController } from './habits.controller';
import { HabitsService } from './habits.service';
import { ReminderSchedulerService } from './reminder-scheduler.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [HabitsController],
  providers: [HabitsService, ReminderSchedulerService],
  exports: [HabitsService],
})
export class HabitsModule {}
