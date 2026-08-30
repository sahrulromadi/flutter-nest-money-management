import { BadRequestException, Injectable } from '@nestjs/common';
import { SYNC_TABLES, getSyncTable } from './sync.constants';
import { SyncRepository } from './sync.repository';

@Injectable()
export class SyncService {
  constructor(private readonly syncRepository: SyncRepository) {}

  async push(
    userId: string,
    changes: Record<string, Record<string, unknown>[]>,
  ): Promise<void> {
    const unknownTables = Object.keys(changes).filter(
      (name) => !getSyncTable(name),
    );
    if (unknownTables.length) {
      throw new BadRequestException(
        `Tabel tidak dikenal: ${unknownTables.join(', ')}`,
      );
    }

    // Urutan sesuai dependency FK: parent dulu baru child.
    for (const table of SYNC_TABLES) {
      const rows = changes[table.name];
      if (!rows?.length) continue;
      for (const row of rows) {
        await this.syncRepository.upsert(table, row, userId);
      }
    }
  }

  async pull(
    userId: string,
    since: string | null,
  ): Promise<Record<string, Record<string, unknown>[]>> {
    const result: Record<string, Record<string, unknown>[]> = {};
    for (const table of SYNC_TABLES) {
      result[table.name] = await this.syncRepository.findChangedSince(
        table,
        userId,
        since,
      );
    }
    return result;
  }
}
