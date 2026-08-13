import { Module } from '@nestjs/common';
import { MissedReasonsController } from './missed-reasons.controller';
import { MissedReasonsService } from './missed-reasons.service';

@Module({
  controllers: [MissedReasonsController],
  providers: [MissedReasonsService],
  exports: [MissedReasonsService],
})
export class MissedReasonsModule {}
