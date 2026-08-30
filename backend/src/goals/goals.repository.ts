import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface Goal {
  id: string;
  user_id: string;
  account_id: string | null;
  name: string;
  target_amount: string;
  due_date: string | null;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

@Injectable()
export class GoalsRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async create(
    userId: string,
    data: {
      name: string;
      targetAmount: number;
      dueDate?: string | null;
      accountId?: string | null;
    },
  ): Promise<Goal> {
    const result = await this.pool.query<Goal>(
      `INSERT INTO goals (user_id, name, target_amount, due_date, account_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [
        userId,
        data.name,
        data.targetAmount,
        data.dueDate ?? null,
        data.accountId ?? null,
      ],
    );
    return result.rows[0];
  }

  async findAllByUser(userId: string): Promise<Goal[]> {
    const result = await this.pool.query<Goal>(
      `SELECT * FROM goals WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at`,
      [userId],
    );
    return result.rows;
  }

  async findByIdAndUser(id: string, userId: string): Promise<Goal | null> {
    const result = await this.pool.query<Goal>(
      `SELECT * FROM goals WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return result.rows[0] ?? null;
  }

  async update(
    id: string,
    userId: string,
    data: { name?: string; targetAmount?: number; dueDate?: string | null },
  ): Promise<Goal | null> {
    const result = await this.pool.query<Goal>(
      `UPDATE goals SET
         name = COALESCE($3, name),
         target_amount = COALESCE($4, target_amount),
         due_date = COALESCE($5, due_date),
         updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING *`,
      [
        id,
        userId,
        data.name ?? null,
        data.targetAmount ?? null,
        data.dueDate ?? null,
      ],
    );
    return result.rows[0] ?? null;
  }

  async softDelete(id: string, userId: string): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE goals SET deleted_at = now(), updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return (result.rowCount ?? 0) > 0;
  }

  async getCurrentAmount(goalId: string): Promise<number> {
    const result = await this.pool.query<{ current_amount: string }>(
      `SELECT COALESCE(SUM(amount), 0) AS current_amount
       FROM transactions WHERE goal_id = $1 AND deleted_at IS NULL`,
      [goalId],
    );
    return Number(result.rows[0]?.current_amount ?? 0);
  }
}
