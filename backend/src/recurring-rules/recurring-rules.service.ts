import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AccountsRepository } from '../accounts/accounts.repository';
import { CategoriesRepository } from '../categories/categories.repository';
import { RecurringRulesRepository } from './recurring-rules.repository';
import { CreateRecurringRuleDto } from './dto/create-recurring-rule.dto';
import { UpdateRecurringRuleDto } from './dto/update-recurring-rule.dto';

@Injectable()
export class RecurringRulesService {
  constructor(
    private readonly recurringRulesRepository: RecurringRulesRepository,
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
}
