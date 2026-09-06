import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface Budget {
  id: string;
  period_id: string;
  category_id: string;
  limit_amount: string;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

@Injectable()
export class BudgetsRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async create(
    periodId: string,
    categoryId: string,
    limitAmount: number,
  ): Promise<Budget> {
    const result = await this.pool.query<Budget>(
      `INSERT INTO budgets (period_id, category_id, limit_amount)
       VALUES ($1, $2, $3) RETURNING *`,
      [periodId, categoryId, limitAmount],
    );
    return result.rows[0];
  }

  async findAllByPeriod(periodId: string): Promise<Budget[]> {
    const result = await this.pool.query<Budget>(
      `SELECT * FROM budgets WHERE period_id = $1 AND deleted_at IS NULL`,
      [periodId],
    );
    return result.rows;
  }

  async findByIdInPeriod(
    id: string,
    periodId: string,
  ): Promise<Budget | null> {
    const result = await this.pool.query<Budget>(
      `SELECT * FROM budgets WHERE id = $1 AND period_id = $2 AND deleted_at IS NULL`,
      [id, periodId],
    );
    return result.rows[0] ?? null;
  }

  async update(id: string, limitAmount: number): Promise<Budget | null> {
    const result = await this.pool.query<Budget>(
      `UPDATE budgets SET limit_amount = $2, updated_at = now()
       WHERE id = $1 AND deleted_at IS NULL RETURNING *`,
      [id, limitAmount],
    );
    return result.rows[0] ?? null;
  }

  async softDelete(id: string): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE budgets SET deleted_at = now(), updated_at = now()
       WHERE id = $1 AND deleted_at IS NULL`,
      [id],
    );
    return (result.rowCount ?? 0) > 0;
  }

  async getSpent(budgetId: string): Promise<number> {
    const result = await this.pool.query<{ spent: string }>(
      `SELECT COALESCE(SUM(t.amount), 0) AS spent
       FROM budgets b
       JOIN periods bp ON bp.id = b.period_id
       JOIN transactions t
         ON t.category_id = b.category_id
         AND t.type = 'Expense'
         AND t.deleted_at IS NULL
         AND t.occurred_at >= bp.started_at
         AND (bp.ended_at IS NULL OR t.occurred_at <= bp.ended_at)
       WHERE b.id = $1
       GROUP BY b.id`,
      [budgetId],
    );
    return Number(result.rows[0]?.spent ?? 0);
  }
}
