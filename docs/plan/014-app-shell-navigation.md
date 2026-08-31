# 014 — App Shell & Navigation

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: DESIGN.md #6 (struktur navigasi)

## Context
Bangun kerangka navigasi sebelum isi tiap fitur — bottom nav 4 tab + FAB tengah, sesuai IA yang udah disepakati. Tab `Insights`/bagian `Goals` di `More` boleh nampilin placeholder "coming soon" dulu (isinya nyusul plan 021/022), yang penting struktur & routing-nya jadi dari awal biar gak perlu re-arsitektur pas nambah fitur.

## Scope
1. `lib/app/router.dart` — `go_router` config: shell route pake `StatefulShellRoute` (biar tiap tab punya navigation stack sendiri), 4 branch (`/home`, `/transactions`, `/insights`, `/more`) + route terpisah `/transactions/add` (full page, bukan nested di shell — sesuai DESIGN.md "halaman penuh")
2. `lib/app/app_shell.dart` — widget `Scaffold` dgn `BottomNavigationBar` (4 item) + `FloatingActionButton` tengah (docked, `FloatingActionButtonLocation.centerDocked`) yang navigate ke `/transactions/add`
3. Placeholder screen tiap tab (`HomeScreen`, `TransactionsScreen`, `InsightsScreen`, `MoreScreen`) — sementara isi teks judul doang, nanti diisi plan-plan berikutnya
4. Update `main.dart` pake `MaterialApp.router`

## Out of Scope
- Isi konten tiap screen (plan 017-019, 021-023)
- Auth guard di routing (plan 015 — abis auth ada, route protection ditambah di sini)

## Verification
1. App buka langsung ke tab Home
2. Tap tiap bottom nav item → pindah tab, state tiap tab kepisah (misal scroll position gak reset kalau pindah2 tab)
3. Tap FAB → buka `/transactions/add` sbg halaman penuh (bukan modal/sheet), back button balik ke tab sebelumnya
4. `flutter analyze` clean

## Next
Plan 015 — auth & app lock (login, PIN, biometric).
