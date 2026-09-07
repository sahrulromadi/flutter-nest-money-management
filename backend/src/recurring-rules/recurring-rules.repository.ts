import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface RecurringRule {
  id: string;
  user_id: string;
  account_id: string;
  category_id: string;
  type: 'Income' | 'Expense';
  amount: string;
  note: string | null;
  interval_unit: 'Day' | 'Week' | 'Month' | 'DaysOfWeek';
  interval_value: number;
  start_date: string;
  next_run_date: string;
  end_date: string | null;
  days_of_week: string | null;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

@Injectable()
export class RecurringRulesRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async create(
    userId: string,
    data: {
      accountId: string;
      categoryId: string;
      type: string;
      amount: number;
      note?: string | null;
      intervalUnit: string;
      intervalValue: number;
      daysOfWeek?: string | null;
      startDate: string;
      endDate?: string | null;
    },
  ): Promise<RecurringRule> {
    const result = await this.pool.query<RecurringRule>(
      `INSERT INTO recurring_rules
         (user_id, account_id, category_id, type, amount, note, interval_unit, interval_value, days_of_week, start_date, next_run_date, end_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $10, $11)
       RETURNING *`,
      [
        userId,
        data.accountId,
        data.categoryId,
        data.type,
        data.amount,
        data.note ?? null,
        data.intervalUnit,
        data.intervalValue,
        data.daysOfWeek ?? null,
        data.startDate,
        data.endDate ?? null,
      ],
    );
    return result.rows[0];
  }

  async findAllByUser(userId: string): Promise<RecurringRule[]> {
    const result = await this.pool.query<RecurringRule>(
      `SELECT * FROM recurring_rules WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at`,
      [userId],
    );
    return result.rows;
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<RecurringRule | null> {
    const result = await this.pool.query<RecurringRule>(
      `SELECT * FROM recurring_rules WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return result.rows[0] ?? null;
  }

  async update(
    id: string,
    userId: string,
    data: { amount?: number; note?: string | null; endDate?: string | null },
  ): Promise<RecurringRule | null> {
    const result = await this.pool.query<RecurringRule>(
      `UPDATE recurring_rules SET
         amount = COALESCE($3, amount),
         note = COALESCE($4, note),
         end_date = COALESCE($5, end_date),
         updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING *`,
      [id, userId, data.amount ?? null, data.note ?? null, data.endDate ?? null],
    );
    return result.rows[0] ?? null;
  }

  async softDelete(id: string, userId: string): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE recurring_rules SET deleted_at = now(), updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return (result.rowCount ?? 0) > 0;
  }
}
