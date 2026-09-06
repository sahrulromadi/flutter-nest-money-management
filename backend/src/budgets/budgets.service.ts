import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PeriodsRepository } from '../periods/periods.repository';
import { CategoriesRepository } from '../categories/categories.repository';
import { BudgetsRepository } from './budgets.repository';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { UpdateBudgetDto } from './dto/update-budget.dto';

interface PgError {
  code?: string;
}

function isPgError(error: unknown): error is PgError {
  return typeof error === 'object' && error !== null && 'code' in error;
}

@Injectable()
export class BudgetsService {
  constructor(
    private readonly budgetsRepository: BudgetsRepository,
    private readonly periodsRepository: PeriodsRepository,
    private readonly categoriesRepository: CategoriesRepository,
  ) {}

  async create(userId: string, periodId: string | undefined, dto: CreateBudgetDto) {
    const period = await this.resolvePeriod(userId, periodId);
    const category = await this.categoriesRepository.findByIdAndUser(
      dto.categoryId,
      userId,
    );
    if (!category || category.type !== 'Expense') {
      throw new BadRequestException(
        'Kategori tidak ditemukan atau bukan kategori Expense',
      );
    }

    try {
      const budget = await this.budgetsRepository.create(
        period.id,
        dto.categoryId,
        dto.limitAmount,
      );
      return this.withSpent(budget);
    } catch (error) {
      if (isPgError(error) && error.code === '23505') {
        throw new BadRequestException(
          'Kategori ini udah punya budget di periode ini',
        );
      }
      throw error;
    }
  }

  async findAll(userId: string, periodId: string | undefined) {
    const period = await this.resolvePeriod(userId, periodId);
    const budgets = await this.budgetsRepository.findAllByPeriod(period.id);
    return Promise.all(budgets.map((b) => this.withSpent(b)));
  }

  async update(
    userId: string,
    periodId: string | undefined,
    id: string,
    dto: UpdateBudgetDto,
  ) {
    const period = await this.resolvePeriod(userId, periodId);
    const existing = await this.budgetsRepository.findByIdInPeriod(
      id,
      period.id,
    );
    if (!existing) {
      throw new NotFoundException('Budget tidak ditemukan');
    }
    const budget = await this.budgetsRepository.update(id, dto.limitAmount);
    return this.withSpent(budget!);
  }

  async remove(userId: string, periodId: string | undefined, id: string) {
    const period = await this.resolvePeriod(userId, periodId);
    const existing = await this.budgetsRepository.findByIdInPeriod(
      id,
      period.id,
    );
    if (!existing) {
      throw new NotFoundException('Budget tidak ditemukan');
    }
    await this.budgetsRepository.softDelete(id);
  }

  private async resolvePeriod(userId: string, periodId: string | undefined) {
    if (periodId) {
      const period = await this.periodsRepository.findByIdAndUser(
        periodId,
        userId,
      );
      if (!period) {
        throw new NotFoundException('Periode tidak ditemukan');
      }
      return period;
    }
    const active = await this.periodsRepository.findActiveByUser(
      userId,
    );
    if (!active) {
      throw new NotFoundException('Belum ada periode aktif');
    }
    return active;
  }

  private async withSpent<T extends { id: string; limit_amount: string }>(
    budget: T,
  ) {
    const spent = await this.budgetsRepository.getSpent(budget.id);
    const limit = Number(budget.limit_amount);
    return {
      ...budget,
      spent,
      percentage: limit > 0 ? Math.round((spent / limit) * 100) : 0,
    };
  }
}
