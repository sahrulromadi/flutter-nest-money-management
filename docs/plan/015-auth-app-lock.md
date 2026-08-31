# 015 — Auth & App Lock

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: PRD.md #5 Rilis 1 (PIN/biometric lock), TECH_STACK.md #2 (`local_auth`, `flutter_secure_storage`, `dio`)

## Context
Login ke backend (dapet JWT) sekali di awal, abis itu app dikunci PIN/biometric tiap dibuka (bukan login ulang tiap kali — sesuai PRD, single-user app). Token disimpen di secure storage, dio otomatis refresh token yang expired.

## Scope
1. `lib/data/remote/api_client.dart` — `Dio` instance + interceptor: attach `Authorization: Bearer` dari secure storage, auto-refresh via `POST /auth/refresh` kalau kena 401, retry request asli
2. `lib/data/remote/auth_api.dart` — `login(email, password)`, `refresh(refreshToken)` (panggil backend `/auth/login`, `/auth/refresh` dari plan 002)
3. `lib/features/auth/login_screen.dart` — form email+password, submit → simpen token ke `flutter_secure_storage`, lanjut ke `PinSetupScreen`
4. `lib/features/auth/pin_setup_screen.dart` — set PIN 6 digit pertama kali, hash PIN (bukan plain) disimpen di secure storage
5. `lib/features/auth/lock_screen.dart` — muncul tiap app dibuka (kalau token udah ada): coba biometric dulu (`local_auth`) otomatis, fallback input PIN manual kalau biometric gagal/gak ada/user pilih "pake PIN"
6. `lib/app/router.dart` (update dari plan 014) — redirect logic: belum ada token → `/login`; ada token tapi app baru dibuka/di-resume → `/lock`; udah unlock → tab utama
7. Encryption key DB (plan 013) diikat ke PIN? **Tidak** — key DB tetap random terpisah di secure storage, PIN cuma gerbang UI (secure storage sendiri udah di-encrypt OS-level/keystore), biar simpel & PIN bisa direset tanpa re-encrypt DB

## Out of Scope
- Ganti PIN / lupa PIN flow (backlog, PIN reset manual lewat re-login kalau lupa di v1)
- Multi-device session management (single-user, gak perlu)

## Verification
1. First run → langsung ke `/login`, gak ada token
2. Login sukses → diarahkan set PIN
3. Kill app, buka lagi → `/lock` muncul, coba biometric dulu (kalau device support & udah didaftarin), fallback PIN
4. PIN salah 1x → tetep di lock screen, gak nge-crash
5. Access token expired (simulasi manual, misal set expiry pendek pas testing) → request API tetep sukses krn auto-refresh, user gak ngerasa ke-logout
6. `flutter analyze` clean

## Next
Plan 016 — accounts feature.
