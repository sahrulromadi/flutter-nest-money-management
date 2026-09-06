# 031 — Login: Notifikasi + Server Menang (Wipe Data Lokal)

Status: Draft — belum dikerjakan
Sumber: user. Skenario bahaya: HP udah ada data lokal (mis. data coba-coba tanpa login),
terus login ke akun yang **udah ada datanya di server** → sekarang data lokal ke-push ke
akun itu (merge) → data campur / nabrak.

## Behavior sekarang (yang mau diganti)
`AuthController.login()`:
1. Simpan token.
2. `reassignUserData(localId, serverUserId)` — semua row lokal di-re-tag ke user server,
   `pending_sync = true`.
3. `LocalIdentity.adopt(serverUserId)`.
4. Sync berikutnya: push data lokal → server, pull data server → lokal. **Merge.**

## Keputusan
**Server menang.** Pas login, kalau ada data lokal di bawah `LocalIdentity` (belum pernah
login di device ini):
1. Tampilin **dialog konfirmasi** di layar Login sebelum proses:
   > "Ada data di HP ini yang belum ke akun mana pun. Login bakal **menghapus** data itu
   > dan mengganti dengan data akun `<email>`. Lanjut?"
   > [Batal] [Login & Ganti]
2. **Batal** → login dibatalin, token ga disimpan, tetap logged out.
3. **Login & Ganti** → hapus **semua** data lokal (semua tabel), adopt `serverUserId`,
   simpan token, lalu **pull** dari server (biar data akun langsung muncul).
4. Kalau **ga ada** data lokal → langsung proses (adopt + pull), tanpa dialog.

`reassignUserData` (merge) **dihapus** — ga dipake lagi.

### Kenapa server menang, bukan merge / pilihan
- User minta eksplisit — paling aman, ga ada risiko data nabrak / dobel.
- Data lokal pra-login = biasanya data coba-coba. Kalau beneran mau dijaga, user bisa Batal
  (walau belum ada export — trade-off diterima).

## Scope — Mobile only

### `AppDatabase` (`app_database.dart`)
- Hapus `reassignUserData`.
- Tambah:
  - `Future<bool> hasLocalData(String userId)` — cek ada row (belum deleted) di tabel mana
    pun buat `userId`. (accounts / categories / transactions / goals / recurring_rules /
    periods / budgets). Cukup cek beberapa yang paling mungkin keisi + `OR`.
  - `Future<void> wipeAll()` — `delete()` semua row dari semua tabel, dalam 1 transaksi.
    (encryption key di `flutter_secure_storage` **ga** disentuh.)

### `AuthController` (`auth_controller.dart`)
- `login(email, password)` → tetap, tapi:
  - abis simpan token + decode `serverUserId`:
    - kalau `localId != serverUserId` → `wipeAll()` + `LocalIdentity.adopt(serverUserId)`.
      (dialog udah di layar Login sebelum manggil `login()` — controller ga urus UI.)
  - **jangan** panggil `reassignUserData`.
- Opsi: `login()` trigger sync pull sekali abis sukses (best-effort) biar data akun langsung
  keliatan. Atau serahin ke `main.dart` startup / sync tile. Default: trigger di `login()`
  (`ref.read(syncEngineProvider).sync().catchError((_) {})` — cek nama provider sync).

### `login_screen.dart`
- Sebelum manggil `authController.login(...)`:
  - `final hasData = await ref.read(appDatabaseProvider).hasLocalData(await LocalIdentity.ensure());`
  - kalau `hasData` → `showDialog` konfirmasi (teks di atas). Batal → `return` (ga login).
  - lanjut `login(...)`.
- Loading state pas `login()` jalan (udah ada? cek).

### Cek dampak
- `LocalIdentity.adopt` — masih dipake, ga berubah.
- Flow "belum login, catat data, TERUS login pertama kali biar data kebawa" — **berubah**:
  sekarang data lokal itu ilang (dengan warning). Dokumentasikan di PRD kalau perlu — ini
  keputusan sadar (single-user, server = sumber kebenaran).

## Verifikasi
1. `flutter analyze` clean, test pass.
2. Fresh install, catat 1 akun + beberapa transaksi (tanpa login). Login ke akun server
   yang **kosong** → dialog muncul → "Login & Ganti" → data lokal ilang, app kosong,
   sync pull ga nemu apa-apa. Bikin data baru → sync → masuk akun itu.
3. Fresh install, catat data, login ke akun server yang **udah ada data** → "Login & Ganti"
   → data lokal ilang, data akun muncul (abis pull). Ga ada dobel / campur.
4. Dialog → "Batal" → tetap di layar Login, belum login, data lokal utuh.
5. Fresh install, **langsung** login (belum catat apa-apa) → **ga ada dialog**, langsung
   masuk, pull data akun.
6. Logout → login lagi (device yang udah pernah login, `localId == serverUserId`) →
   **ga ada dialog**, ga ada wipe (data device itu emang punya akun itu).

## Out of Scope
- Export data lokal sebelum wipe.
- Pilihan "merge" (dibuang — server menang aja).
- Multi-akun di 1 device.
- Konfirmasi ulang di logout (logout ga hapus data, cuma clear token — biarin).

## Catatan (dev phase)
APK masih development → tiap ubah schema, uninstall + install ulang. `schemaVersion` Drift
ditahan di `1`, `MigrationStrategy` belum ada (plan 030). Migrasi Drift beneran ditambah
nanti pas ada rilis yang datanya perlu dijaga.
