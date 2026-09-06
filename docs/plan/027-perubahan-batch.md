# 027 — Perubahan & Penambahan Fitur (Batch)

Status: Draft — dikumpulin dulu, eksekusi nanti setelah semua item masuk
Sumber: permintaan user — beberapa perubahan sekaligus di atas APK yang udah live + data ke-sync ke Postgres

Konteks umum: APK sudah rilis & dipakai. Data lokal (Drift/SQLite terenkripsi) sudah
ke-sync ke Postgres backend. Jadi tiap perubahan schema **wajib** punya jalur migrasi
di dua sisi:
- Backend: file `node-pg-migrate` baru (`npm run migrate:create -- <nama>`), `up` + `down`.
- Mobile: naikin `schemaVersion` Drift + tulis step di `MigrationStrategy.onUpgrade`
  (saat ini `schemaVersion = 1` dan **belum ada** `MigrationStrategy` — perlu ditambah
  pertama kali dipakai).

---

## Item 1 — Buang kolom `type` di accounts

**Alasan**: user gak suka field tipe akun (enum `Bank` / `Ewallet` / `Cash`). Akun cukup
punya nama + saldo awal. Tipe gak dipakai di logika apa pun (balance dihitung dari
`transactions.type`, bukan `accounts.type`) — cuma tampil sebagai ikon + subtitle di list.

### Backend (NestJS + Postgres)
- Migration baru:
  - `up`: `ALTER TABLE accounts DROP COLUMN type;`
  - `down`: `ALTER TABLE accounts ADD COLUMN type TEXT NOT NULL DEFAULT 'Cash' CHECK (type IN ('Bank','Ewallet','Cash'));`
    (default biar row existing gak nolak; rollback murni struktural)
- `backend/src/accounts/dto/create-account.dto.ts` — hapus `ACCOUNT_TYPES` + field `type`.
- `backend/src/accounts/dto/update-account.dto.ts` — hapus `type`.
- `backend/src/accounts/accounts.repository.ts`:
  - hapus `type` dari interface row, `INSERT`, `UPDATE` (`COALESCE` param geser), param array.
  - query `getBalance` gak kena (pakai `t.type`, bukan `a.type`).
- `backend/src/accounts/accounts.service.ts` — gak ada perubahan (cuma teruskan dto).
- `backend/src/sync/sync.constants.ts` — hapus `'type'` dari `columns` tabel `accounts`
  (index 16). **Urutan deploy**: backend push dulu sebelum mobile yang udah drop kolom,
  atau sync bakal kirim kolom yang gak ada. Aman karena single-user & sync manual.

### Mobile (Flutter + Drift)
- `mobile/lib/data/local/tables/accounts.dart` — hapus getter `type`.
- `mobile/lib/data/local/app_database.dart`:
  - `schemaVersion` → `2`.
  - tambah `MigrationStrategy`:
    - `onCreate`: `m.createAll()`
    - `onUpgrade`: `if (from < 2) await m.alterTable(TableMigration(accounts));`
      (SQLite `DROP COLUMN` via Drift `TableMigration` — recreate tanpa kolom `type`)
- Regenerate: `dart run build_runner build --delete-conflicting-outputs`.
- `mobile/lib/data/repository/accounts_repository.dart` — hapus param `type` di `create` & `update`.
- `mobile/lib/features/accounts/account_form_screen.dart` — hapus `_accountTypes`, `_type`,
  `Wrap`/`ChoiceChip` selector. Form tinggal: nama + (saat create) saldo awal.
- `mobile/lib/features/accounts/accounts_list_screen.dart` — hapus `_typeIcon` switch &
  `subtitle: Text(account.type)`. Ganti leading jadi ikon statis (mis. `Icons.wallet_outlined`)
  atau balance jadi subtitle. Keputusan minor, default: ikon statis.
- `mobile/lib/data/sync/sync_serializers.dart` — hapus `'type'` dari `accountToJson` &
  `type:` dari `accountFromJson`.

### Docs
- `docs/SCHEMA.md` §accounts — hapus baris `type` dari tabel.
- `docs/PRD.md` §4 & §5.2 — sesuaikan (akun gak punya "tipe (bank/e-wallet/cash)" lagi).
- `docs/DESIGN.md` — gak ada referensi tipe akun spesifik, skip.

