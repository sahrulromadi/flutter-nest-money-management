import { Module } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { CategoriesModule } from '../categories/categories.module';
import { TransactionsModule } from '../transactions/transactions.module';
import { RecurringRulesController } from './recurring-rules.controller';
import { RecurringRulesService } from './recurring-rules.service';
import { RecurringRulesRepository } from './recurring-rules.repository';
import { RecurringRulesScheduler } from './recurring-rules.scheduler';

@Module({
  imports: [AccountsModule, CategoriesModule, TransactionsModule],
  controllers: [RecurringRulesController],
  providers: [
    RecurringRulesService,
    RecurringRulesRepository,
    RecurringRulesScheduler,
  ],
})
export class RecurringRulesModule {}
