import { Injectable } from '@nestjs/common';
import { RemindersRepository } from './reminders.repository';

@Injectable()
export class RemindersService {
  constructor(private readonly remindersRepository: RemindersRepository) {}

  upcomingBills(userId: string, withinDays: number) {
    return this.remindersRepository.findUpcomingBills(userId, withinDays);
  }

  async dailyCheck(userId: string) {
    const hasTransactionToday =
      await this.remindersRepository.hasTransactionToday(userId);
    return { hasTransactionToday };
  }
}