### Verifikasi
1. Backend: `npm run migrate:up` sukses; `\d accounts` di psql — kolom `type` hilang.
   `npm run migrate:down` balikin kolom. `npm run build` + `npm run lint` clean.
2. Swagger `/docs` — `POST /accounts` body gak minta `type` lagi.
3. Mobile: `flutter analyze` clean; `flutter build apk --debug` sukses.
4. Upgrade in-place (install APK lama → install baru di atasnya, data lokal ada isinya):
   app buka tanpa crash, akun lama tetap muncul dengan saldo benar. **Ini test kritis** —
   pastikan `drift_dev schema` test kalau ada, atau minimal manual di device.
5. Tambah akun baru (nama + saldo) → muncul di list → sync ke Postgres sukses, no error
   kolom `type`.
6. Edit akun lama → nama keganti, saldo utuh.

### Out of Scope item ini
- Ganti `type` jadi field lain (mis. warna/ikon custom per akun) — kalau mau, item terpisah.

---

## Item 2 — Input nominal duit gak friendly di semua form sekunder

**Masalah**: field nominal pakai `TextField`/`TextFormField` biasa + prefill/ketik dari `0`
→ jadi `0546023` (leading zero nyangkut, gak ada pemisah ribuan). Jelek.

**Kena di 4 form** (semua `keyboardType: number`, plain field):
- `account_form_screen.dart` — `_initialBalanceController` (saldo awal)
- `recurring_form_screen.dart` — `_amountController` (nominal aturan berulang) ← user report
- `goal_form_screen.dart` — `_targetController` (target nominal)
- `insights/budget_form_sheet.dart` — `_limitController` (limit nominal)

**Konteks**: form Tambah Transaksi (`transaction_form_screen.dart`) udah bener — pakai
`NumPad` custom (`shared/num_pad.dart`) + `formatRupiah`. Tapi 4 form di atas isinya banyak
field; nempelin numpad gede di tiap-tiap form makan tempat & ubah layout drastis.

### Keputusan
Bikin 1 widget shared **`MoneyField`** (`mobile/lib/shared/money_field.dart`) — wrapper
`TextFormField` + `TextInputFormatter` yang:
- strip semua non-digit, buang leading zero,
- format ribuan pakai locale id (`1.234.567`) live pas ngetik,
- expose `onChanged(int)` / bisa dibaca via controller helper `moneyFieldValue(text)`.
Drop-in ganti 4 field di atas. Keyboard OS numeric tetap (form sekunder, gak perlu numpad).
`transaction_form_screen` **gak diubah** — numpad-nya udah oke (flow utama, sesuai DESIGN.md).

Reuse `formatRupiah` / `NumberFormat` dari `shared/currency_formatter.dart` buat grouping.

### Scope (mobile only, gak nyentuh backend/schema)
- **baru**: `mobile/lib/shared/money_field.dart` — `MoneyField` + parser helper.
- `account_form_screen.dart` — `_initialBalanceController` → `MoneyField`. (field cuma muncul
  pas create, pertahankan.) submit: parse via helper.
- `recurring_form_screen.dart` — `_amountController` → `MoneyField`.
- `goal_form_screen.dart` — `_targetController` → `MoneyField`.
- `insights/budget_form_sheet.dart` — `_limitController` → `MoneyField`.
- Tiap submit: ganti `double.tryParse(controller.text)` → parse digit-only helper.

### Verifikasi
1. `flutter analyze` clean; `flutter build apk --debug` sukses.
2. Tiap form (akun / recurring / goal / budget): ketik `546023` → tampil `546.023`
   (bukan `0546023`), backspace jalan, submit → nilai tersimpan `546023`.
3. Kosongin field → submit → validasi nolak ("wajib diisi") sesuai behavior existing.
4. Edit recurring/goal/budget yang udah ada nominal → field ke-prefill ke-format bener.
5. Transaksi (numpad) → gak berubah, gak regresi.

### Out of Scope
- Ganti numpad transaksi.
- Edit saldo awal akun setelah dibuat.
- Input desimal (semua nominal IDR bulat, sesuai app sekarang).

---

## Item 3 — FAB "+" ngambang di atas keyboard pas ngetik

