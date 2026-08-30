import { Inject, Injectable } from '@nestjs/common';
import { Pool, PoolClient } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface BudgetPeriod {
  id: string;
  user_id: string;
  started_at: string;
  ended_at: string | null;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

@Injectable()
export class BudgetPeriodsRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async findActiveByUser(userId: string): Promise<BudgetPeriod | null> {
    const result = await this.pool.query<BudgetPeriod>(
      `SELECT * FROM budget_periods
       WHERE user_id = $1 AND ended_at IS NULL AND deleted_at IS NULL`,
      [userId],
    );
    return result.rows[0] ?? null;
  }

  async findAllByUser(userId: string): Promise<BudgetPeriod[]> {
    const result = await this.pool.query<BudgetPeriod>(
      `SELECT * FROM budget_periods WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY started_at DESC`,
      [userId],
    );
    return result.rows;
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<BudgetPeriod | null> {
    const result = await this.pool.query<BudgetPeriod>(
      `SELECT * FROM budget_periods WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return result.rows[0] ?? null;
  }

  async closeActive(
    client: PoolClient,
    userId: string,
    endedAt: string,
  ): Promise<void> {
    await client.query(
      `UPDATE budget_periods SET ended_at = $2, updated_at = now()
       WHERE user_id = $1 AND ended_at IS NULL AND deleted_at IS NULL`,
      [userId, endedAt],
    );
  }

  async create(
    client: PoolClient,
    userId: string,
    startedAt: string,
  ): Promise<BudgetPeriod> {
    const result = await client.query<BudgetPeriod>(
      `INSERT INTO budget_periods (user_id, started_at) VALUES ($1, $2) RETURNING *`,
      [userId, startedAt],
    );
    return result.rows[0];
  }

  async withTransaction<T>(
    fn: (client: PoolClient) => Promise<T>,
  ): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}
