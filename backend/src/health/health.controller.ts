import { Controller, Get, Inject } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Pool } from 'pg';
import { PG_POOL } from '../database/database.constants';
import { Public } from '../auth/decorators/public.decorator';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Public()
  @Get()
  async check() {
    await this.pool.query('SELECT 1');
    return { status: 'ok' };
  }
}
