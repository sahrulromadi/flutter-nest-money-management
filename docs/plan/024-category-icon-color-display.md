# 024 — Polish Pra-Deploy

Status: Belum dikerjakan
Sumber: kumpulan temuan pemakaian + keputusan user selama sesi coba-coba app

4 item polish yang dikerjain barengan sebelum deploy. Independen satu sama lain — boleh dikerjain terpisah, digabung di sini biar 1 pass review.

- **A** — Tampilkan icon & warna kategori di UI (sekarang disimpen tapi ga kepake)
- **B** — Hapus fitur "reminder catat harian"
- **C** — Enhance halaman Login
- **D** — Tampilkan saldo akun di halaman Transactions

---

## BAGIAN A — Tampilkan Icon & Warna Kategori di UI

### Context
`category_form_screen.dart` (plan 017) udah nyimpen:
- `icon` → `IconData.codePoint` di-`toString()` (mis. `"58732"`)
- `color` → hex `#rrggbb` (dari `_colorChoices`)

Tapi **ga ada satu widget pun yang baca `category.icon` / `category.color`** — grep `category.icon`/`category.color` di `features/` = 0 hasil. Semua tempat masih hardcode `Icon(Icons.label_outline)` atau icon berdasarkan `transaction.type`. Fitur setengah jadi: persist ✓, render ✗.

### Keputusan: simpan INDEX, bukan codePoint
`IconData` dari int dinamis bikin `flutter build` gagal tree-shake icon (harus `--no-tree-shake-icons`). Hindari: simpen **index dari list `_iconChoices`** (const), map balik ke `IconData` const pas render. Tree-shake tetep jalan.

Konsekuensi: `_iconChoices` jadi kontrak stabil — urutan JANGAN diubah, cuma boleh append di akhir. Kasih komentar warning di list-nya.

### Scope
1. `lib/shared/category_visuals.dart` (baru):
   - `const kCategoryIcons = <IconData>[...]` — pindahin `_iconChoices` ke sini, jadiin sumber tunggal
   - `IconData categoryIcon(String? stored)` — parse index, fallback `Icons.label_outline` kalau null/invalid/out-of-range
   - `Color? categoryColor(String? hex)` — parse `#rrggbb`, null kalau invalid
2. `category_form_screen.dart` — `_icon` simpen `index.toString()` bukan `codePoint.toString()`; `_iconChoices`/`_colorChoices` pakai dari `category_visuals.dart`
3. Migrasi data lama: kolom `icon` lama isinya codePoint. Opsi termudah — anggap semua `icon` existing invalid → fallback (data kategori user masih dikit, acceptable). Ga perlu migrasi Drift.
4. Pakai `categoryIcon`/`categoryColor` di:
   - `features/categories/categories_list_screen.dart` — `leading` ListTile (parent + sub)
   - `features/home/home_screen.dart` — row transaksi terakhir (butuh join/lookup category dari `transaction.categoryId`)
   - `features/transactions/transactions_list_screen.dart` — row transaksi (`_TransactionTile.leading`)
   - `features/transactions/transaction_form_screen.dart` — grid picker kategori
5. Row transaksi sekarang icon-nya dari `type` — ganti: kalau ada `categoryId` → icon+warna kategori; kalau transfer/null → fallback icon `type`
6. Butuh cara lookup `Category` by id di UI transaksi — cek `categoriesProvider`/DAO udah expose `watchById` atau map `id->Category`; kalau belum, tambah.

### Out of Scope (A)
- Nambah pilihan icon/warna baru
- Custom color picker (tetep palette terbatas)
- Ganti representasi jadi emoji

---

## BAGIAN B — Hapus Fitur "Reminder Catat Harian"

### Context
PRD Rilis 3 #10 minta 2 reminder: (a) tagihan jatuh tempo dari `recurring_rules`, (b) reminder catat pengeluaran harian kalau belum ada transaksi hari itu. User mutusin **buang (b)** — mengganggu, value rendah. (a) tetep.

