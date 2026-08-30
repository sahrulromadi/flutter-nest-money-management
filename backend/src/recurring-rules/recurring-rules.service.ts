import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { addDays, addMonths, addWeeks } from 'date-fns';
import { AccountsRepository } from '../accounts/accounts.repository';
import { CategoriesRepository } from '../categories/categories.repository';
import { TransactionsRepository } from '../transactions/transactions.repository';
import { RecurringRulesRepository } from './recurring-rules.repository';
import { CreateRecurringRuleDto } from './dto/create-recurring-rule.dto';
import { UpdateRecurringRuleDto } from './dto/update-recurring-rule.dto';

@Injectable()
export class RecurringRulesService {
  private readonly logger = new Logger(RecurringRulesService.name);

  constructor(
    private readonly recurringRulesRepository: RecurringRulesRepository,
    private readonly transactionsRepository: TransactionsRepository,
    private readonly accountsRepository: AccountsRepository,
    private readonly categoriesRepository: CategoriesRepository,
  ) {}

  async create(userId: string, dto: CreateRecurringRuleDto) {
    const account = await this.accountsRepository.findByIdAndUser(
      dto.accountId,
      userId,
    );
    if (!account) {
      throw new BadRequestException('Akun tidak ditemukan');
    }
    const category = await this.categoriesRepository.findByIdAndUser(
      dto.categoryId,
      userId,
    );
    if (!category || category.type !== dto.type) {
      throw new BadRequestException(
        'Kategori tidak ditemukan atau tipe gak sesuai',
      );
    }
    return this.recurringRulesRepository.create(userId, dto);
  }

  findAll(userId: string) {
    return this.recurringRulesRepository.findAllByUser(userId);
  }

  async findOne(userId: string, id: string) {
    const rule = await this.recurringRulesRepository.findByIdAndUser(
      id,
      userId,
    );
    if (!rule) {
      throw new NotFoundException('Recurring rule tidak ditemukan');
    }
    return rule;
  }

  async update(userId: string, id: string, dto: UpdateRecurringRuleDto) {
    const rule = await this.recurringRulesRepository.update(id, userId, dto);
    if (!rule) {
      throw new NotFoundException('Recurring rule tidak ditemukan');
    }
    return rule;
  }

  async remove(userId: string, id: string) {
    const deleted = await this.recurringRulesRepository.softDelete(
      id,
      userId,
    );
    if (!deleted) {
      throw new NotFoundException('Recurring rule tidak ditemukan');
    }
  }

  async generateDueTransactions(): Promise<number> {
    const dueRules = await this.recurringRulesRepository.findDueRules();
    for (const rule of dueRules) {
      await this.transactionsRepository.create(rule.user_id, {
        accountId: rule.account_id,
        categoryId: rule.category_id,
        type: rule.type,
        amount: Number(rule.amount),
        occurredAt: rule.next_run_date,
        note: rule.note,
        recurringRuleId: rule.id,
      });

      const nextRunDate = this.computeNextRunDate(
        rule.next_run_date,
        rule.interval_unit,
        rule.interval_value,
      );
      await this.recurringRulesRepository.advanceNextRunDate(
        rule.id,
        nextRunDate,
      );
    }
    this.logger.log(`Generated ${dueRules.length} recurring transaction(s)`);
    return dueRules.length;
  }

  private computeNextRunDate(
    fromDate: string,
    unit: 'Day' | 'Week' | 'Month',
    value: number,
  ): string {
    const date = new Date(`${fromDate}T00:00:00Z`);
    const next =
      unit === 'Day'
        ? addDays(date, value)
        : unit === 'Week'
          ? addWeeks(date, value)
          : addMonths(date, value);
    return next.toISOString().slice(0, 10);
  }
}
