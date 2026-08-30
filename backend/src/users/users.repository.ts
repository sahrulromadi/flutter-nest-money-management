import { Inject, Injectable } from '@nestjs/common';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';

export interface User {
  id: string;
  email: string;
  password_hash: string;
}

@Injectable()
export class UsersRepository {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async findByEmail(email: string): Promise<User | null> {
    const result = await this.pool.query<User>(
      'SELECT id, email, password_hash FROM users WHERE email = $1 AND deleted_at IS NULL',
      [email],
    );
    return result.rows[0] ?? null;
  }
}
