import { Module } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { CategoriesModule } from '../categories/categories.module';
import { RecurringRulesController } from './recurring-rules.controller';
import { RecurringRulesService } from './recurring-rules.service';
import { RecurringRulesRepository } from './recurring-rules.repository';

@Module({
  imports: [AccountsModule, CategoriesModule],
  controllers: [RecurringRulesController],
  providers: [RecurringRulesService, RecurringRulesRepository],
})
export class RecurringRulesModule {}
