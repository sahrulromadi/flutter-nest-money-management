import { Module } from '@nestjs/common';
import { DebtsController } from './debts.controller';
import { DebtsService } from './debts.service';
import { DebtsRepository } from './debts.repository';

@Module({
  controllers: [DebtsController],
  providers: [DebtsService, DebtsRepository],
})
export class DebtsModule {}
