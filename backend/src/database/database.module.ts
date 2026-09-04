import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Pool, types } from 'pg';
import { PG_POOL } from './database.constants';

// DATE (OID 1082) balikin string 'YYYY-MM-DD' apa adanya, bukan JS Date —
// kalau di-parse jadi Date, JSON serialize ke UTC bisa geser tanggal
// tergantung timezone server (misal jam 00:00 WIB jadi 17:00 hari sebelumnya di UTC).
types.setTypeParser(types.builtins.DATE, (value: string) => value);

// NUMERIC (OID 1700) default-nya string biar presisi arbitrary gak ilang.
// Semua kolom uang di app ini NUMERIC(18,2) IDR — aman dibaca sbg double
// (jauh di bawah batas presisi float64). parseFloat biar client (Flutter
// `as num`) gak throw "String is not a subtype of num".
// ponytail: kalau nanti butuh presisi > 15 digit signifikan, balik ke string
// dan parse manual di client.
types.setTypeParser(types.builtins.NUMERIC, (value: string) => parseFloat(value));

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: PG_POOL,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        new Pool({ connectionString: config.get<string>('DATABASE_URL') }),
    },
  ],
  exports: [PG_POOL],
})
export class DatabaseModule {}
