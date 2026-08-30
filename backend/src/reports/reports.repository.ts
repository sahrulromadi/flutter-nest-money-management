import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface CategoryBreakdownRow {
  category_id: string;
  category_name: string;
  total: string;
}

export interface CashflowTrendRow {
  day: string;
  income: string;
  expense: string;
}

export interface SummaryRow {
  total_income: string;
  total_expense: string;
}

@Injectable()
export class ReportsRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async getSummary(
    userId: string,
    from: string,
    to: string,
  ): Promise<SummaryRow> {
    const result = await this.pool.query<SummaryRow>(
      `SELECT
         COALESCE(SUM(amount) FILTER (WHERE type = 'Income'), 0) AS total_income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'Expense'), 0) AS total_expense
       FROM transactions
       WHERE user_id = $1 AND deleted_at IS NULL
         AND occurred_at >= $2 AND occurred_at <= $3`,
      [userId, from, to],
    );
    return result.rows[0];
  }

  async getCategoryBreakdown(
    userId: string,
    from: string,
    to: string,
    type?: string,
  ): Promise<CategoryBreakdownRow[]> {
    const result = await this.pool.query<CategoryBreakdownRow>(
      `SELECT c.id AS category_id, c.name AS category_name, SUM(t.amount) AS total
       FROM transactions t
       JOIN categories c ON c.id = t.category_id
       WHERE t.user_id = $1 AND t.deleted_at IS NULL
         AND t.type <> 'Transfer'
         AND t.occurred_at >= $2 AND t.occurred_at <= $3
         AND ($4::text IS NULL OR t.type = $4)
       GROUP BY c.id, c.name
       ORDER BY total DESC`,
      [userId, from, to, type ?? null],
    );
    return result.rows;
  }

  async getCashflowTrend(
    userId: string,
    from: string,
    to: string,
  ): Promise<CashflowTrendRow[]> {
    const result = await this.pool.query<CashflowTrendRow>(
      `SELECT
         occurred_at::date AS day,
         COALESCE(SUM(amount) FILTER (WHERE type = 'Income'), 0) AS income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'Expense'), 0) AS expense
       FROM transactions
       WHERE user_id = $1 AND deleted_at IS NULL
         AND occurred_at >= $2 AND occurred_at <= $3
       GROUP BY occurred_at::date
       ORDER BY day`,
      [userId, from, to],
    );
    return result.rows;
  }
}
