# 025 — Logout + Hapus PIN + Redesign Karasuno

Status: Belum dikerjakan
Sumber: keputusan user

3 item. A & B saling nyambung (dua-duanya nyentuh auth flow) — kerjain bareng. C independen, bisa nyusul.

- **A** — Fitur Logout
- **B** — Hapus total fitur PIN / biometric lock
- **C** — Redesign visual mobile: nuansa Haikyuu!! / voli / Karasuno / gagak — termasuk skeleton loading (ganti spinner polos, fix "lingkaran di header"), ilustrasi/gambar per empty & error state, dan enhance header

---

## BAGIAN A — Fitur Logout

### Context
`AuthController.logout()` udah ADA (`features/auth/auth_controller.dart:68`) — clear token, set `state = AuthPhase.loggedOut`. Tapi **gak ada satu tombol pun di UI** yang manggil. `more_screen.dart` gak punya entri logout (komentarnya sendiri ngaku "PIN reset & theme toggle belum masuk plan").

### Scope
1. `features/more/more_screen.dart`:
   - Tambah section paling bawah (setelah `SyncTile`, dipisah `Divider`): `ListTile` "Keluar" (`Icons.logout`, warna `colorScheme.error` biar jelas destruktif)
   - Tap → `showDialog` konfirmasi ("Yakin keluar? Data lokal tetap tersimpan, tinggal login lagi buat sync.") → kalau ya, `ref.read(authControllerProvider.notifier).logout()`
   - `MoreScreen` jadi `ConsumerWidget` (sekarang `StatelessWidget`) biar bisa akses `ref`
2. Setelah `logout()` → `state = loggedOut` → `routerProvider` redirect (udah ada) otomatis lempar ke `/login`. Ga perlu navigasi manual.
3. Cek `logout()`: sekarang cuma `TokenStorage.clearTokens()`. Pastiin ini cukup — data Drift lokal SENGAJA gak dihapus (biar ga perlu re-sync full pas login lagi, single-user). Kasih komentar negasin keputusan itu.
4. (opsional, kalau gampang) Panggil `NotificationService.instance.cancelAll()` pas logout — batalin reminder yang ke-schedule buat user itu.

### Out of Scope (A)
- Revoke refresh token di backend (belum ada endpoint; token bakal expiry sendiri — acceptable buat single-user)
- Hapus data lokal pas logout

---

## BAGIAN B — Hapus Total Fitur PIN / Biometric Lock

