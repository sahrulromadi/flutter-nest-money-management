import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface UpcomingBill {
  id: string;
  account_id: string;
  category_id: string;
  type: 'Income' | 'Expense';
  amount: string;
  note: string | null;
  next_run_date: string;
}

@Injectable()
export class RemindersRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async findUpcomingBills(
    userId: string,
    withinDays: number,
  ): Promise<UpcomingBill[]> {
    const result = await this.pool.query<UpcomingBill>(
      `SELECT id, account_id, category_id, type, amount, note, next_run_date
       FROM recurring_rules
       WHERE user_id = $1 AND deleted_at IS NULL
         AND next_run_date <= CURRENT_DATE + ($2::int * INTERVAL '1 day')
         AND (end_date IS NULL OR end_date >= CURRENT_DATE)
       ORDER BY next_run_date`,
      [userId, withinDays],
    );
    return result.rows;
  }

  async hasTransactionToday(userId: string): Promise<boolean> {
    const result = await this.pool.query<{ exists: boolean }>(
      `SELECT EXISTS(
         SELECT 1 FROM transactions
         WHERE user_id = $1 AND deleted_at IS NULL AND occurred_at = CURRENT_DATE
       ) AS exists`,
      [userId],
    );
    return result.rows[0].exists;
  }
}
