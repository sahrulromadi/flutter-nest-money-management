import { Injectable, NotFoundException } from '@nestjs/common';
import { BudgetPeriodsRepository } from './budget-periods.repository';

@Injectable()
export class BudgetPeriodsService {
  constructor(
    private readonly budgetPeriodsRepository: BudgetPeriodsRepository,
  ) {}

  async startNewPeriod(userId: string, startedAt: string) {
    return this.budgetPeriodsRepository.withTransaction(async (client) => {
      const endedAt = this.dayBefore(startedAt);
      await this.budgetPeriodsRepository.closeActive(client, userId, endedAt);
      return this.budgetPeriodsRepository.create(client, userId, startedAt);
    });
  }

  findAll(userId: string) {
    return this.budgetPeriodsRepository.findAllByUser(userId);
  }

  async findActive(userId: string) {
    const period = await this.budgetPeriodsRepository.findActiveByUser(
      userId,
    );
    if (!period) {
      throw new NotFoundException('Belum ada periode budget aktif');
    }
    return period;
  }

  private dayBefore(dateString: string): string {
    const date = new Date(`${dateString}T00:00:00Z`);
    date.setUTCDate(date.getUTCDate() - 1);
    return date.toISOString().slice(0, 10);
  }
}
