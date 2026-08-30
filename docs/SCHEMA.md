# Database Schema

Status: Draft v2
Sumber: PRD.md #4/#9 (entitas & edge case) + TECH_STACK.md (Postgres, UUID, no ORM)

Semua tabel: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ`, `deleted_at TIMESTAMPTZ NULL` (soft delete). Kolom `updated_at`/`deleted_at` dipakai sync engine (last-write-wins, PRD #7).

## users
| Kolom | Tipe | Ket |
|---|---|---|
| email | TEXT UNIQUE | |
| password_hash | TEXT | argon2 |

## accounts
| Kolom | Tipe | Ket |
|---|---|---|
| user_id | UUID FK → users | |
| name | TEXT | |
| type | TEXT | enum: Bank / Ewallet / Cash |
| initial_balance | NUMERIC(18,2) | |
| currency | TEXT | default 'IDR' |

Saldo berjalan **tidak disimpan** — dihitung on-the-fly: `initial_balance + SUM(transaksi terkait account ini, sesuai arah in/out/transfer)`. Alasan: hindari resiko drift kalau ada bug sync/edit; skala solo-user cukup ringan buat query on-the-fly.

## categories
| Kolom | Tipe | Ket |
|---|---|---|
| user_id | UUID FK → users | |
| name | TEXT | |
| type | TEXT | enum: Income / Expense |
| parent_id | UUID FK → categories, NULL | subkategori |
| icon | TEXT NULL | |
| color | TEXT NULL | |

Gak ada kategori bawaan/predefined — semua kategori dibuat manual oleh user. Delete = soft delete (kategori lama dipakai transaksi historis tetap valid, PRD #9).

## transactions
| Kolom | Tipe | Ket |
|---|---|---|
| user_id | UUID FK → users | |
| account_id | UUID FK → accounts | akun asal |
| category_id | UUID FK → categories, NULL | NULL kalau type=transfer |
| type | TEXT | enum: Income / Expense / Transfer |
| amount | NUMERIC(18,2) | selalu positif, arah dari `type` |
| transfer_to_account_id | UUID FK → accounts, NULL | diisi kalau type=transfer |
| occurred_at | DATE | tanggal transaksi (beda dari created_at) |
| note | TEXT NULL | |
| recurring_rule_id | UUID FK → recurring_rules, NULL | ditandai kalau auto-generated |
| goal_id | UUID FK → goals, NULL | tag kontribusi ke goal (1 transaksi → 1 goal) |

Transfer = **1 row** (bukan 2 row terpisah) → gak perlu exclude manual di laporan income/expense per kategori, karena category_id NULL & type=transfer otomatis di-skip dari breakdown kategori.

## budget_periods
| Kolom | Tipe | Ket |
|---|---|---|
| user_id | UUID FK → users | |
| started_at | DATE | |
| ended_at | DATE NULL | NULL = periode aktif |

Dibuat manual oleh user tiap gajian cair (PRD #5 Rilis 2). Periode sebelumnya di-set `ended_at` otomatis saat periode baru dibuat.

## budgets
| Kolom | Tipe | Ket |
|---|---|---|
| budget_period_id | UUID FK → budget_periods | |
| category_id | UUID FK → categories | |
| limit_amount | NUMERIC(18,2) | |

Unique constraint: `(budget_period_id, category_id)`.

## recurring_rules
| Kolom | Tipe | Ket |
|---|---|---|
| user_id | UUID FK → users | |
| account_id | UUID FK → accounts | |
| category_id | UUID FK → categories | |
| type | TEXT | enum: Income / Expense |
| amount | NUMERIC(18,2) | |
| note | TEXT NULL | |
| interval_unit | TEXT | enum: Day / Week / Month |
| interval_value | INT | misal tiap 2 minggu → unit=week, value=2 |
| start_date | DATE | |
| next_run_date | DATE | dipakai scheduler cari rule yang harus di-generate |
| end_date | DATE NULL | opsional, stop otomatis |

## goals
| Kolom | Tipe | Ket |
|---|---|---|
| user_id | UUID FK → users | |
| name | TEXT | |
| target_amount | NUMERIC(18,2) | |
| due_date | DATE NULL | |
| account_id | UUID FK → accounts, NULL | opsional, kalau nabung di akun spesifik |

## Keputusan Desain
| Topik | Keputusan | Alasan |
|---|---|---|
| Balance akun & goal progress | On-the-fly SUM, bukan cached column | Hindari drift, cukup ringan buat skala solo-user |
| Transfer antar akun | 1 row (type=transfer, `transfer_to_account_id`) | Gak dobel-hitung di laporan kategori |
| Goal contribution | Kolom `goal_id` langsung di transactions | 1 transaksi = 1 goal, cukup buat kebutuhan sekarang; bisa naik ke join table nanti kalau perlu partial/multi-goal |

## Next
DDL sudah dibuat sebagai migration `node-pg-migrate` di `backend/migrations/` (9 file, urut sesuai dependency FK: extensions → users → accounts → categories → goals → recurring_rules → transactions → budget_periods → budgets).
