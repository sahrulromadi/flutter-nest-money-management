# PRD: Aplikasi Manajemen Keuangan Pribadi

Status: Draft v2
Sumber: hasil brainstorming (lihat plan file sesi ini)

## 1. Problem Statement
User butuh cara mencatat & mengelola keuangan pribadi (pemasukan, pengeluaran, budget, tabungan) tanpa bergantung penuh pada aplikasi pihak ketiga — karena kontrol privasi data dan fleksibilitas fitur jadi prioritas. Aplikasi ini juga jadi sarana belajar development.

Masalah spesifik dengan app existing (Money Lover, Wallet, dll):
- Data finansial tersimpan di server pihak ketiga yang tidak sepenuhnya dikontrol user.
- Budget period fixed bulanan-kalender — tidak cocok karena tanggal gajian user tidak tetap tiap bulan.
- Fitur generik/berlebihan, tidak fleksibel sesuai kebiasaan pencatatan user sendiri.

## 2. Goals & Success Metrics
| Goal | Ukuran keberhasilan |
|---|---|
| Privasi & kontrol data | Data sensitif tidak pernah dikirim ke third-party service selain backend milik sendiri |
| App benar-benar dipakai harian | User mencatat transaksi minimal 1x/hari tanpa merasa ribet (bukan cuma dipakai minggu pertama lalu ditinggal) |
| Budgeting sesuai pola gajian nyata | Budget period bisa disesuaikan manual per siklus gajian, bukan dipaksa ke kalender bulanan |
| Belajar & portfolio | Codebase rapi, terdokumentasi, bisa dipakai sbg referensi/portfolio |

## 3. Target User
Solo user (pemilik aplikasi sendiri). Tidak ada kebutuhan multi-tenant/multi-user, tidak ada role/permission system.

## 4. Platform & Data Model

### Platform
Mobile (Android/iOS). Data local-first (SQLite di device) + sync ke backend cloud milik sendiri. App tetap fungsional penuh offline; sync terjadi otomatis saat online, conflict resolution: last-write-wins berdasarkan timestamp (cukup untuk single-user, no concurrent-edit scenario).

### Entitas Data Inti
- **Account (Dompet)**: id, nama, tipe (bank/e-wallet/cash), saldo awal, saldo berjalan (calculated), currency (IDR fixed v1)
- **Category**: id, nama, tipe (income/expense), parent_id (nullable, buat subkategori), icon/warna, is_custom (bool)
- **Transaction**: id, account_id, category_id, tipe (income/expense/transfer), nominal, tanggal, catatan, is_recurring_generated (bool)
- **BudgetPeriod**: id, tanggal_mulai, tanggal_selesai (nullable — null berarti periode aktif berjalan), dibuat manual oleh user saat gajian cair
- **Budget**: id, budget_period_id, category_id, limit_nominal
- **RecurringRule**: id, template transaksi (account, category, nominal, catatan), interval (harian/mingguan/bulanan/custom hari), tanggal_mulai, tanggal_berikutnya
- **Goal**: id, nama, target_nominal, saldo_terkumpul, tenggat (nullable), account_id terkait (opsional, kalau nabung di akun spesifik)

## 5. Scope & User Stories — Rilis Bertahap

### Rilis 1 (MVP)
Fokus: bisa dipakai catat transaksi harian secara nyata, dengan keamanan dasar.

1. **Catat transaksi**
   - Sebagai user, saya bisa tambah transaksi pemasukan/pengeluaran dengan nominal, akun, kategori, tanggal, catatan.
   - Acceptance: transaksi baru langsung update saldo akun terkait secara instan (optimistic, tanpa nunggu sync).
2. **Multi akun/dompet**
   - Sebagai user, saya bisa buat beberapa akun (bank, e-wallet, cash) dengan saldo awal masing-masing.
   - Acceptance: total saldo semua akun terlihat di home screen; saldo per akun bisa dilihat terpisah.
3. **Kategori custom**
   - Sebagai user, saya bisa pilih dari kategori predefined atau buat kategori/subkategori baru.
   - Acceptance: kategori custom tersimpan & muncul di pilihan kategori transaksi berikutnya.
4. **PIN/biometric lock**
   - Sebagai user, app saya terkunci PIN/fingerprint/face unlock saat dibuka.
   - Acceptance: app tidak bisa diakses tanpa autentikasi; ada fallback PIN kalau biometric gagal/tidak tersedia.
5. **Sync local ↔ cloud dasar**
   - Sebagai user, data saya tetap ada meskipun ganti device, karena ke-sync ke cloud pribadi.
   - Acceptance: transaksi yang dibuat offline ter-sync otomatis begitu online, tanpa duplikasi.

### Rilis 2
Fokus: kontrol budget sesuai pola gajian nyata + visibilitas kondisi keuangan.

6. **Budget period custom (manual)**
   - Sebagai user, saya bisa mulai "periode budget baru" manual (misal saat gajian cair), dengan menandai tanggal mulai.
   - Periode sebelumnya otomatis ditutup (tanggal_selesai = tanggal_mulai periode baru - 1 hari).
   - Acceptance: histori periode budget sebelumnya tetap bisa dilihat (read-only) untuk evaluasi.
