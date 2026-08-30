import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';
import { SyncTableConfig } from './sync.constants';

@Injectable()
export class SyncRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async upsert(
    table: SyncTableConfig,
    row: Record<string, unknown>,
    userId: string,
  ): Promise<void> {
    const values = table.columns.map((column) => {
      if (column === 'user_id' && table.hasUserIdColumn) {
        return userId;
      }
      return row[column] ?? null;
    });

    const columnList = table.columns.join(', ');
    const placeholders = table.columns.map((_, i) => `$${i + 1}`).join(', ');
    const updateSet = table.columns
      .filter((c) => c !== 'id')
      .map((c) => `${c} = EXCLUDED.${c}`)
      .join(', ');

    await this.pool.query(
      `INSERT INTO ${table.name} (${columnList})
       VALUES (${placeholders})
       ON CONFLICT (id) DO UPDATE SET ${updateSet}
       WHERE EXCLUDED.updated_at > ${table.name}.updated_at`,
      values,
    );
  }

  async findChangedSince(
    table: SyncTableConfig,
    userId: string,
    since: string | null,
  ): Promise<Record<string, unknown>[]> {
    const result = await this.pool.query<Record<string, unknown>>(
      `SELECT * FROM ${table.name}
       WHERE ($1::timestamptz IS NULL OR updated_at > $1)
         AND ${table.userScopeWhere}
       ORDER BY updated_at`,
      [since, userId],
    );
    return result.rows;
  }
}
