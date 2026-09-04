# 026 — Setting Server URL di App

Status: Belum dikerjakan
Sumber: keputusan user — backend jalan di laptop (bukan VPS), HP akses via IP LAN. URL server harus bisa diganti dari app tanpa rebuild.

## Context
Sekarang base URL backend hardcoded:
`lib/data/remote/api_config.dart` → `kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000')`.
Ganti network / IP laptop = harus `flutter run --dart-define=...` ulang. Ga praktis buat pemakaian harian (HP dipakai di mana-mana, laptop kadang nyala kadang nggak, IP LAN bisa berubah).

Butuh: field "Server URL" yang diisi user dari HP, kesimpen di device, dipakai semua HTTP call.

## Keputusan
- Simpan di `flutter_secure_storage` (udah dipakai di app), key `server_base_url`.
- **Precedence**: URL tersimpan  >  `--dart-define=API_BASE_URL`  >  `http://localhost:3000` (fallback dev).
- Ganti URL **tidak** auto-logout. Token per-server; kalau user nunjuk backend beda → call bakal 401 → interceptor refresh gagal → `clearTokens()` (flow existing) → user login ulang. Cukup, jangan tambah logika.
- Validasi client-side: harus `http://` atau `https://` + host, port opsional. Tolak string ngasal.
- Trailing slash di-strip pas simpan (biar `${base}/auth/login` gak jadi `//`).

## Scope

### 1. Storage + provider
- `lib/data/remote/server_url.dart` (baru):
  - `ServerUrlStore` — `read()` / `write(String)` / `clear()` ke secure storage
  - `serverUrlProvider` = `NotifierProvider<ServerUrlController, String>` — `build()` load dari storage; kalau null → `kApiBaseUrl` (yang sekarang, dari dart-define/fallback). Expose `set(String)`.
- `api_config.dart`: `kApiBaseUrl` tetap jadi **default/fallback** doang (rename komentarnya). Timeout const tetap.

### 2. Wiring Dio ke URL dinamis
Masalah: `Dio(BaseOptions(baseUrl: ...))` di-set pas construct. Sekarang di-`new` di:
- `AuthApi()` — `lib/data/remote/auth_api.dart`
- `ApiClient({authApi})` — `lib/data/remote/api_client.dart` (juga `new AuthApi()` sendiri kalau `authApi` null)
- Provider: `authApiProvider` (`features/auth/auth_controller.dart`), `apiClientProvider` (`data/remote/api_client_provider.dart`)

Ubah:
- `AuthApi(this._baseUrl)` — terima baseUrl, pakai di `BaseOptions`.
- `ApiClient(this._authApi, {required String baseUrl})` — terima baseUrl + AuthApi (wajib, jangan `new` di dalam).
- `authApiProvider` → `ref.watch(serverUrlProvider)` lalu `AuthApi(url)`.
- `apiClientProvider` → `ref.watch(serverUrlProvider)` + `ref.watch(authApiProvider)` → `ApiClient(authApi, baseUrl: url)`.
- Efek: pas `serverUrlProvider` berubah, Riverpod auto-rebuild `authApiProvider` + `apiClientProvider` + semua yang depend (sync, reminders, insights, dst). Ga perlu invalidate manual.
- Cek `api_client.dart` interceptor `onError` yang manggil `_authApi.refresh(...)` — udah pakai field `_authApi`, aman.

### 3. UI — Settings screen
Belum ada Settings screen (DESIGN.md nyebut ada, tapi cuma logout + reminder toggle yang ke-implement, nyebar di More). Bikin minimal:
- `lib/features/settings/settings_screen.dart` — `ConsumerWidget`, di-push dari More (`ListTile` "Pengaturan", `Icons.settings_outlined`, taruh sebelum "Keluar").
- Isi:
  - Section "Server" — tampil URL aktif + tombol "Ubah" → `AlertDialog` dgn `TextFormField` (prefill URL sekarang, validator format) → simpan via `serverUrlProvider.set()`.
  - Tombol "Test koneksi" — `GET ${url}/health` (cek `backend/src/health` buat path pasti; kemungkinan `/health`), timeout 5 detik. Tampil hasil: ✓ "Backend OK" / ✗ "Ga kejangkau" / ✗ "HTTP <code>". Pakai Dio sekali-pakai, jangan lewat interceptor auth.
  - Note kecil di bawah: "Isi IP LAN laptop, mis. http://192.168.1.10:3000. Laptop & HP harus satu WiFi + backend nyala."
- (opsional, kalau gampang) pindah entri reminder toggle ke sini juga biar Settings ke-konsolidasi. Kalau nambah scope, skip — biarin di More.

### 4. Backend
- Pastiin backend listen `0.0.0.0` bukan `127.0.0.1` — cek `backend/src/main.ts` `app.listen(port)` (default Nest udah `0.0.0.0`, tinggal verifikasi, jangan di-set `'localhost'`).
- Ga ada perubahan kode backend lain.

## Out of Scope
- Multi-profile / multi-server (simpen banyak URL) — 1 URL cukup
- Auto-discovery (mDNS/bonjour) laptop di LAN — overkill
- HTTPS / cert pinning — HTTP LAN dulu (`usesCleartextTraffic` udah aktif)
- Deploy VPS — dibatalin, TECH_STACK direvisi terpisah (bukan di plan ini)
- Theme toggle di Settings — plan lain

## Verifikasi
1. `flutter analyze` clean, `flutter build apk --debug` sukses
2. Fresh install (belum set URL) → app tetap jalan pakai default `localhost:3000` (via `adb reverse`) — ga regресi dari sekarang
3. Set URL ke IP LAN laptop → "Test koneksi" → ✓ Backend OK
4. Sync (More → Sync) → sukses, data masuk Postgres laptop
5. Set URL ke IP ngaco → sync → gagal cepet (timeout 8 dtk) dengan error jelas, ga hang
6. Set URL format salah ("halo", "ftp://x") → ditolak di dialog, ga kesimpen
7. Restart app → URL yang disimpan kepakai lagi (persist)
8. `--dart-define=API_BASE_URL=...` pas ga ada URL tersimpan → dipakai sbg default

## Next
Revisi `docs/TECH_STACK.md` §5 (hosting) — VPS/Caddy jadi opsional/backlog, default: backend jalan di laptop, akses LAN. (Plan/PR terpisah, doc-only.)