**Klarifikasi user**: FAB "+" tengah itu **memang harus selalu muncul** (fitur utama,
sesuai DESIGN.md §6). Masalahnya **cuma satu**: pas keyboard OS muncul (mis. ngetik nama
akun), FAB ke-dorong naik nangkring di atas keyboard — jelek.

**Root cause**: `Scaffold` di `AppShell` (`mobile/lib/app/app_shell.dart:20`) pakai default
`resizeToAvoidBottomInset: true`. Default ini bikin Scaffold nyusut ngikutin tinggi keyboard,
dan `FloatingActionButton` (docked di `centerDocked`) ikut naik biar gak ketutupan.

### Keputusan
Set `resizeToAvoidBottomInset: false` di `Scaffold` `AppShell`. Efek: FAB + `BottomAppBar`
diam di posisi bawah layar; pas keyboard muncul, keyboard **nutupin** mereka (bukan ndorong
naik). Begitu keyboard ketutup, FAB balik keliatan. 1 baris.

Form screen (`AccountFormScreen`, `CategoryFormScreen`, dll) punya `Scaffold` sendiri —
`resizeToAvoidBottomInset`-nya independen, konten form tetap ke-scroll/resize normal pas
keyboard muncul. Yang di-`false` cuma shell-nya.

### Scope
Mobile only, 1 file: `mobile/lib/app/app_shell.dart` — tambah
`resizeToAvoidBottomInset: false` di `Scaffold(...)`.

### Verifikasi
1. `flutter analyze` clean; `flutter build apk --debug` sukses.
2. Buka form yang ada input teks + keyboard OS (mis. Tambah Akun → tap "Nama akun"):
   FAB "+" **gak** ngambang di atas keyboard — ke-cover keyboard.
3. Tutup keyboard → FAB "+" & bottom nav balik keliatan di posisi normal.
4. Field form yang lagi di-fokus tetap keliatan (gak ketutup keyboard) — karena form
   pakai Scaffold + scroll sendiri.
5. 4 tab utama tanpa keyboard: FAB + bottom nav normal, gak geser.

### Out of Scope
- Sembunyiin FAB total di layar tertentu (user eksplisit nolak — FAB harus selalu ada).
- Pindah layar form ke route di luar shell.

---

## Item 4 — Ordering kategori (drag di mobile)

**Permintaan**: user mau atur urutan kategori — yang penting ditaruh di atas. Reorder di
mobile **by drag** (tahan & geser).

**Konteks**: sekarang kategori selalu urut `created_at ASC` (backend `findAllByUser`,
Drift `CategoriesDao.watchAll`). `CategoriesListScreen` = `ListView` biasa, parent +
subkategori nested. Transaction form baca list yang sama buat chip kategori — otomatis
ikut urutan baru.

### Keputusan
- Kolom baru `sort_order INTEGER NOT NULL DEFAULT 0` di `categories` (backend + Drift).
- Urutan efektif: `ORDER BY sort_order ASC, created_at ASC` — tie-break `created_at` jaga
  urutan lama stabil sampai user drag pertama kali.
- **Scope drag v1: kategori level atas (parent) aja.** Subkategori ikut urutan insert di
  bawah parent-nya. Reorder subkategori = out of scope (mekanisme sama, bisa nyusul).
- Drag dalam 1 grup: siblings `type` sama & `parent_id` sama. Expense & Income kepisah
  (udah beda tab).
- Reorder = **operasi lokal + sync biasa**. Gak perlu endpoint REST baru: mobile tulis
  `sort_order` baru ke Drift + `pending_sync = true`, sync engine push kaya biasa.
  `updated_at` di-bump → last-write-wins aman.

### Backend (NestJS + Postgres)
- Migration baru:
  - `up`:
    ```sql
    ALTER TABLE categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;
    UPDATE categories c SET sort_order = s.rn - 1
      FROM (SELECT id, row_number() OVER (
              PARTITION BY user_id, type, parent_id ORDER BY created_at
            ) rn FROM categories) s
      WHERE c.id = s.id;
    ```
  - `down`: `ALTER TABLE categories DROP COLUMN sort_order;`
