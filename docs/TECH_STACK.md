# Tech Stack: Aplikasi Manajemen Keuangan Pribadi

Status: Draft v3
Sumber: keputusan tech stack (lihat PRD.md untuk requirement)

## 1. Ringkasan Stack

| Layer | Pilihan |
|---|---|
| Mobile | Flutter (Dart) |
| Local DB (device) | SQLite via **Drift** + SQLCipher (encrypted at rest) |
| App lock | PIN + biometric (`local_auth` + `flutter_secure_storage`) |
| Backend API | **NestJS** (Node.js + TypeScript), **tanpa ORM** — raw SQL |
| Backend DB | **PostgreSQL** (self-hosted) |
| DB access (backend) | `pg` (node-postgres) + hand-written SQL + `node-pg-migrate` untuk migration |
| Auth | JWT (access + refresh token) |
| Hosting | VPS + Docker Compose (NestJS + Postgres + reverse proxy) |
| Reverse proxy / TLS | Caddy (auto HTTPS via Let's Encrypt) |
| Sync strategy | Custom, timestamp-based push/pull, last-write-wins (sesuai PRD #7) |
| API docs | `@nestjs/swagger` (OpenAPI) — import/sync ke Postman |

## 2. Mobile — Flutter

Package inti: `drift` (local DB), `sqlcipher_flutter_libs` (enkripsi), `local_auth` (biometric), `flutter_secure_storage` (PIN/key storage), `dio` (HTTP client), **Riverpod** (state management).

### Perbandingan opsi framework mobile
| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| **Flutter (dipilih)** | Single codebase Android+iOS; ekosistem local DB & offline-first matang (Drift, sqflite, Isar); performa dekat native (compile ke native code); hot reload cepat buat iterasi | Ukuran app relatif lebih besar; harus belajar Dart (bahasa baru); package native-specific kadang butuh platform channel manual |
| React Native / Expo | Pakai JS/TS (familiar buat web dev); ekosistem JS raksasa; OTA update lewat Expo | Bridge JS↔native historically lebih lambat (New Architecture udah lebih baik tapi masih overhead); banyak library offline-sync (WatermelonDB) punya learning curve sendiri & kurang aktif maintained dibanding Drift |
| Native (Kotlin + Swift terpisah) | Performa & akses API platform paling maksimal; no abstraction overhead | Harus develop & maintain 2 codebase terpisah; effort 2x buat solo dev side project |

**Alasan pilih Flutter**: cross-platform effort minimal (solo dev, side project santai), ekosistem local-first (Drift) paling matang buat kebutuhan offline-first di PRD, dan selaras keputusan lo buat belajar hal baru.

### Perbandingan opsi local DB (Flutter)
| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| **Drift (dipilih)** | SQL-first (nulis SQL asli, bukan abstraksi ORM) — selaras filosofi "kontrol query penuh"; type-safe generated code; reactive streams (query auto-update ke UI); dukungan SQLCipher resmi | Perlu code-generation step (build_runner) tiap ubah schema; sedikit lebih verbose buat setup awal |
| sqflite (raw) | Paling ringan, langsung wrap SQLite API, gak ada code-gen | Nulis parsing row manual, gak type-safe, gampang typo di kolom |
| Isar / ObjectBox | Performa sangat cepat, NoSQL object-oriented, query builder enak dipakai | Bukan SQL — kalau nanti butuh query kompleks/join, lebih terbatas; skema mental beda dari Postgres di backend (dua bahasa data berbeda) |

**Alasan pilih Drift**: paling konsisten sama backend (sama-sama SQL, sama-sama "gak nyembunyiin query asli"), dan reactive query cocok buat UI yang harus update instan pas ada transaksi baru (NFR performa PRD).

## 3. Backend — NestJS + Postgres (tanpa ORM)

- Query/DB access: `pg` (node-postgres) langsung, raw SQL per query
- Migration: `node-pg-migrate` — SQL langsung, gak generate dari model
- Validation: `class-validator` / `zod` di layer request body
- Auth: JWT (access + refresh token), password di-hash pake `argon2`. Single-user app — no flow registrasi publik.

### Perbandingan opsi framework backend
| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| **NestJS (dipilih)** | Struktur modular jelas (module/controller/service) — bagus buat project yang tumbuh; TypeScript native, tipe konsisten sama Dart di mobile; DI bikin testing lebih gampang | Sedikit lebih "berat"/opinionated dibanding Express polos; ada learning curve decorator & DI kalau belum pernah pakai |
| Express / Fastify (Node) | Minimal, ringan, bebas struktur | Struktur project harus didisiplinin sendiri, gampang berantakan tanpa konvensi jelas di project jangka panjang |
| Go (net/http atau Fiber) | Performa & concurrency terbaik, single binary deploy, resource footprint kecil | Bahasa & ekosistem baru buat dipelajari; development velocity biasanya lebih lambat drpd Node/TS buat CRUD-heavy app |
| Python (FastAPI) | Sangat cepat buat develop, auto API docs, sintaks simpel | Runtime lebih lambat drpd Node/Go; typing gak seketat TS secara default |

**Alasan pilih NestJS**: sesuai keputusan lo, TypeScript-nya selaras sama Dart (strongly-typed di kedua sisi), dan strukturnya bagus buat project yang bakal nambah modul terus (budgets, recurring, goals, dst).

### Perbandingan opsi akses database (ORM vs raw SQL)
| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| **Raw SQL via `pg` (dipilih)** | Kontrol penuh atas query & performa; gak ada "magic" tersembunyi; paling banyak belajar SQL/Postgres | Nulis SQL manual tiap query (lebih verbose); rawan human-error kalau gak hati-hati (SQL injection kalau lupa parameterized query, harus disiplin) |
| ORM (Prisma/TypeORM) | Development cepat, migration otomatis dari schema, type-safety built-in | Query kompleks (join budget+kategori+periode) kadang susah/gak efisien lewat ORM; nambah abstraction layer yang "nyembunyiin" SQL asli — bertentangan sama preferensi lo |
| Query builder (Kysely/Knex) | Type-safe tapi tetep deket ke SQL asli, jalan tengah antara raw & ORM | Tetep ada dependency & sedikit abstraksi; lo udah eksplisit minta "jangan ORM" jadi opsi ini juga di-skip demi konsistensi |

**Alasan pilih raw SQL**: sesuai permintaan eksplisit lo — no ORM.

### API Documentation — Swagger/OpenAPI + Postman
- `@nestjs/swagger` — decorator (`@ApiTags`, `@ApiOperation`, `@ApiResponse`, dll) di tiap controller/DTO, auto-generate spec OpenAPI + Swagger UI (`/docs`) tanpa nulis dokumentasi terpisah manual.
- Spec OpenAPI (`/docs-json`) tinggal di-import ke Postman (File → Import → URL/JSON) → auto jadi Postman Collection lengkap sama request & schema.
- Postman juga bisa "Sync" ke spec URL itu (fitur API definition sync) — kalau endpoint nambah/berubah, collection Postman tinggal di-refresh, gak perlu update manual satu-satu.
- Konsekuensi: harus disiplin nulis decorator Swagger di tiap endpoint baru (gak otomatis kayak ORM-based framework), tapi ini satu-satunya sumber kebenaran dokumentasi API (docs, Swagger UI, Postman semua dari spec yang sama — gak ada drift antar dokumen).

### Migration & Historikal Skema
Backend & local device beda mekanisme migration karena beda constraint (server dikontrol penuh vs device lama mungkin masih ke-install user):

**Backend (Postgres, `node-pg-migrate`)**
- Tiap migration = file SQL bertimestamp (`up`/`down`), ditulis manual.
- Tool bikin tabel `pgmigrations` di DB buat nyimpen migration mana yang udah di-apply.
- `node-pg-migrate up` → jalanin migration baru yang belum tercatat, berurutan sesuai timestamp. `down` buat rollback.

**Local (Flutter, Drift)**
- Drift punya `schemaVersion` (int) di database class.
- Tiap ubah skema → naikin versi, tulis step migration di `onUpgrade` (stepwise dari oldVersion ke newVersion — device lama yang ketinggalan beberapa versi tetap jalanin semua step berurutan).
- Drift punya tool export/verify schema (`drift_dev schema`) — bikin snapshot tiap versi & generate test migration otomatis, biar migration ke-cover test sebelum dirilis (data user gak boleh hilang/corrupt pas app di-update).

## 4. Database — PostgreSQL

- Self-hosted, container Docker sendiri (bukan managed service pihak ketiga) — selaras goal privasi.
- ID pakai UUID (bukan auto-increment) — perlu digenerate di client saat offline tanpa nunggu server.
- Kolom sync tiap tabel: `updated_at`, `deleted_at` (soft delete) — dasar strategi last-write-wins.
- Backup: `pg_dump` terjadwal (cron) ke storage terpisah.

### Perbandingan opsi database
| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| **PostgreSQL (dipilih)** | Robust, fitur lengkap (JSON, full-text search, constraint kuat); ekosistem tooling terbaik; sesuai keputusan lo | Butuh effort ops (backup, update, tuning) drpd managed service — tapi wajar buat self-host |
| MySQL/MariaDB | Familiar, ringan, banyak dokumentasi | Fitur constraint/JSON-nya sedikit di bawah Postgres; gak ada alasan kuat pindah dari Postgres di sini |
| SQLite (server-side, misal via LiteFS) | Super ringan, single-file, gampang backup (copy file) | Kurang cocok buat concurrent write dari multiple client + sync engine; lebih pas buat app single-process |
| Managed Postgres (Supabase/Neon/RDS) | Zero-ops (backup/scaling dihandle provider) | Data disimpan di infrastruktur pihak ketiga — bertentangan sama goal privasi & "cloud milik sendiri" |

**Alasan pilih Postgres self-hosted**: sesuai keputusan lo, dan paling selaras goal privasi (data gak nginap di infra pihak ketiga).

## 5. Hosting & Deployment

- VPS murah (misal 1-2 vCPU/2GB RAM cukup buat single-user app) — Contabo/DigitalOcean/Hetzner.
- Docker Compose: service `api` (NestJS), `db` (Postgres), `proxy` (Caddy, auto HTTPS).
- Deployment awal manual (`docker compose up -d`); CI/CD otomatis bisa nyusul kalau udah stabil.

### Perbandingan opsi hosting
| Opsi | Kelebihan | Kekurangan |
|---|---|---|
| **VPS + Docker Compose (dipilih)** | Murah (~$5-10/bulan), full kontrol infra, gampang dipahami buat solo dev, gak ada vendor lock-in | Ops (security update, monitoring, restart-kalau-crash) tanggung jawab sendiri — tapi wajar buat skala single-user app |
| PaaS (Railway/Render/Fly.io) | Deploy super gampang, ada free/cheap tier, auto-restart & monitoring built-in | Postgres di PaaS biasanya tetep "managed" (data di infra mereka) — kurang selaras goal full self-host; harga naik cepet kalau scale |
| Kubernetes (self-host) | Skalabel, industry-standard buat production besar | Overkill total buat single-user app — kompleksitas ops jauh lebih besar drpd manfaatnya |

**Alasan pilih VPS + Docker Compose**: paling simpel buat scope solo-user side project, tetep full kontrol data (selaras goal privasi), dan cukup buat dipelajari tanpa overhead ops berlebihan.

## 6. Assumptions (default, bisa direvisi)
| Topik | Keputusan | Alasan |
|---|---|---|
| State management Flutter | Riverpod | Pragmatis, testable, cocok skala project ini |
| Migration tool | node-pg-migrate | SQL-first, konsisten sama filosofi no-ORM |
| ID strategy | UUID (bukan auto-increment int) | Perlu generate ID di client saat offline tanpa nunggu server |
| Auth model | Single-user JWT, no public registration | App ini solo-use, gak perlu flow signup umum |
| Hosting provider | Belum ditentukan (VPS generik) | Bisa disesuaikan budget/preferensi lo |

## 7. Next
Lanjut ke tahap **Development Process** — urutan build, tooling (lint/format/test), dan repo/branching strategy. Detail teknis seperti struktur folder, kontrak endpoint API, dan algoritma sync akan dirancang di tahap implementasi/design masing-masing fitur.
