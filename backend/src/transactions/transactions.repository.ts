import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';
import { QueryTransactionsDto } from './dto/query-transactions.dto';

export interface Transaction {
  id: string;
  user_id: string;
  account_id: string;
  category_id: string | null;
  type: 'Income' | 'Expense' | 'Transfer';
  amount: string;
  transfer_to_account_id: string | null;
  occurred_at: string;
  note: string | null;
  recurring_rule_id: string | null;
  goal_id: string | null;
  debt_id: string | null;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

export interface CreateTransactionData {
  accountId: string;
  type: string;
  amount: number;
  occurredAt: string;
  categoryId?: string | null;
  transferToAccountId?: string | null;
  note?: string | null;
  goalId?: string | null;
  recurringRuleId?: string | null;
}

@Injectable()
export class TransactionsRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async create(
    userId: string,
    data: CreateTransactionData,
  ): Promise<Transaction> {
    const result = await this.pool.query<Transaction>(
      `INSERT INTO transactions
         (user_id, account_id, category_id, type, amount, transfer_to_account_id, occurred_at, note, goal_id, recurring_rule_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        userId,
        data.accountId,
        data.categoryId ?? null,
        data.type,
        data.amount,
        data.transferToAccountId ?? null,
        data.occurredAt,
        data.note ?? null,
        data.goalId ?? null,
        data.recurringRuleId ?? null,
      ],
    );
    return result.rows[0];
  }

  async findAllByUser(
    userId: string,
    filter: QueryTransactionsDto,
  ): Promise<Transaction[]> {
    const result = await this.pool.query<Transaction>(
      `SELECT * FROM transactions
       WHERE user_id = $1 AND deleted_at IS NULL
         AND ($2::uuid IS NULL OR account_id = $2 OR transfer_to_account_id = $2)
         AND ($3::uuid IS NULL OR category_id = $3)
         AND ($4::date IS NULL OR occurred_at >= $4)
         AND ($5::date IS NULL OR occurred_at <= $5)
       ORDER BY occurred_at DESC, created_at DESC`,
      [
        userId,
        filter.accountId ?? null,
        filter.categoryId ?? null,
        filter.from ?? null,
        filter.to ?? null,
      ],
    );
    return result.rows;
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<Transaction | null> {
    const result = await this.pool.query<Transaction>(
      `SELECT * FROM transactions WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return result.rows[0] ?? null;
  }

  async update(
    id: string,
    userId: string,
    data: {
      amount?: number;
      occurredAt?: string;
      categoryId?: string | null;
      note?: string | null;
      goalId?: string | null;
    },
  ): Promise<Transaction | null> {
    const result = await this.pool.query<Transaction>(
      `UPDATE transactions SET
         amount = COALESCE($3, amount),
         occurred_at = COALESCE($4, occurred_at),
         category_id = COALESCE($5, category_id),
         note = COALESCE($6, note),
         goal_id = COALESCE($7, goal_id),
         updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING *`,
      [
        id,
        userId,
        data.amount ?? null,
        data.occurredAt ?? null,
        data.categoryId ?? null,
        data.note ?? null,
        data.goalId ?? null,
      ],
    );
    return result.rows[0] ?? null;
  }

  async softDelete(id: string, userId: string): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE transactions SET deleted_at = now(), updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return (result.rowCount ?? 0) > 0;
  }
}
