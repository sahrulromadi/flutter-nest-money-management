import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface Account {
  id: string;
  user_id: string;
  name: string;
  initial_balance: string;
  currency: string;
  sort_order: number;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

@Injectable()
export class AccountsRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async create(
    userId: string,
    data: { name: string; initialBalance: number },
  ): Promise<Account> {
    const result = await this.pool.query<Account>(
      `INSERT INTO accounts (user_id, name, initial_balance)
       VALUES ($1, $2, $3) RETURNING *`,
      [userId, data.name, data.initialBalance],
    );
    return result.rows[0];
  }

  async findAllByUser(userId: string): Promise<Account[]> {
    const result = await this.pool.query<Account>(
      `SELECT * FROM accounts WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY sort_order ASC, created_at ASC`,
      [userId],
    );
    return result.rows;
  }

  async findByIdAndUser(id: string, userId: string): Promise<Account | null> {
    const result = await this.pool.query<Account>(
      `SELECT * FROM accounts WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return result.rows[0] ?? null;
  }

  async update(
    id: string,
    userId: string,
    data: { name?: string; sortOrder?: number | null },
  ): Promise<Account | null> {
    const result = await this.pool.query<Account>(
      `UPDATE accounts SET
         name = COALESCE($3, name),
         sort_order = COALESCE($4, sort_order),
         updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING *`,
      [id, userId, data.name ?? null, data.sortOrder ?? null],
    );
    return result.rows[0] ?? null;
  }

  async softDelete(id: string, userId: string): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE accounts SET deleted_at = now(), updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return (result.rowCount ?? 0) > 0;
  }

  async getBalance(accountId: string): Promise<number> {
    const result = await this.pool.query<{ balance: string }>(
      `SELECT
         a.initial_balance
         + COALESCE(SUM(CASE
             WHEN t.account_id = a.id AND t.type = 'Income' THEN t.amount
             WHEN t.account_id = a.id AND t.type IN ('Expense', 'Transfer') THEN -t.amount
             WHEN t.transfer_to_account_id = a.id AND t.type = 'Transfer' THEN t.amount
             ELSE 0
           END), 0) AS balance
       FROM accounts a
       LEFT JOIN transactions t
         ON (t.account_id = a.id OR t.transfer_to_account_id = a.id)
         AND t.deleted_at IS NULL
       WHERE a.id = $1
       GROUP BY a.id`,
      [accountId],
    );
    return Number(result.rows[0]?.balance ?? 0);
  }
}