7. **Budgeting per kategori**
   - Sebagai user, saya bisa set limit nominal per kategori untuk periode budget yang sedang aktif.
   - Acceptance: ada indikator visual (progress bar/warna) saat pengeluaran kategori mendekati (>80%) atau melewati limit; notifikasi saat limit terlampaui.
8. **Dashboard laporan & grafik**
   - Sebagai user, saya bisa lihat trend cashflow (in/out) & breakdown pengeluaran per kategori untuk periode budget aktif atau periode lalu.
   - Acceptance: grafik minimal: pie/bar breakdown per kategori, line/bar trend harian dalam periode berjalan.

### Rilis 3
Fokus: otomatisasi & habit-forming.

9. **Recurring transaction**
   - Sebagai user, saya bisa set transaksi berulang (gaji, tagihan, subscription) yang auto-tercatat sesuai interval.
   - Acceptance: transaksi recurring yang sudah di-generate ditandai berbeda dari manual (bisa diedit/dihapus per-instance tanpa ganggu rule-nya).
10. **Reminder/notifikasi**
    - Sebagai user, saya dapat notifikasi tagihan jatuh tempo (dari recurring rule) & reminder catat pengeluaran harian kalau belum ada transaksi tercatat hari itu.
    - Acceptance: reminder bisa di-disable per jenis dari settings.
11. **Goals/target nabung**
    - Sebagai user, saya bisa set target tabungan dengan nominal & tenggat, lalu track progress.
    - Acceptance: progress terupdate otomatis kalau ada transaksi yang ditandai kontribusi ke goal tsb (manual tag, bukan auto-detect).

### Backlog (belum dijadwalkan, revisit setelah Rilis 1-3 stabil)
- Multi-currency (kalau ada kebutuhan akun mata uang asing)
- Import mutasi bank (CSV) & export laporan (Excel/PDF)

## 6. Non-Functional Requirements
- **Privasi**: data sensitif (saldo, transaksi, catatan) tidak boleh dikirim ke third-party analytics/crash-reporting/tracking apa pun. Kalaupun pakai crash reporting, harus di-scrub dari data finansial.
- **Offline-first**: fitur inti (catat transaksi, lihat saldo, lihat laporan periode aktif) harus tetap jalan 100% tanpa koneksi internet.
- **Keamanan**: app terkunci PIN/biometric; data at-rest terenkripsi di device (SQLCipher atau setara); komunikasi ke backend via HTTPS/TLS.
- **Performa**: input transaksi terasa instan (<100ms UI feedback) meskipun sync ke cloud belum selesai (optimistic UI + background sync).
- **Reliabilitas sync**: kalau sync gagal (network error dll), data lokal tidak boleh hilang — retry otomatis saat online lagi.

## 7. Assumptions (default yang diambil, bisa direvisi)
| Topik | Keputusan default | Alasan |
|---|---|---|
| Mata uang | IDR only di v1 | User berbasis Indonesia, multi-currency nambah kompleksitas tanpa kebutuhan jelas saat ini |
| Kategori | Predefined + custom | Selaras dengan motivasi "fitur existing kurang fleksibel" |
| Budget period | Custom, manual-set per periode | Gajian tidak tetap tiap bulan — user set tanggal mulai periode sendiri tiap kali gajian cair |
| PIN/biometric | Masuk Rilis 1 | Data finansial sensitif, selaras goal privasi |
| Import/export | Backlog | Bukan blocker untuk mulai pakai app sehari-hari |
| Conflict resolution sync | Last-write-wins by timestamp | Single-user, tidak ada concurrent edit dari device berbeda di waktu bersamaan secara realistis |
| Goal contribution tracking | Manual tag per transaksi | Auto-detect kontribusi ke goal terlalu kompleks & rawan salah tebak untuk v1 |

## 8. Out of Scope (v1 dan seterusnya, kecuali direvisi)
- Multi-user / shared account
- Integrasi langsung ke API bank (open banking)
- Investasi/portfolio tracking
- Web/desktop client (mobile only)

## 9. Edge Cases & Hal yang Perlu Diperhatikan Saat Development
- Transaksi transfer antar akun sendiri (misal dari bank ke e-wallet) — perlu tipe transaksi khusus supaya tidak dobel-hitung sbg income & expense terpisah.
- Kategori yang dihapus tapi masih dipakai transaksi lama — soft-delete, jangan hard-delete supaya histori tidak rusak.
- Budget period baru dimulai di tengah bulan — laporan bulanan kalender (kalau ada) harus tetap bisa cross-reference ke periode custom.
- Recurring rule yang tanggal jatuh temponya di luar tanggal valid (misal tanggal 31 tapi bulan depan cuma 30 hari) — perlu aturan fallback (misal jatuh ke tanggal terakhir bulan itu).
- Sync konflik saat app dibuka di 2 device offline lalu online bersamaan — perlu strategi (default: last-write-wins, lihat #7).

## 10. Next
Lanjut ke tahap **Tech Stack** — pilih stack mobile, local DB, backend/sync service, dan strategi auth/security.