- `backend/src/categories/categories.repository.ts`:
  - `sort_order: number` di interface `Category`.
  - `findAllByUser` → `ORDER BY sort_order ASC, created_at ASC`.
  - `create` INSERT: `sort_order` gak diisi (default 0; kategori baru nyempil di antara
    `sort_order=0`, urut `created_at`). Ceiling diterima — user tinggal drag.
  - `update`: tambah `sort_order = COALESCE($N, sort_order)` + param opsional.
- `backend/src/categories/dto/update-category.dto.ts` — tambah `sortOrder?: number`
  (`@IsOptional() @IsInt() @Min(0)`). Buat edit via REST nanti; sync jalan tanpa ini.
- `backend/src/sync/sync.constants.ts` — tambah `'sort_order'` ke `columns` tabel
  `categories` (push & pull dua-duanya digerakin array ini — 1 baris).

### Mobile (Flutter + Drift)
- `mobile/lib/data/local/tables/categories.dart` — tambah
  `IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();`
- `mobile/lib/data/local/app_database.dart`:
  - naikin `schemaVersion` (lihat **Catatan Eksekusi** — koordinasi sama Item 1).
  - `MigrationStrategy.onUpgrade`: `if (from < N) await m.addColumn(categories, categories.sortOrder);`
- regenerate: `dart run build_runner build --delete-conflicting-outputs`.
- `mobile/lib/data/local/daos/categories_dao.dart`:
  - `watchAll` orderBy → `[sortOrder asc, createdAt asc]`.
  - method baru `reorder(List<String> orderedIds)` — dalam `transaction`, loop index,
    `update` tiap row: `sortOrder = i`, `updatedAt = now`, `pendingSync = true`.
- `mobile/lib/data/repository/categories_repository.dart` — expose `reorder(...)`.
- `mobile/lib/data/sync/sync_serializers.dart`:
  - `categoryToJson` → `'sort_order': c.sortOrder`.
  - `categoryFromJson` → `sortOrder: Value(j['sort_order'] as int? ?? 0)`.
- `mobile/lib/features/categories/categories_list_screen.dart`:
  - `_CategoryTypeList`: parent list jadi `ReorderableListView` (bawaan Flutter, no package).
    Tiap item = tile parent + subkategori-nya (satu blok drag).
  - `onReorder` → hitung urutan id parent baru → `reorder(ids)`. Optimistic (stream Drift
    auto-refresh).
  - drag: long-press default (paling simpel, gak nambah widget).
- `transaction_form_screen.dart` — **gak diubah**, chip kategori otomatis ikut urutan baru.

### Docs
- `docs/SCHEMA.md` §categories — tambah baris `sort_order`.
- `docs/PRD.md` — opsional, sebut kategori bisa di-reorder manual.

### Verifikasi
1. Backend: `migrate:up` → kolom `sort_order` ada, row lama backfill 0..n per grup;
   `GET /categories` urut sesuai. `migrate:down` bersih. `build` + `lint` clean.
2. Mobile: `flutter analyze` clean; `build apk --debug` sukses.
3. Upgrade in-place (data lama): app buka, kategori urutan lama, no crash.
4. Drag kategori "penting" ke atas → pindah langsung (optimistic) → kill app → buka lagi →
   urutan persist.
5. Buka Tambah Transaksi → chip kategori ikut urutan baru.
6. Sync (More → Sync) → `sort_order` masuk Postgres; `GET /categories` match device.
7. Tambah kategori baru → muncul → bisa di-drag.

### Out of Scope
- Reorder subkategori dalam parent.
- Drag lintas tab (Expense ↔ Income).
- Reorder akun (item terpisah kalau mau).
- Endpoint REST khusus reorder (bulk) — sync udah cukup.

---

## Item 5 — Fitur hapus akun & hapus kategori

**Permintaan**: user mau bisa hapus akun & hapus kategori dari app.

**Konteks**: plumbing-nya **udah ada semua**, cuma gak ada UI pemicunya:
- Backend: `DELETE /accounts/:id` & `DELETE /categories/:id` → soft delete (`deleted_at`).
- Mobile: `AccountsRepository.delete(id)` & `CategoriesRepository.delete(id)` → soft delete
  lokal + `pending_sync = true`. Sync engine push `deleted_at`.