### Context
User mutusin PIN/biometric lock (PRD Rilis 1 #4) **dibuang total**. Alasan: single-user, ribet, device udah punya lock sendiri. Auth flow disederhanain jadi: `loading → loggedOut → unlocked`. Habis login langsung kepakai, ga ada gerbang PIN.

### Touchpoint (hasil grep `pin|lock|biometric|local_auth`)
| File | Aksi |
|---|---|
| `features/auth/lock_screen.dart` | **HAPUS file** |
| `features/auth/pin_setup_screen.dart` | **HAPUS file** |
| `features/auth/widgets/pin_pad.dart` | `PinDots` dipakai cuma di lock_screen → hapus. `NumPad` MASIH dipakai `transaction_form_screen.dart` → **pindah** ke `shared/num_pad.dart`, update import di form transaksi |
| `features/auth/auth_state.dart` | Hapus `AuthPhase.locked` & `AuthPhase.needsPinSetup`. Sisa: `loading`, `loggedOut`, `unlocked` |
| `features/auth/auth_controller.dart` | Hapus `setPin`, `unlockWithPin`, `unlockWithBiometric`, `relock`, `_hashPin`. `_init()`: kalau ada token → langsung `state = unlocked` (buang cek `hasPinSet`). `login()`: habis simpan token → `state = unlocked` (buang cabang `needsPinSetup`) |
| `data/remote/token_storage.dart` | Hapus `savePinHash`, `readPinHash`, `hasPinSet`, konstanta `_pinHashKey`. (Sisa key `pin_hash` di device lama — harmless, biarin) |
| `app/router.dart` | Hapus route `/lock` & `/pin-setup`, import `lock_screen`/`pin_setup_screen`, entri di `_authRoutes`. `redirect`: hapus `case needsPinSetup` & `case locked` |
| `main.dart` | Hapus `didChangeAppLifecycleState` → `relock()` (App lifecycle observer bisa dibuang total kalau cuma dipakai itu). Listener `AuthPhase.unlocked` buat refresh reminder → tetap, tapi cek masih relevan (sekarang `unlocked` langsung habis login/cold-start) |
| `features/more/more_screen.dart` | Komentar "PIN reset" — hapus |
| `pubspec.yaml` | Hapus dependency `local_auth` (`local_auth: ^3.0.2`). Cek `flutter_secure_storage` MASIH dipakai (token, db encryption key, reminder settings) → **jangan** dihapus |

### Verifikasi khusus B
- `flutter pub get` bersih setelah `local_auth` dicabut
- `grep -rn "local_auth\|lock_screen\|pin_setup\|AuthPhase.locked\|AuthPhase.needsPinSetup\|relock\|unlockWithPin" lib` → 0 hasil
- Cold start dengan token valid → langsung Home, ga ada layar PIN
- Login → langsung Home
- App di-background lalu dibuka lagi → tetap di Home, ga minta PIN

### Docs (B)
- Descoping PIN didokumentasiin di plan 025 ini. Doc lama (PRD Rilis 1 #4, plan 015-auth-app-lock) **SENGAJA gak diubah** — histori keputusan asli utuh (konsisten sama cara plan 024 handle reminder).

### Out of Scope (B)
- Ganti dgn app-lock lain (pola, password app-level) — kalau nanti mau, plan baru
- Hapus enkripsi DB (SQLCipher) — itu beda hal, tetap ada

---

## BAGIAN C — Redesign Visual: Nuansa Karasuno / Voli / Gagak

### Context
Palette hitam-oranye Karasuno udah ada (`theme/app_colors.dart`, DESIGN.md §2-4) tapi penerapannya masih "Material default rasa oranye" — belum berasa Haikyuu. Target: identitas visual yang kerasa gagak/voli TANPA ngorbanin kejelasan angka duit (warna semantik income/expense TETAP hijau/merah universal, ga diganggu — DESIGN.md §1).

### Prinsip
- Tema Karasuno buat **chrome & aksen**: app bar, FAB, header, empty state, splash/login, kartu, divider
- Angka duit & status keuangan: **tetap netral/semantik**, jangan di-"gagak"-in
- Jangan norak — 1-2 signature move yang konsisten, bukan tempelan gagak di tiap sudut

### Bug yang sekalian dibenerin: "lingkaran di header"
Pas buka Home pertama kali muncul lingkaran spinner di area header. Itu `home_screen.dart:37` — `loading: () => const CircularProgressIndicator()` POLOS (tanpa `Center`/ukuran) di bawah label "Total Saldo", muncul selama `totalBalanceProvider` loading (DB kebuka + query saldo). Diganti skeleton (lihat sub-bagian Skeleton).

### Scope

**0. Skeleton Loading (ganti SEMUA spinner polos)**
Sekarang ada ~22 `CircularProgressIndicator` di 12 file (grep `CircularProgressIndicator` di `features/`) — hampir semua di `.when(loading:)`. Ganti dengan **skeleton placeholder** yang bentuknya niru konten asli, bukan spinner muter.
- `lib/shared/skeleton.dart` (baru):
  - `Skeleton` — box abu rounded dengan animasi shimmer halus (pakai `AnimatedBuilder` + `LinearGradient` bergerak; JANGAN nambah package `shimmer`, cukup ~40 baris). Warna dari `colorScheme.surfaceContainerHighest` → `.outline` opacity rendah, adaptif light/dark.
  - `SkeletonText({width, height})`, `SkeletonCircle({size})`, `SkeletonLine` — primitif
- Per layar bikin skeleton yang niru layout:
  - **Home**: batang lebar buat total saldo (tinggi ~40, lebar ~60%), 2 kotak stat bersebelahan, 5 baris transaksi (circle + 2 garis + garis kanan)
  - **Transactions**: strip saldo → 3 kartu skeleton; list → 6-8 baris tile skeleton grouped
  - **Accounts / Categories / Goals / Recurring / Insights list**: 4-6 baris tile skeleton
  - **Insights chart** (`insights_screen.dart:156` dll): kotak `height:160` dengan shimmer, bukan spinner di tengah
  - **Form (`transaction_form`, `recurring_form`, `budget_form_sheet`)**: chip/field skeleton di posisi yang bener
- Spinner yang BOLEH tetap (bukan skeleton): tombol submit lagi loading (login "Masuk", sync tile) — itu memang indikator aksi, kecilin & kasih warna `onPrimary`. Skeleton cuma buat loading DATA halaman.
- Prinsip: skeleton = layout hantu, no layout shift pas data masuk. Durasi shimmer ~1.2s loop, gerak kiri→kanan.

**1. Tipografi**
- Tambah font display bergaya jersey/atletik buat ANGKA BESAR (total saldo, nominal di form transaksi) — mis. `Oswald` / `Anton` / `Bebas Neue` (condensed, bold, kesan nomor punggung). Sisa teks tetap default (readability).
- Daftar di `pubspec.yaml` `fonts:`, bikin `TextTheme` custom di `app_theme.dart` — `displayLarge/Medium` pakai font jersey, body pakai default.
- Bundel file font di `assets/fonts/` (jangan `google_fonts` runtime-fetch — offline-first, PRD NFR).

**2. Signature visual (pilih 2, konsisten dipakai)**
- **Sayap/feather accent**: garis diagonal / motif bulu tipis di app bar atau header Home (custom painter atau SVG asset), warna primary opacity rendah
- **Garis lapangan voli**: divider & section separator pakai gaya garis lapangan (dobel garis tipis) bukan `Divider` polos
- **Siluet gagak**: 1 tempat aja — splash screen ATAU empty state ilustrasi (gagak terbang, monokrom). Jangan di app bar tiap screen.
- **Sudut kartu tajam** (`BorderRadius` kecil 4-6px, bukan 12+) + border tegas — kesan jersey panel, bukan bubble

**3. Gambar & ilustrasi (perbanyak — ini yang bikin "oke")**
Bundel semua di `assets/img/`, format: SVG (via `flutter_svg`, tambah dep) ATAU PNG @1x/@2x/@3x monokrom biar bisa di-tint. Lisensi bebas-pakai (undraw.co style / bikin sendiri / CC0).
- **Login/Splash hero**: ilustrasi gagak terbang di atas net voli, atau bola voli + sayap. Gede, jadi fokus atas layar.
- **Empty state per fitur** (masing-masing beda, jangan 1 gambar dipakai semua):
  - Transactions kosong → gagak nangkring di net, "Belum ada rally"
  - Accounts kosong → dompet/jersey kosong
  - Categories kosong → papan taktik voli kosong
  - Goals kosong → bola voli menuju ring/target
  - Recurring kosong → peluit + kalender
  - Insights (belum ada periode budget) → scoreboard kosong
- **Header Home**: motif bulu/sayap samar sebagai background di belakang angka saldo (opacity 6-10%, primary color).
- **Error state**: 1 ilustrasi gagak "jatuh"/bingung + tombol "Coba lagi" — dipakai di `.when(error:)` gantiin `Text('Error: $e')` yang sekarang.
- **Section header** (opsional): ikon kecil bergaya buat tiap section di More.
- Semua ilustrasi: 2 varian warna atau 1 varian yang jalan di light & dark (tint via `ColorFilter`), test dua-duanya.
- Bikin `lib/shared/app_illustration.dart` — enum + widget wrapper (`AppIllustration.emptyTransactions`) biar konsisten ukuran/tint, gampang dipakai ulang.

**4. Per-screen**
- **Login** (abis plan 024): ganti icon wallet generik → hero ilustrasi gagak + wordmark bergaya + tagline pendek ("Fly high." / "Catat, kontrol, terbang."). Background hitam crow dengan aksen oranye tipis / motif bulu.
- **Home**: total saldo pakai font jersey gede + label kecil di atasnya kayak scoreboard, motif sayap samar di belakang. Snapshot income/expense jadi 2 "skor" bersebelahan dengan garis pemisah gaya lapangan.
- **Bottom nav + FAB**: FAB udah oranye. Tambah: ikon nav aktif dikasih underline tebal (garis lapangan). FAB "+" pertimbangkan ikon bulu tipis (opsional, hati-hati norak).
- **Empty states**: pakai `AppIllustration` + copy bertema (lihat list di atas), bukan teks polos.
- **App bar**: warna solid crow black (dark) / oranye (light), judul bold jersey. Garis oranye tipis di bawah app bar (kesan garis lapangan).

**5. Header enhance (khusus, diminta user)**
Header = area atas tiap layar (app bar + baris pertama konten). Sekarang app bar Material polos + konten langsung nempel.
- **Home**: ganti app bar biasa jadi header custom (`SliverAppBar` expanded ~140px ATAU `Container` header):
  - Baris atas: sapaan / nama app kecil + ikon (sync status? notif?)
  - Tengah: "TOTAL SALDO" label uppercase spaced + angka jersey gede
  - Background: gradient crow-black → primary tipis, ATAU motif bulu/sayap SVG opacity rendah
  - Nyusut jadi app bar biasa pas di-scroll (kalau pakai Sliver)
- **Transactions**: header tipis judul + strip saldo akun (plan 024) nempel jadi satu blok, kasih background surface beda tipis biar kepisah dari list
- **Layar list lain (Accounts/Categories/dst)**: app bar konsisten — warna solid tema, judul bold, garis bawah oranye tipis
- Bikin `lib/shared/app_header.dart` kalau polanya berulang — 1 widget header reusable
- Wajib: header ga makan tempat berlebih di layar kecil, aman di notch/status bar (`SafeArea`), light+dark dua-duanya kontras

**4. Microcopy (ringan, opsional)**
- Istilah voli buat aksi tertentu kalau pas: "rally" (aktivitas), "serve" (mulai periode budget), "receive" (terima pemasukan). JANGAN maksa — cuma di empty state / judul section, bukan di label tombol utama.

### Aset yang perlu disiapin
- Font jersey (`.ttf`, lisensi OFL: Oswald/Anton/Bebas Neue) → `assets/fonts/`
- Ilustrasi → `assets/img/` (SVG kalau pakai `flutter_svg`, atau PNG @1/2/3x):
  - hero login (gagak + net/voli)
  - 6 empty state (transactions, accounts, categories, goals, recurring, insights) — masing2 beda
  - 1 error state (gagak bingung)
  - motif bulu/sayap buat background header (tileable atau 1 gede opacity rendah)
- Dep baru (kalau pakai SVG): `flutter_svg` — 1 package, worth it buat tint + ukuran fleksibel. Kalau mau nol dep: PNG multi-res.
- Daftar SEMUA font & img di `pubspec.yaml` (`fonts:` + `assets:`)

### Out of Scope (C)
- Animasi kompleks (gagak terbang animated, parallax) — v2 kalau sempat
- Ganti struktur navigasi / IA (tetap 4 tab + FAB, DESIGN.md §6)
- Ubah warna semantik keuangan (hijau/merah/amber) — HARAM diganggu
- Dark/light: dua-duanya tetap didukung, redesign kena dua-duanya

### Verifikasi (C)
- Skeleton: buka tiap layar dgn DB/backend lambat (matiin backend / throttle) → yang muncul skeleton berbentuk konten, BUKAN spinner muter; ga ada layout shift pas data masuk
- "Lingkaran di header Home" hilang — diganti skeleton batang saldo
- Light & dark dua-duanya rapi, kontras teks lolos (WCAG AA buat teks penting)
- Angka income tetap hijau, expense tetap merah, di semua screen
- Ilustrasi ke-tint bener di light & dark (ga ada gambar item di background gelap / putih di background terang)
- `flutter build apk --debug` sukses (font & asset ke-bundle, bukan runtime fetch)
- Screenshot before/after: Home, Login, 1 empty state, 1 loading state

---

## Verifikasi Gabungan
1. `flutter analyze` clean, `flutter build apk --debug` sukses
2. Backend `npm run build` clean (bagian B ga nyentuh backend, tapi cek regресi)
3. Logout: More → Keluar → konfirmasi → balik ke login; login lagi → data lokal masih ada
4. PIN: cold start / login / resume dari background → langsung Home, ga ada layar PIN di mana pun
5. `grep` PIN/local_auth di `lib` → 0
6. Visual: Home & Login berasa Karasuno, angka duit tetap netral, dark+light dua-duanya oke
7. Loading: ga ada spinner polos di loading data halaman — semua skeleton. "Lingkaran di header" ilang.
8. Tiap empty state punya ilustrasi sendiri; error state ada ilustrasi + tombol "Coba lagi"
9. Header Home ke-enhance (scoreboard style, motif sayap), header layar lain konsisten

## Next
Deploy backend (VPS) + build APK rilis buat pemakaian harian.