Catatan: endpoint backend `GET /reminders/daily-check` **udah gak dipanggil** dari mobile (`reminder_scheduler.dart` cuma jadwalin notif jam 20:00 flat, gak pernah cek `hasTransactionToday`). Jadi ini dead-ish code + toggle UI yang gak ada gunanya.

### Scope — Mobile
1. `lib/data/notifications/notification_service.dart` — hapus `const _dailyChannel` + method `scheduleDailyCheckReminder()`
2. `lib/data/remote/reminders_api.dart` — hapus `hasTransactionToday()` (+ DTO/model terkait kalau ada)
3. `lib/features/reminders/reminder_scheduler.dart` — hapus block `if (_settings.dailyEnabled) { ...scheduleDailyCheckReminder(hour: 20...) }`
4. `lib/features/reminders/reminder_settings.dart` — hapus `_dailyKey`, field `dailyEnabled`, `setDailyEnabled()`, param `dailyEnabled` di ctor + `copyWith`, baris `_load` yang baca `_dailyKey`. `ReminderSettings` tinggal `billsEnabled` — pertimbangin sekalian disederhanain (keputusan pas eksekusi)
5. `lib/features/reminders/reminder_settings_tiles.dart` — hapus `SwitchListTile` "Reminder catat harian" (`Icons.edit_calendar_outlined`). Kalau tinggal 1 toggle, flatten `Column`
6. Cleanup device: sekali pas upgrade, cancel notif harian yang mungkin udah ke-schedule (id `0`). `_plugin.cancel(0)` di `NotificationService.init()`, atau `cancelAll()` lalu re-schedule bills. Keputusan pas eksekusi
7. Sisa key `reminder_daily_enabled` di secure storage — harmless, biarin

### Scope — Backend
8. `src/reminders/reminders.controller.ts` — hapus handler `@Get('daily-check')` + method `dailyCheck`
9. `src/reminders/reminders.service.ts` — hapus `dailyCheck()`
10. `src/reminders/reminders.repository.ts` — hapus `hasTransactionToday()`
11. Modul `reminders` tetep ada (masih ada `upcoming-bills`)

### Scope — Docs
12. Descoping "reminder catat harian" didokumentasiin di plan 024 ini aja. Doc lama (`PRD.md`, plan 011/023) SENGAJA gak diubah — biar histori keputusan asli utuh. Plan 024 yang jadi rujukan revisi.

### Out of Scope (B)
- Ganti daily reminder jadi bentuk lain (streak, weekly digest)
- Hapus dependency `flutter_local_notifications` / `timezone` — masih dipake reminder tagihan

---

## BAGIAN C — Enhance Halaman Login

### Context
`lib/features/auth/login_screen.dart` sekarang polos banget: 2 `TextFormField` + 1 tombol, ga ada identitas visual, ga kena tema Karasuno, error cuma teks merah. First impression app jelek.

### Scope
1. Identitas visual:
   - Logo / nama app "Money Management" di atas form (pakai `mipmap/ic_launcher` atau teks bergaya, warna primary Karasuno)
   - Layout ke-center vertikal, `maxWidth` biar ga melebar di layar gede, padding konsisten
2. Field:
   - Password: tombol toggle show/hide (`suffixIcon` mata)
   - `textInputAction`: email → `next`, password → `done` (submit langsung dari keyboard)
   - Autofill hints (`AutofillHints.username` / `.password`)
   - Email di-`autofocus` pas layar buka
3. Feedback:
   - Error ditaruh di `SnackBar` atau container beralert-style (border + bg tipis pakai `colorScheme.errorContainer`), bukan teks polos
   - Bedain error: gagal jaringan ("Server gak kejangkau, cek koneksi") vs kredensial salah ("Email atau password salah") — cek `DioException.type` (`connectionTimeout`/`connectionError` vs response 401)
4. Tombol "Masuk": full-width, tinggi cukup (48+), state loading udah ada — pertahanin
5. (opsional) Inget email terakhir dipake — simpen di `SharedPreferences`/secure storage, prefill pas balik ke login

### Out of Scope (C)
- Registrasi / lupa password (single-user, no signup — sesuai PRD)
- Social login
- Animasi berlebihan