- `watchAll` (accounts & categories DAO) udah filter `deleted_at IS NULL` → begitu dihapus,
  langsung ilang dari semua list & picker.

Jadi ini **mobile-only, UI doang** + beberapa guard. Gak ada perubahan schema.

### Keputusan
- Titik hapus: **tombol "Hapus" di form Edit** (`AccountFormScreen` & `CategoryFormScreen`
  mode edit), style destructive (merah, `semantic.danger`), di bawah tombol Simpan.
  Alasan: konsisten dua-duanya, gak bentrok sama `ReorderableListView` kategori (Item 4).
  Swipe-to-delete di list = out of scope (form udah cukup).
- Selalu pakai **confirm dialog** sebelum hapus (aksi ga gampang dibalik dari UI).
- Soft delete only — transaksi historis yang refer ke akun/kategori itu **tetap utuh**.

### Guard: akun

- Sebelum hapus, hitung transaksi kepake akun ini:
  `SELECT count(*) FROM transactions WHERE (account_id = $1 OR transfer_to_account_id = $1) AND deleted_at IS NULL`.
  Kalau > 0 → dialog kasih tau: *"Akun ini dipakai di N transaksi. Transaksi lama tetap
  tersimpan, tapi akun hilang dari daftar & total saldo. Hapus?"*
- Tetap boleh hapus (soft delete). Gak ada blocking.
- DAO baru: `TransactionsDao.countForAccount(id)` (atau reuse existing kalau ada).

### Guard: kategori

- **Cascade subkategori**: hapus parent → subkategori-nya (yang belum kehapus) ikut ke-soft-delete
  dalam 1 transaksi lokal, semua `pending_sync = true`. Kalau nggak, sub jadi orphan
  (`parent_id` nunjuk row kehapus, nested di bawah "kosong").
  - Mobile: `CategoriesDao.softDeleteCascade(id, now)` — `WHERE id = $1 OR parent_id = $1`.
  - Backend `categories.repository.softDelete` → `WHERE (id = $1 OR parent_id = $1) AND user_id = $2`
    (biar hapus via REST juga cascade; sync tetap jalan lewat pending_sync tiap row).
- Warn kalau kepake (kalau gampang, else skip): transaksi (`count` where `category_id = $1`),
  recurring rule, budget. Tampilkan angka di dialog, tetap boleh hapus.

### Tampilan transaksi historis setelah hapus

Row transaksi resolve nama/ikon lewat `accountsListProvider` & `categoriesByIdProvider` yang
dua-duanya filter `deleted_at` → abis hapus, subtitle akun jadi kosong & ikon kategori jadi
generic. Fix biar histori tetap kebaca:
- `CategoriesDao` + `AccountsDao`: method `watchAllIncludingDeleted(userId)` (tanpa filter
  `deleted_at`).
- Provider lookup baru (`accountsByIdProvider`, dan ubah `categoriesByIdProvider`) pakai versi
  include-deleted — **cuma buat lookup map di row transaksi**, bukan buat picker/list.
- Picker (form transaksi, filter, dst) tetap pakai `...ListProvider` yang exclude deleted.

### Scope file (mobile)
- `mobile/lib/data/local/daos/accounts_dao.dart` — `watchAllIncludingDeleted`.
- `mobile/lib/data/local/daos/categories_dao.dart` — `watchAllIncludingDeleted`, `softDeleteCascade`.
- `mobile/lib/data/local/daos/transactions_dao.dart` — `countForAccount`, (opsional) `countForCategory`.
- `mobile/lib/data/repository/accounts_repository.dart` — `watchAllIncludingDeleted`, `txnCount(id)`.
- `mobile/lib/data/repository/categories_repository.dart` — `delete` → cascade; count helper.
- `mobile/lib/features/accounts/accounts_providers.dart` — `accountsByIdProvider` (include deleted).
- `mobile/lib/features/categories/categories_providers.dart` — `categoriesByIdProvider` → include deleted.
- `mobile/lib/features/accounts/account_form_screen.dart` — tombol Hapus (edit mode) + confirm.
- `mobile/lib/features/categories/category_form_screen.dart` — tombol Hapus (edit mode) + confirm.
- `mobile/lib/features/transactions/transactions_list_screen.dart` — `_AccountLabel` pakai
  `accountsByIdProvider` (biar nama akun kehapus tetap muncul).

