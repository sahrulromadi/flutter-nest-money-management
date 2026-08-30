# 001 — NestJS Project Setup

Status: Done
Sumber: TECH_STACK.md (NestJS + TS, no ORM), SCHEMA.md (DDL sudah ada di `backend/migrations/`)

## Context
`backend/` udah ada `package.json`, migration DDL, `.env.example`, `.gitignore` (dari step DB schema). Belum ada aplikasi NestJS-nya sendiri. Step ini bikin fondasi app: bootstrap, config, koneksi DB (raw `pg`, no ORM), health-check, Swagger docs — sebelum modul fitur (auth, accounts, dst) mulai dibikin.

`backend/` bukan folder kosong lagi (ada `package.json`/`node_modules`/`migrations`), jadi setup NestJS dilakukan manual (install dependency + bikin file config sendiri), bukan `nest new` yang butuh folder kosong.

## Scope
1. **Dependencies (production)**: `@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express`, `@nestjs/config`, `@nestjs/swagger`, `reflect-metadata`, `rxjs`, `class-validator`, `class-transformer`
2. **Dependencies (dev)**: `@nestjs/cli`, `@nestjs/schematics`, `@nestjs/testing`, `typescript`, `ts-node`, `tsconfig-paths`, `@types/node`, `@types/express`, `eslint` + `@typescript-eslint/*`, `prettier`
3. **Config files**: `tsconfig.json`, `tsconfig.build.json`, `nest-cli.json`, `.eslintrc.cjs`, `.prettierrc`
4. **App skeleton**:
   - `src/main.ts` — bootstrap, global `ValidationPipe`, Swagger setup (`/docs`, `/docs-json`)
   - `src/app.module.ts` — root module, `ConfigModule.forRoot({ isGlobal: true })`
   - `src/database/database.module.ts` + `database.provider.ts` — provider `pg.Pool` pake `DATABASE_URL` dari env (global module, dipakai module lain lewat DI, no ORM)
   - `src/health/health.module.ts` + `health.controller.ts` — `GET /health`, query `SELECT 1` ke DB buat verifikasi koneksi
5. **package.json scripts**: `start`, `start:dev` (watch mode), `build`, `lint`

## Out of Scope (belum di step ini)
- Auth module, business modules (accounts/categories/transactions/dst) — menyusul di plan berikutnya (002+)
- Testing setup (Jest) — ditambah pas mulai ada logic yang perlu di-test
- Husky/lint-staged/CI — belum prioritas di tahap ini

## Verification
1. `npm run start:dev` jalan tanpa error
2. `GET /health` return 200 + hasil query DB (butuh Postgres lokal jalan & migration ke-apply — kalau belum ada, dicatat sbg langkah manual sebelum verifikasi ini)
3. `/docs` kebuka, nampilin Swagger UI (kosong dulu, belum ada endpoint fitur)
4. `npm run lint` clean 

## Next
Setelah app skeleton jalan → plan `002` buat auth module (JWT, seed single user, guard).
