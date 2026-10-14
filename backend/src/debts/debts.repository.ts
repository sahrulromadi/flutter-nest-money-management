import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface Debt {
  id: string;
  user_id: string;
  direction: 'Utang' | 'Piutang';
  counterparty: string;
  amount: string;
  due_date: string | null;
  note: string | null;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

@Injectable()
export class DebtsRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async create(
    userId: string,
    data: {
      direction: 'Utang' | 'Piutang';
      counterparty: string;
      amount: number;
      dueDate?: string | null;
      note?: string | null;
    },
  ): Promise<Debt> {
    const result = await this.pool.query<Debt>(
      `INSERT INTO debts (user_id, direction, counterparty, amount, due_date, note)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [
        userId,
        data.direction,
        data.counterparty,
        data.amount,
        data.dueDate ?? null,
        data.note ?? null,
      ],
    );
    return result.rows[0];
  }

  async findAllByUser(userId: string): Promise<Debt[]> {
    const result = await this.pool.query<Debt>(
      `SELECT * FROM debts WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at`,
      [userId],
    );
    return result.rows;
  }

  async findByIdAndUser(id: string, userId: string): Promise<Debt | null> {
    const result = await this.pool.query<Debt>(
      `SELECT * FROM debts WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return result.rows[0] ?? null;
  }

  async update(
    id: string,
    userId: string,
    data: {
      counterparty?: string;
      amount?: number;
      dueDate?: string | null;
      note?: string | null;
    },
  ): Promise<Debt | null> {
    const result = await this.pool.query<Debt>(
      `UPDATE debts SET
         counterparty = COALESCE($3, counterparty),
         amount = COALESCE($4, amount),
         due_date = COALESCE($5, due_date),
         note = COALESCE($6, note),
         updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING *`,
      [
        id,
        userId,
        data.counterparty ?? null,
        data.amount ?? null,
        data.dueDate ?? null,
        data.note ?? null,
      ],
    );
    return result.rows[0] ?? null;
  }

  async softDelete(id: string, userId: string): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE debts SET deleted_at = now(), updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return (result.rowCount ?? 0) > 0;
  }

  // SUM transaksi yang di-tag ke debt ini (gak peduli Income/Expense — trust client,
  // sama pola kayak goal_id).
  async getCurrentAmount(debtId: string): Promise<number> {
    const result = await this.pool.query<{ current_amount: string }>(
      `SELECT COALESCE(SUM(amount), 0) AS current_amount
       FROM transactions WHERE debt_id = $1 AND deleted_at IS NULL`,
      [debtId],
    );
    return Number(result.rows[0]?.current_amount ?? 0);
  }
}
