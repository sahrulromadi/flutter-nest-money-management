# Setup Backend — Migrasi & Seed

Doc lain: [PRD](PRD.md) · [Tech Stack](TECH_STACK.md) · [Schema](SCHEMA.md) · [Design](DESIGN.md) · [plan/](plan/)

## Prasyarat

1. Postgres jalan (Docker Compose di root repo):
   ```bash
   docker compose up -d
   ```
   DB: `db_money_management`, user/pass `postgres` / `postgres`, port `5432`.
2. Dependency backend:
   ```bash
   cd backend
   npm install
   ```
3. `backend/.env` ada (copy dari `.env.example`), minimal:
   ```
   DATABASE_URL=postgres://postgres:postgres@localhost:5432/db_money_management
   ```

## Migrasi (`node-pg-migrate`)

Semua dari folder `backend/`.

| Perintah | Fungsi |
|---|---|
| `npm run migrate:up` | Jalanin semua migrasi yang belum ke-apply (urut timestamp). |
| `npm run migrate:down` | Rollback 1 migrasi terakhir. |
| `npm run migrate:create -- <nama>` | Bikin file migrasi SQL baru di `backend/migrations/` (isi `-- Up` / `-- Down` manual). |

Tabel `pgmigrations` di DB nyimpen migrasi mana yang udah jalan. File migrasi = SQL biasa,
timestamp-prefixed, ditulis tangan.

Contoh bikin + jalanin:
```bash
npm run migrate:create -- add-something
# edit backend/migrations/<timestamp>_add-something.sql
npm run migrate:up
```

## Seed

### User (buat login + sync)

```bash
npm run seed:user -- <email> <password>
```
Bikin/overwrite user di tabel `users` (password di-hash argon2). App single-user, jadi cukup 1.
Wajib ada sebelum bisa login dari mobile & sync.

### Akun / dompet

```bash
npm run seed:account -- <email-user> <nama-akun> [saldo-awal]
```
Contoh: `npm run seed:account -- me@example.com "BCA" 500000`

`email-user` harus user yang udah di-seed. `saldo-awal` opsional (default 0).
Berguna buat reset cepat pas test migrasi (wipe DB → `migrate:up` → `seed:user` → `seed:account`).

> Akun juga bisa dibuat langsung dari app (More → Akun → +). Script ini buat setup awal / testing.

## Reset DB dari nol

```bash
docker compose down -v && docker compose up -d   # hapus volume, DB fresh
cd backend
npm run migrate:up
npm run seed:user -- me@example.com rahasia123
npm run seed:account -- me@example.com "Cash" 0
```
