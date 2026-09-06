import { Injectable, NotFoundException } from '@nestjs/common';
import { PeriodsRepository } from './periods.repository';

@Injectable()
export class PeriodsService {
  constructor(private readonly periodsRepository: PeriodsRepository) {}

  async startNewPeriod(userId: string, startedAt: string) {
    return this.periodsRepository.withTransaction(async (client) => {
      const endedAt = this.dayBefore(startedAt);
      await this.periodsRepository.closeActive(client, userId, endedAt);
      return this.periodsRepository.create(client, userId, startedAt);
    });
  }

  findAll(userId: string) {
    return this.periodsRepository.findAllByUser(userId);
  }

  async findActive(userId: string) {
    const period = await this.periodsRepository.findActiveByUser(userId);
    if (!period) {
      throw new NotFoundException('Belum ada periode aktif');
    }
    return period;
  }

  private dayBefore(dateString: string): string {
    const date = new Date(`${dateString}T00:00:00Z`);
    date.setUTCDate(date.getUTCDate() - 1);
    return date.toISOString().slice(0, 10);
  }
}
