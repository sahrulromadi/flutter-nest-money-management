# 034 — Transaksi Berulang: Pilih Hari Tertentu (Sen/Sel/…/Min)

Status: **SELESAI** (2026-09-06).
Sumber: user. Case sering: parkir tiap Senin–Jumat. "Tiap 1 Hari" ikut generate Sabtu/Minggu.
User ga mau setup ulang terus. → mode "hari tertentu" (multi-select hari), nyakup weekday.

## Keputusan
Tambah `interval_unit = 'DaysOfWeek'` + kolom `days_of_week TEXT` (CSV angka hari,
1=Senin .. 7=Minggu — ngikut `DateTime.weekday` Dart).

- `interval_unit = 'DaysOfWeek'` → rule jalan tiap hari yang ada di `days_of_week`.
  `interval_value` diabaikan.
- Sen–Jum = `days_of_week = '1,2,3,4,5'`. Sen/Rab/Jum = `'1,3,5'`. dst.
- Mode lama (`Day`/`Week`/`Month` + `interval_value`) tetap ada, `days_of_week` NULL.

## Schema

### Backend — migrasi baru
```sql
ALTER TABLE recurring_rules ADD COLUMN days_of_week TEXT;
ALTER TABLE recurring_rules DROP CONSTRAINT recurring_rules_interval_unit_check;
ALTER TABLE recurring_rules ADD CONSTRAINT recurring_rules_interval_unit_check
  CHECK (interval_unit IN ('Day', 'Week', 'Month', 'DaysOfWeek'));
```
(cek nama constraint aktual di `\d recurring_rules` — default `recurring_rules_interval_unit_check`)
`down`: kebalikannya (drop kolom + balikin CHECK).

### Backend — kode
- `create-recurring-rule.dto.ts`: `INTERVAL_UNITS` tambah `'DaysOfWeek'`. Field
  `daysOfWeek?: string` (`@IsOptional() @IsString()` — validasi format "1,3,5" di service
  atau regex `^[1-7](,[1-7])*$`).
- `recurring-rules.repository.ts`: interface `RecurringRule` + INSERT + (update kalau ada)
  tambah `days_of_week`.
- `sync.constants.ts`: tabel `recurring_rules` kolom tambah `'days_of_week'`.

### Mobile
- `tables/recurring_rules.dart`:
  - `daysOfWeek => text().named('days_of_week').nullable()()`
  - `intervalUnit` CHECK tambah `'DaysOfWeek'`.
  - dev phase (fresh install, schemaVersion 1) → cukup regen build_runner.
- `sync_serializers.dart`: `recurringRuleToJson`/`FromJson` tambah `days_of_week` /
  `daysOfWeek: Value(j['days_of_week'] as String?)`.
- `recurring_rules_repository.dart` `create`: param `String? daysOfWeek`.

## Form (`recurring_form_screen.dart`)
- `_intervalUnits` tambah `'DaysOfWeek'`. Dropdown label map:
  `{'Day':'Hari','Week':'Minggu','Month':'Bulan','DaysOfWeek':'Hari tertentu'}`.
- State `Set<int> _daysOfWeek = {}`.
- `_intervalUnit == 'DaysOfWeek'`:
  - sembunyiin field "Tiap [N]".
  - tampil 7 `FilterChip`: Sen Sel Rab Kam Jum Sab Min (value 1..7). Multi-select.
- `_submit`: kalau mode DaysOfWeek & `_daysOfWeek` kosong → error "Pilih minimal 1 hari".
  Kirim `daysOfWeek: (_daysOfWeek.toList()..sort()).join(',')`.

## Generator (`recurring_generator.dart`)
- `nextRecurringDate(from, unit, value, {String? daysOfWeek})`:
  - `case 'DaysOfWeek'`: parse `daysOfWeek` → `Set<int>`. Dari `from`, maju 1 hari terus
    sampai `d.weekday` ada di set. Return `d`. (kalau set kosong / null → return `from` +
    1 hari, fallback aman)
- `run()`:
  - pas ambil rule, teruskan `rule.daysOfWeek` ke `nextRecurringDate`.
  - sebelum while-loop, kalau `intervalUnit == 'DaysOfWeek'` & `next.weekday` **ga** ada di
    set → maju ke hari pertama yang cocok (biar start_date yang jatuh di hari non-pilihan
    ga bikin transaksi di hari itu).
  - guard `existsForRule` tetap.

## Verifikasi
1. `flutter analyze` + `build_runner` OK. Backend `migrate:up`/`down`, `build` + `eslint` clean.
2. Bikin rule "parkir Rp 2.000", satuan **Hari tertentu**, centang Sen–Jum, mulai Jumat.
3. Restart app Senin depan → ke-generate transaksi Jum + Sen (Sab/Min skip), `next_run_date`
   = Selasa.
4. Rule Sen/Rab/Jum, mulai Selasa → transaksi pertama di Rabu.
5. Mode Day/Week/Month biasa → ga regresi, `days_of_week` NULL.
6. Sync → `interval_unit='DaysOfWeek'` + `days_of_week='1,2,3,4,5'` masuk Postgres, no error.
7. `end_date` → generator berhenti di `end_date`.

## Out of Scope
- Kombinasi "tiap 2 minggu di hari tertentu".
- Edit rule (form belum support edit — hapus + bikin baru).
