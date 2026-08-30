import { Module } from '@nestjs/common';
import { BudgetPeriodsModule } from '../budget-periods/budget-periods.module';
import { CategoriesModule } from '../categories/categories.module';
import { BudgetsController } from './budgets.controller';
import { BudgetsService } from './budgets.service';
import { BudgetsRepository } from './budgets.repository';

@Module({
  imports: [BudgetPeriodsModule, CategoriesModule],
  controllers: [BudgetsController],
  providers: [BudgetsService, BudgetsRepository],
})
export class BudgetsModule {}
