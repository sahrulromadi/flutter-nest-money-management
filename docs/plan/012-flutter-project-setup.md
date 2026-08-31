# 012 — Flutter Project Setup & Theme

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: TECH_STACK.md #2 (Flutter, Riverpod, package inti), DESIGN.md (palette Karasuno)

## Context
Mulai project mobile. User cuma pakai Android — project di-scaffold Android-only (gak ada folder `ios/`, `web/`, `windows/`, `linux/`, `macos/`) biar gak berat & gak ada clutter platform yang gak dipake.

## Scope
1. `flutter create --platforms=android --org com.moneymanagement mobile` (di root `mobile/` yang udah ada, kosong) — cuma generate `android/` + `lib/` + `pubspec.yaml`, gak ada folder platform lain
2. `pubspec.yaml` — tambah dependency inti (sesuai TECH_STACK.md):
   - `drift`, `sqlite3_flutter_libs`, `sqlcipher_flutter_libs` (local DB + encryption)
   - `flutter_riverpod` (state management)
   - `dio` (HTTP client)
   - `local_auth`, `flutter_secure_storage` (biometric + secure storage)
   - `go_router` (routing — cocok buat bottom nav + nested route, minim boilerplate dibanding Navigator manual)
   - dev: `build_runner`, `drift_dev`
3. `lib/theme/app_colors.dart` — semua token warna dari DESIGN.md #2-4 (light+dark+semantik) sbg konstanta
4. `lib/theme/app_theme.dart` — `ColorScheme.light()`/`.dark()` manual dari token, `ThemeData` pake `Material 3`
5. `lib/theme/app_semantic_colors.dart` — `ThemeExtension` custom buat income/expense/warning/danger (DESIGN.md #4/#5)
6. `lib/main.dart` — `MaterialApp` minimal, `themeMode: ThemeMode.system` (ikut sistem device, sesuai keputusan), render 1 screen placeholder buat verifikasi tema

## Out of Scope
- Navigasi/routing struktur (plan 014)
- Local DB (plan 013)

## Verification
1. `flutter create` gak generate `ios/`, `web/`, `windows/`, `linux/`, `macos/` — cuma `android/`
2. `flutter run` (emulator/device Android) jalan, nampilin placeholder screen
3. Ganti device ke dark mode → app ikut ganti ke `ColorScheme.dark()` (oranye lebih terang, bg `#121212`)
4. `flutter analyze` clean

## Next
Plan 013 — local database schema (Drift + SQLCipher).
