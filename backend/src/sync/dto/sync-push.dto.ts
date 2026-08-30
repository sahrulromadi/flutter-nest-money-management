import { ApiProperty } from '@nestjs/swagger';
import { IsObject } from 'class-validator';
import { SYNC_TABLES } from '../sync.constants';

const TABLE_NAMES = SYNC_TABLES.map((t) => t.name);

export class SyncPushDto {
  @ApiProperty({
    description: `Object keyed by table name (${TABLE_NAMES.join(', ')}), value = array of row objects (kolom snake_case sesuai schema DB)`,
  })
  @IsObject()
  changes!: Record<string, Record<string, unknown>[]>;
}
