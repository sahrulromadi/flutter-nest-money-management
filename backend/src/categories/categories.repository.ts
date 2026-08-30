import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface Category {
  id: string;
  user_id: string;
  name: string;
  type: 'Income' | 'Expense';
  parent_id: string | null;
  icon: string | null;
  color: string | null;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

@Injectable()
export class CategoriesRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async create(
    userId: string,
    data: {
      name: string;
      type: string;
      parentId?: string | null;
      icon?: string | null;
      color?: string | null;
    },
  ): Promise<Category> {
    const result = await this.pool.query<Category>(
      `INSERT INTO categories (user_id, name, type, parent_id, icon, color)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [
        userId,
        data.name,
        data.type,
        data.parentId ?? null,
        data.icon ?? null,
        data.color ?? null,
      ],
    );
    return result.rows[0];
  }

  async findAllByUser(userId: string, type?: string): Promise<Category[]> {
    const result = await this.pool.query<Category>(
      `SELECT * FROM categories
       WHERE user_id = $1 AND deleted_at IS NULL
         AND ($2::text IS NULL OR type = $2)
       ORDER BY created_at`,
      [userId, type ?? null],
    );
    return result.rows;
  }

  async findByIdAndUser(id: string, userId: string): Promise<Category | null> {
    const result = await this.pool.query<Category>(
      `SELECT * FROM categories WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return result.rows[0] ?? null;
  }

  async update(
    id: string,
    userId: string,
    data: {
      name?: string;
      icon?: string | null;
      color?: string | null;
    },
  ): Promise<Category | null> {
    const result = await this.pool.query<Category>(
      `UPDATE categories SET
         name = COALESCE($3, name),
         icon = COALESCE($4, icon),
         color = COALESCE($5, color),
         updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING *`,
      [id, userId, data.name ?? null, data.icon ?? null, data.color ?? null],
    );
    return result.rows[0] ?? null;
  }

  async softDelete(id: string, userId: string): Promise<boolean> {
    const result = await this.pool.query(
      `UPDATE categories SET deleted_at = now(), updated_at = now()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, userId],
    );
    return (result.rowCount ?? 0) > 0;
  }
}
