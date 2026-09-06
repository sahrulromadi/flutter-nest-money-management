# 020 — Sync Engine

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: TECH_STACK.md #6 (sync strategy), backend plan 006 (`/sync/push`, `/sync/pull`)

## Context
Penutup Rilis 1 mobile — hubungin local DB (Drift) ke backend biar data gak ilang kalau ganti device. Timestamp-based, last-write-wins (sama kayak backend).

## Scope
1. `lib/data/remote/sync_api.dart` — `push(changes)`, `pull(since)` (panggil `/sync/push`, `/sync/pull`)
2. `lib/data/sync/sync_engine.dart`:
   - `push()`: query semua row dgn flag dirty di tiap tabel lokal, kirim ke `/sync/push`, abis sukses clear flag dirty
   - `pull()`: ambil `last_synced_at` tersimpan lokal, panggil `/sync/pull?since=`, upsert hasil ke local DB (last-write-wins by `updated_at`, sama logic kayak backend), update `last_synced_at`
   - `syncAll()`: push dulu baru pull (urutan penting — perubahan lokal harus kekirim sebelum narik perubahan lain)
3. Trigger sync: **manual doang** — tombol "Sync" (misal di `More` screen atau icon di app bar), user tekan → jalanin `syncAll()`. Gak ada auto-trigger pas connectivity berubah, gak ada periodic/background sync (keputusan eksplisit: user mau kontrol kapan sync jalan)
4. `lib/data/sync/sync_status_provider.dart` — Riverpod provider expose status (`idle`/`syncing`/`success`/`error`) + `lastSyncedAt`, dipakai buat state tombol (loading spinner pas syncing) & label "Terakhir sync: ..."

## Out of Scope
- Realtime sync (WebSocket) — sesuai TECH_STACK.md, polling/manual cukup buat v1
- Conflict UI (user gak perlu tau ada conflict, last-write-wins otomatis di background — sesuai keputusan awal)

## Verification
1. Tambah transaksi offline (matiin network) → tetep kesimpen lokal, gak error, **gak ada sync otomatis kejadian**
2. Nyalain network, tekan tombol Sync → `syncAll()` jalan, transaksi muncul di `GET /sync/pull` versi backend (cross-check lewat curl)
3. Tanpa tekan tombol → data tetep lokal doang, gak ke-push meski online (pastiin gak ada listener connectivity yang nyala sync sendiri)
4. Edit data yang sama dari 2 "device" (simulasi: ubah langsung di DB backend via SQL, lalu pull di app) → yang `updated_at` lebih baru yang menang
5. Kill app pas sync jalan, buka lagi → gak ada data corrupt/dobel, tekan Sync lagi lanjut normal
6. `flutter analyze` clean

## Next
Mobile Rilis 1 selesai fungsional. Plan 021 — Insights (budget & reports UI, Rilis 2).
