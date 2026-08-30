import { Module } from '@nestjs/common';
import { BudgetPeriodsModule } from '../budget-periods/budget-periods.module';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';
import { ReportsRepository } from './reports.repository';

@Module({
  imports: [BudgetPeriodsModule],
  controllers: [ReportsController],
  providers: [ReportsService, ReportsRepository],
})
export class ReportsModule {}