### Scope file (backend)
- `backend/src/categories/categories.repository.ts` — `softDelete` cascade ke subkategori.
- Sisanya (`DELETE` endpoint, service) udah ada — gak diubah.

### Verifikasi
1. `flutter analyze` clean; `flutter build apk --debug` sukses. Backend `build` + `lint` clean.
2. Edit akun tanpa transaksi → Hapus → confirm → ilang dari list Akun, Home, picker transaksi.
3. Edit akun yang ada transaksinya → Hapus → dialog sebут jumlah transaksi → confirm →
   akun ilang, **transaksi lama masih ada** di list Transactions, subtitle nama akun **tetap
   kebaca** (lewat `accountsByIdProvider`).
4. Hapus kategori parent yang punya sub → parent + semua sub ilang; transaksi lama yang
   pakai kategori itu masih ada, ikon kategori tetap kebaca.
5. Sync (More → Sync) → `deleted_at` kepush ke Postgres; `GET /accounts` & `/categories`
   gak nampilin yang kehapus. Re-pull di device lain → konsisten.
6. Hapus lewat `DELETE /categories/:id` (Swagger) untuk parent → subkategori ikut kehapus di DB.
7. Kategori kehapus gak muncul lagi di chip form Tambah Transaksi & di list (Item 4 reorder).

### Out of Scope
- Hard delete / purge permanen.
- "Restore" akun/kategori yang kehapus (bisa manual di DB kalau kepencet).
- Swipe-to-delete di list akun/kategori.
- Reassign transaksi ke akun/kategori lain sebelum hapus.

---

## Item 6 — Buang icon & warna dari kategori

**Permintaan**: user mau hapus fitur icon + warna di kategori. Kategori jadi teks aja.

**Konteks**: ini **revert** dari plan `024-category-icon-color-display.md`. Kolom
`categories.icon` (index ke `kCategoryIcons`) + `categories.color` (hex `#rrggbb`).
Cek dampak (udah di-grep):
- Chart Insights **gak kepake** — pie/breakdown pakai palet `ChartColors.categorical(index)`,
  bukan `category.color`. `reports.repository` gak select icon/color. **Insights aman.**
- Yang pakai: `category_visuals.dart` (helper), `category_form_screen` (picker icon+warna),
  `categories_list_screen` (leading icon), `home_screen` (~L79-86), `transactions_list_screen`
  (~L289-295, udah ada fallback ikon by-type), `transaction_form_screen` (~L229 chip avatar).

### Backend (NestJS + Postgres)
- Migration baru:
  - `up`: `ALTER TABLE categories DROP COLUMN icon; ALTER TABLE categories DROP COLUMN color;`
  - `down`: `ALTER TABLE categories ADD COLUMN icon TEXT; ALTER TABLE categories ADD COLUMN color TEXT;`
    (nullable, data lama gak balik — rollback struktural aja)
- `categories.repository.ts` — buang `icon`/`color` dari interface `Category`, `INSERT` di
  `create`, `SET` di `update` (param geser).
- `dto/create-category.dto.ts` & `dto/update-category.dto.ts` — buang field `icon`, `color`.
- `sync.constants.ts` — buang `'icon'`, `'color'` dari `columns` tabel `categories`.

### Mobile (Flutter + Drift)
- `mobile/lib/data/local/tables/categories.dart` — hapus getter `icon`, `color`.
- `mobile/lib/data/local/app_database.dart` — bump `schemaVersion`, `onUpgrade`:
  `if (from < N) await m.alterTable(TableMigration(categories));` (recreate tanpa 2 kolom).
- regenerate build_runner.
- **Hapus file** `mobile/lib/shared/category_visuals.dart` (semua isinya khusus kategori:
  `categoryIcon`, `categoryColor`, `kCategoryIcons`, `kCategoryColors`, `categoryColorToHex`).
  Cek gak ada import nyangkut.
- `mobile/lib/data/sync/sync_serializers.dart` — buang `'icon'`/`'color'` dari
  `categoryToJson` & `categoryFromJson`.