---

## BAGIAN D — Tampilkan Saldo Akun di Halaman Transactions

### Context
Sekarang:
- **Home** — total saldo gabungan (angka gede) + snapshot income/expense + 5 transaksi terakhir
- **Transactions** — cuma list transaksi grouped by tanggal, ga ada info saldo
- **More → Accounts** — saldo per-akun di trailing tile

User mau **info duit per akun kelihatan di halaman Transactions**. Interpretasi default (konfirmasi/finalisasi pas eksekusi):
- Tambah **header ringkas saldo per akun** di atas list Transactions — row horizontal scroll berisi chip/kartu kecil: nama akun + saldo, plus 1 chip "Semua" nunjukin total gabungan
- Chip nyambung ke **filter akun**: tap chip akun → list transaksi ke-filter ke akun itu, saldo yang ditonjolin = saldo akun itu (`accountBalanceProvider`); tap "Semua" → balik ke semua transaksi + total (`totalBalanceProvider`)
- Reuse provider yang udah ada (`accountBalanceProvider`, `totalBalanceProvider`, `accountsListProvider`) — jangan bikin query baru

### Keputusan yang perlu difinalin pas eksekusi
- Kata "saja" di permintaan user: apakah blok **total saldo gede di Home dihapus** (dipindah full ke Transactions), atau Home tetep punya total + Transactions dapet breakdown per-akun? Default plan ini: **Home tetep**, Transactions dapet breakdown per-akun. Konfirmasi ke user sebelum hapus apa pun dari Home.
- Bentuk visual: chip horizontal-scroll vs `DropdownButton` pemilih akun + 1 angka saldo gede. Default: chip scroll (lebih cepat baca banyak akun sekaligus, sesuai DESIGN.md "angka jelas, minim tap").

### Scope
1. `features/transactions/transactions_list_screen.dart`:
   - Widget baru `_AccountBalanceStrip` di atas `_GroupedList` (di dalam `data:` branch, dan tetep tampil walau list kosong)
   - State filter akun (Riverpod `StateProvider<String?>` atau param ke `transactionsListProvider`) — `null` = semua
   - `transactionsListProvider` udah nerima `TransactionFilter` → pakai field `accountId` yang udah ada, jangan bikin mekanisme baru
2. Pastiin `TransactionFilter` support filter by `accountId` (cek DAO — kemungkinan udah, dipakai dari layar lain)
3. Empty state per-akun: kalau akun kepilih belum ada transaksi → "Belum ada transaksi di akun ini" + tetep tampilin strip saldo

### Out of Scope (D)
- Filter tanggal/kategori di strip yang sama (biarin di filter collapsed existing kalau ada, atau plan lain)
- Grafik saldo per waktu
- Ubah layout Accounts screen di More

---

## Verification (gabungan)
1. `flutter analyze` clean; `flutter build apk --debug` sukses **TANPA** `--no-tree-shake-icons`
2. Backend `npm run build` + lint clean
3. **A**: set icon+warna kategori → muncul di list kategori; bikin transaksi pakai kategori itu → row di Home & Transactions nampilin icon+warna kategori
4. **A**: transaksi transfer (categoryId null) → fallback icon `swap_horiz`, ga crash; kategori tanpa icon/warna → fallback `label_outline`, ga crash
5. **B**: Settings cuma ada toggle "Reminder tagihan jatuh tempo"; `GET /reminders/daily-check` → 404
6. **B**: device yg sebelumnya ke-schedule notif harian → notif jam 8 malam berhenti setelah upgrade; reminder tagihan tetep jalan
7. **C**: halaman login ada identitas visual + toggle password + submit dari keyboard; matiin backend → login nunjukin error "server gak kejangkau" (bukan "password salah"), ga hang
8. **D**: strip saldo per akun tampil di Transactions; tap chip akun → list ke-filter + saldo akun itu yang ditonjolin; tap "Semua" → balik ke semua + total
9. **D**: nothing removed dari Home tanpa konfirmasi user

## Next
Balik ke urutan normal: deployment backend (VPS) + build APK harian.
