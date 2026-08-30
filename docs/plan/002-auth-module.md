# 002 — Auth Module

Status: Done
Sumber: PRD.md (single-user, PIN/biometric di mobile — ini auth API-nya), TECH_STACK.md §3 (JWT access+refresh, argon2, no public registration)

## Context
App single-user, gak ada flow registrasi publik — user di-seed manual ke DB. Auth module ini nyediain login (dapetin JWT) + refresh token, dan guard yang proteksi semua endpoint lain (modul 003+ nanti otomatis ke-protect).

## Scope
1. **Dependencies**: `@nestjs/jwt`, `argon2`
2. **`src/users/users.repository.ts`** — raw SQL, cuma `findByEmail(email)` (dibutuhin buat login; CRUD users lengkap gak perlu krn no registration)
3. **`src/auth/`**:
   - `auth.service.ts` — `login(email, password)`: cek argon2 hash, generate access token (short-lived) + refresh token (long-lived), keduanya JWT stateless (gak disimpen di DB — no revocation list di v1, cukup buat solo-user; upgrade ke DB-backed refresh token kalau nanti butuh logout/revoke)
   - `auth.controller.ts` — `POST /auth/login`, `POST /auth/refresh`
   - `dto/login.dto.ts`, `dto/refresh.dto.ts` — validasi pake `class-validator`
   - `guards/jwt-auth.guard.ts` — custom guard verify `Authorization: Bearer <token>` pake `JwtService` (gak pake Passport — simpel, cukup 1 strategi verifikasi)
   - `decorators/public.decorator.ts` — `@Public()` buat exclude route dari guard (dipakai di `/auth/login`, `/auth/refresh`, `/health`)
4. **Global guard**: daftarin `JwtAuthGuard` sbg `APP_GUARD` di `AppModule` — semua endpoint protected by default, kecuali ditandai `@Public()`
5. **Seed script**: `scripts/seed-user.ts` — jalan via `ts-node`, terima email+password dari argv, hash pake argon2, insert ke tabel `users`. Cara ini yang gantiin "registration flow" (PRD: no public registration)
6. **Env vars baru** (tambah ke `.env.example`): `JWT_ACCESS_SECRET`, `JWT_ACCESS_EXPIRES_IN` (misal `15m`), `JWT_REFRESH_SECRET`, `JWT_REFRESH_EXPIRES_IN` (misal `30d`)
7. **Swagger**: `@ApiBearerAuth()` di controller yang protected

## Out of Scope
- Logout/revoke token (butuh DB-backed refresh token — backlog kalau kepake)
- Password reset/change (belum ada kebutuhan, single-user, bisa reset manual lewat DB/script kalau lupa)

## Verification
1. Jalanin seed script → 1 user kebuat di DB
2. `POST /auth/login` email+password bener → 200, dapet `accessToken` + `refreshToken`
3. `POST /auth/login` password salah → 401
4. `GET /health` tanpa token → tetep 200 (`@Public()`)
5. Endpoint lain tanpa token → 401 (belum ada route protected selain auth/health yang sengaja public — diverifikasi ulang pas plan 003, endpoint `accounts` pertama yang beneran protected)
6. `POST /auth/refresh` pake refresh token valid → 200, dapet access token baru
7. `npm run lint` clean, `npx nest build` sukses

## Next
Plan `003` — modul `accounts` (CRUD dompet, pattern controller/service/repository, protected by JwtAuthGuard).
