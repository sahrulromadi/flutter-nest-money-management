import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { RecurringRulesService } from './recurring-rules.service';

@Injectable()
export class RecurringRulesScheduler {
  constructor(
    private readonly recurringRulesService: RecurringRulesService,
  ) {}

  @Cron('0 1 * * *')
  async handleDailyGeneration() {
    await this.recurringRulesService.generateDueTransactions();
  }
}
