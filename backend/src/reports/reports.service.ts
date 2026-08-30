import { Injectable, NotFoundException } from '@nestjs/common';
import { BudgetPeriodsRepository } from '../budget-periods/budget-periods.repository';
import { ReportsRepository } from './reports.repository';

@Injectable()
export class ReportsService {
  constructor(
    private readonly reportsRepository: ReportsRepository,
    private readonly budgetPeriodsRepository: BudgetPeriodsRepository,
  ) {}

  async summary(userId: string, from?: string, to?: string) {
    const range = await this.resolveRange(userId, from, to);
    const row = await this.reportsRepository.getSummary(
      userId,
      range.from,
      range.to,
    );
    const totalIncome = Number(row.total_income);
    const totalExpense = Number(row.total_expense);
    return {
      from: range.from,
      to: range.to,
      totalIncome,
      totalExpense,
      net: totalIncome - totalExpense,
    };
  }

  async categoryBreakdown(
    userId: string,
    from?: string,
    to?: string,
    type?: string,
  ) {
    const range = await this.resolveRange(userId, from, to);
    return this.reportsRepository.getCategoryBreakdown(
      userId,
      range.from,
      range.to,
      type,
    );
  }

  async cashflowTrend(userId: string, from?: string, to?: string) {
    const range = await this.resolveRange(userId, from, to);
    return this.reportsRepository.getCashflowTrend(
      userId,
      range.from,
      range.to,
    );
  }

  private async resolveRange(userId: string, from?: string, to?: string) {
    if (from && to) {
      return { from, to };
    }
    const active = await this.budgetPeriodsRepository.findActiveByUser(
      userId,
    );
    if (!active) {
      throw new NotFoundException(
        'Belum ada periode budget aktif, kasih from/to manual',
      );
    }
    return {
      from: active.started_at,
      to: active.ended_at ?? new Date().toISOString().slice(0, 10),
    };
  }
}
