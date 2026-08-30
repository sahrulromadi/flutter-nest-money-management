import { Module } from '@nestjs/common';
import { BudgetPeriodsController } from './budget-periods.controller';
import { BudgetPeriodsService } from './budget-periods.service';
import { BudgetPeriodsRepository } from './budget-periods.repository';

@Module({
  controllers: [BudgetPeriodsController],
  providers: [BudgetPeriodsService, BudgetPeriodsRepository],
  exports: [BudgetPeriodsRepository],
})
export class BudgetPeriodsModule {}
