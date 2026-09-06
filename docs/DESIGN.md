# Design & Color Palette

Status: Draft v1
Tema: **Karasuno** (Haikyuu!!) — hitam & oranye, motif gagak (crow)

## 1. Prinsip
- Warna tema (hitam/oranye Karasuno) dipakai buat **UI chrome**: app bar, tombol utama, highlight, ikon aktif.
- Warna semantik keuangan (income/expense/warning) **tetap universal** (hijau/merah/amber) — gak ikut tema, biar gak ambigu. User harus bisa langsung baca "ini pemasukan" vs "ini alert", terlepas dari suka/gak suka warnanya.
- Support light & dark mode (Flutter Material 3 `ColorScheme` didefinisikan manual, bukan cuma `fromSeed`, biar warnanya presisi sesuai Karasuno — bukan hasil auto-generate M3 yang bisa melenceng).

## 2. Palette — Light Mode
| Role | Hex | Ket |
|---|---|---|
| Primary | `#F2620D` | Oranye Karasuno (jersey accent, "flightless crow" energy) |
| Primary Container | `#FFE0C7` | Oranye pucat, buat background chip/badge aktif |
| On Primary | `#FFFFFF` | Teks/ikon di atas primary |
| Secondary (Crow Black) | `#1A1A1E` | Hitam jersey, dipake buat teks utama & elemen tegas (bukan pure `#000`, lebih soft) |
| Background | `#FAFAF8` | |
| Surface | `#FFFFFF` | Card, sheet |
| On Background / On Surface | `#1A1A1E` | |
| Outline / Border | `#E4E1DC` | |

## 3. Palette — Dark Mode
| Role | Hex | Ket |
|---|---|---|
| Primary | `#FF7A1F` | Oranye sedikit lebih terang, biar kontras cukup di background gelap |
| Primary Container | `#5C2E0C` | |
| On Primary | `#1A1A1E` | |
| Secondary | `#E8E6E1` | Near-white, ganti peran "hitam jersey" jadi terang di dark mode |
| Background | `#121212` | Crow black — dasar dark mode |
| Surface | `#1E1E1E` | |
| On Background / On Surface | `#F5F5F3` | |
| Outline / Border | `#3A3A3D` | |

## 4. Warna Semantik (sama di light & dark, disesuaikan kontras)
| Role | Light | Dark | Dipake buat |
|---|---|---|---|
| Income / Positive | `#12A150` | `#34D399` | Transaksi pemasukan, goal progress naik |
| Expense / Negative | `#E5484D` | `#F87171` | Transaksi pengeluaran |
| Warning | `#F5A623` | `#FBBF24` | Budget mendekati limit (>80%) |
| Danger | `#DC2626` | `#EF4444` | Budget lewat limit |

## 5. Implementasi Flutter
- Definisikan `ColorScheme.light(...)` dan `ColorScheme.dark(...)` manual pake token di atas (bukan `ColorScheme.fromSeed`), taro di `lib/theme/app_colors.dart` + `lib/theme/app_theme.dart` pas mulai project.
- Warna semantik (income/expense/warning/danger) taro sbg custom `ThemeExtension` biar bisa diakses type-safe lewat `Theme.of(context).extension<AppSemanticColors>()`, konsisten sama pendekatan Material 3 (bukan hardcode warna di tiap widget).

## 6. Layout & Navigasi

Target: Gen Z, gak mau ribet — minim tap ke aksi utama, angka jelas, copy singkat.

### Struktur navigasi
Bottom nav 4 tab + FAB tengah (tombol "+" gede buat quick-add, selalu keliatan di layar manapun):

`Home` — `Akun` — `[+ FAB]` — `Insights` — `More`

- **Home**: dashboard ringkas. Tap row transaksi → edit. "Lihat semua" → histori transaksi full-screen.
- **Akun**: list akun + saldo (paling sering dibuka). (plan 032 — dulu tab ini "Transactions")
- **[+]**: buka halaman penuh tambah transaksi (bukan sheet — biar fokus, gak keganggu konten belakang)
- **Insights**: budget progress + laporan/grafik, selector periode
- **More**: categories, goals, recurring, sync, settings
- **Transactions** (histori lengkap): bukan tab lagi — diakses dari "Lihat semua" di Home (halaman penuh).

### Layout per screen (Rilis 1)

**Home**
- Total saldo (semua akun digabung) — angka gede, paling menonjol di layar
- Snapshot periode ini: income vs expense, 2 angka bersebelahan
- 5 transaksi terakhir + link "Lihat semua" → tab Transactions
- (Rilis 2+) Banner alert kalau ada budget mendekati/lewat limit

**Transactions**
- Filter (akun/kategori/tanggal) collapsed by default — gak makan tempat kalau gak dipake
- List grouped by tanggal (Hari ini/Kemarin/dst), tiap row: ikon kategori, nama, nominal (warna income/expense konsisten), akun
- Swipe kiri = delete, tap = edit
- Infinite scroll

**Add Transaction** (halaman penuh, dari FAB)
- Segmented toggle atas: Expense/Income/Transfer (default Expense — paling sering dipake)
- Input nominal gede di tengah atas (numpad custom, bukan keyboard qwerty)
- Akun (chip selector), kategori (grid ikon, quick-pick), tanggal (default hari ini, tap buat ubah), catatan (optional/collapsed)
- 1 tombol submit full-width di bawah, abis submit langsung balik (gak dipaksa ke Home)

**Insights** (Rilis 2+)
- Selector periode budget (aktif/histori)
- List budget per kategori: progress bar + spent/limit
- Grafik cashflow trend & breakdown kategori — style/warna chart ikutin `dataviz` skill pas dibangun

**More**
- Accounts (list + tambah), Categories (list + tambah), Goals (Rilis 3), **Sync** (tombol manual — sync cuma jalan pas ditekan user, gak ada auto-trigger connectivity/periodic; nampilin "Terakhir sync: ..."), Settings (theme toggle, PIN/biometric, logout)

### Prinsip UX
- FAB selalu keliatan → nambah transaksi max 1 tap dari mana aja
- Angka duit konsisten: hijau=income, merah=expense, di semua screen (sesuai #4)
- Default value pinter: tanggal = hari ini, kategori terakhir dipake muncul duluan di grid
- Swipe gesture buat aksi cepat (delete), gak perlu buka menu
- Copy singkat, gak ada paragraf penjelasan — icon-forward
- Empty state actionable ("Belum ada transaksi" + tombol tambah), bukan sekadar teks kosong
- Feedback instan: optimistic UI + snackbar tipis, gak ada modal blocking buat aksi biasa

## 7. Next
Lanjut scaffold Flutter project (Android-only) pake tema + IA ini.