- `mobile/lib/features/categories/category_form_screen.dart` — hapus grid picker icon +
  picker warna, state `_icon`/`_color`. Form kategori tinggal: nama + tipe + parent.
- `mobile/lib/features/categories/categories_list_screen.dart` — hapus `leading` icon
  (atau ganti statis `Icons.label_outline`). Default: hapus leading, teks aja.
- `mobile/lib/features/home/home_screen.dart` (~L75-90) — ikon transaksi jadi by-type aja
  (arrow up/down/swap), buang cabang `categoryIcon(cat.icon)`.
- `mobile/lib/features/transactions/transactions_list_screen.dart` — di `_TransactionTile`,
  `leading` jadi murni by-`type` (fallback yang udah ada). Variabel `cat` +
  `categoriesByIdProvider` kemungkinan jadi gak kepake di sini — cek & bersihin.
- `mobile/lib/features/transactions/transaction_form_screen.dart` (~L225-235) — chip kategori
  buang `avatar`, `ChoiceChip(label: Text(c.name), ...)` aja.

### Interaksi dengan item lain
- **Item 5**: `categoriesByIdProvider` (include-deleted, buat lookup ikon di row transaksi)
  kemungkinan gak diperlukan lagi setelah Item 6 — row transaksi gak butuh data kategori
  buat ikon. Kalau Item 5 & 6 dikerjain bareng, skip bagian `categoriesByIdProvider` di Item 5.
  `accountsByIdProvider` (nama akun) tetap perlu.
- **Item 4**: dua-duanya ubah `categories` (schema + sync.constants + serializers + Drift).
  Gabung jadi 1 migration backend & 1 step Drift kalau dikerjain berdekatan.

### Docs
- `docs/SCHEMA.md` §categories — hapus baris `icon`, `color`.
- `docs/plan/024-category-icon-color-display.md` — tambah header "SUPERSEDED oleh 027 Item 6".
- `docs/DESIGN.md` — kalau ada nyebut warna/ikon kategori, sesuaikan.

### Verifikasi
1. Backend `migrate:up`/`down` sukses; `build` + `lint` clean. `GET /categories` gak ada
   field icon/color. `POST /categories` gak nerima-nya.
2. Mobile `flutter analyze` clean (gak ada ref nyangkut ke `category_visuals.dart`);
   `build apk --debug` sukses.
3. Upgrade in-place (data lama ada kategori ber-ikon): app buka, kategori muncul teks,
   no crash.
4. Form kategori: gak ada picker icon/warna. Bikin & edit kategori tetap jalan.
5. List Transactions & Home: ikon transaksi by-type, gak error walau kategori lama "punya" icon.
6. Insights: pie/breakdown kategori **tetap jalan** (warna dari palet chart, bukan kategori).
7. Sync → Postgres kolom icon/color udah gak ada, gak ada error kolom hilang.

### Out of Scope
- Ganti icon/warna kategori jadi mekanisme lain (emoji, dsb).
- Migrasi balik data icon/color yang keburu diisi user (di-drop permanen).

---

## Catatan Eksekusi
- Semua item schema: **backend migrate dulu, deploy, baru mobile**. Single-user + sync manual
  jadi window inkonsistensi gak masalah, tapi tetap urut.
- **Item yang ubah schema `categories`: #4 (add `sort_order`), #6 (drop `icon`+`color`).**
  Plus #1 (drop `accounts.type`). Kalau dikerjain berdekatan → gabung: 1 file migration
  backend per tabel, 1 `onUpgrade` step Drift (`schemaVersion` naik 1x).
- **Drift `schemaVersion` & `MigrationStrategy`**: sekarang `schemaVersion = 1`, belum ada
  `MigrationStrategy`. Item pertama yang jalan **wajib** nambah `MigrationStrategy`
  (`onCreate: m.createAll()`, `onUpgrade` stepwise). Tiap item schema berikut = naikin
  `schemaVersion` + tambah `if (from < N)` block. `drift_dev schema` test kalau sempat.
- Urutan aman kalau kepisah: #1 → v2, #6 → v3, #4 → v4 (atau gabung sesuai eksekusi).
- Tiap item = 1 commit (atau 1 PR) sendiri di branch `development`.
- Setelah semua item kelar → update `docs/plan/` index kalau ada, dan file plan ini di-mark Done.
