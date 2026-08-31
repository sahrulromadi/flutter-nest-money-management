# 009 — Recurring Rules Module

Status: Done
Sumber: SCHEMA.md (`recurring_rules`), PRD.md #5 Rilis 3, #9 (edge case tanggal 31)

## Context
Auto-generate transaksi berulang (gaji, tagihan, subscription). Butuh scheduler (cron) + date math yang bener buat kasus "tanggal jatuh tempo di luar tanggal valid bulan itu" (PRD #9) — pake `date-fns` (`addMonths` dkk otomatis clamp ke akhir bulan) drpd nulis date math manual yang rawan bug buat aplikasi duit.

## Scope
- **Dependencies**: `@nestjs/schedule`, `date-fns`
- `src/recurring-rules/recurring-rules.repository.ts` — `create`, `findAllByUser`, `findByIdAndUser`, `update`, `softDelete`, `findDueRules()` (`next_run_date <= CURRENT_DATE AND deleted_at IS NULL AND (end_date IS NULL OR end_date >= CURRENT_DATE)`)
- `src/recurring-rules/recurring-rules.service.ts`:
  - CRUD standar
  - `generateDueTransactions()` — buat tiap rule due: insert transaksi (`recurring_rule_id` keisi), hitung `next_run_date` baru pake `date-fns` (`addDays`/`addWeeks`/`addMonths` sesuai `interval_unit`+`interval_value`)
- `src/recurring-rules/recurring-rules.controller.ts` — CRUD endpoint
- `src/recurring-rules/recurring-rules.scheduler.ts` — `@Cron('0 1 * * *')` (jam 1 pagi tiap hari) panggil `generateDueTransactions()`
- `dto/create-recurring-rule.dto.ts`, `dto/update-recurring-rule.dto.ts`
- `src/recurring-rules/recurring-rules.module.ts` — import `ScheduleModule.forRoot()` di `AppModule`

## Out of Scope
- Preview "transaksi apa yang bakal muncul minggu depan" (nice-to-have, backlog)

## Verification
1. Bikin rule `interval_unit=Month`, `interval_value=1`, `start_date`=hari ini → `next_run_date`=hari ini
2. Panggil `generateDueTransactions()` manual (lewat endpoint test/console) → 1 transaksi kebuat, `recurring_rule_id` keisi, `next_run_date` maju 1 bulan
3. Rule dgn `start_date` tanggal 31, dites maju dari bulan yg cuma 30 hari → `next_run_date` clamp ke tanggal 30 (bukan overflow ke bulan berikutnya), pake `date-fns`
4. Rule yang `end_date` udah lewat → gak digenerate lagi
5. Lint clean, build sukses

## Next
Plan 010 — modul `goals`.
