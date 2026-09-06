import { Module } from '@nestjs/common';
import { PeriodsController } from './periods.controller';
import { PeriodsService } from './periods.service';
import { PeriodsRepository } from './periods.repository';

@Module({
  controllers: [PeriodsController],
  providers: [PeriodsService, PeriodsRepository],
  exports: [PeriodsRepository],
})
export class PeriodsModule {}
