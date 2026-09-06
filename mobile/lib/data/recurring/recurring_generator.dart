import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/recurring_rules_dao.dart';
import '../local/daos/transactions_dao.dart';

/// Pengganti cron backend (plan 029 Item 2). Dipanggil pas app launch:
/// generate transaksi buat tiap recurring rule yang jatuh tempo, catch-up
/// semua instance yang kelewat, lalu dorong `next_run_date`.
class RecurringGenerator {
  RecurringGenerator(this._ruleDao, this._txnDao);

  final RecurringRulesDao _ruleDao;
  final TransactionsDao _txnDao;

  Future<int> run(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdAt = now.toUtc();
    var generated = 0;

    for (final rule in await _ruleDao.findDue(userId, today)) {
      final dow = _parseDays(rule.daysOfWeek);
      var next = _dateOnly(rule.nextRunDate);
      final end = rule.endDate == null ? null : _dateOnly(rule.endDate!);

      // Mode DaysOfWeek: kalau next jatuh di hari yang ga dipilih, maju dulu.
      if (rule.intervalUnit == 'DaysOfWeek' && dow.isNotEmpty) {
        while (!dow.contains(next.weekday)) {
          next = next.add(const Duration(days: 1));
        }
      }

      while (!next.isAfter(today) && (end == null || !next.isAfter(end))) {
        if (!await _txnDao.existsForRule(rule.id, next)) {
          await _txnDao.upsert(
            TransactionsCompanion.insert(
              id: const Uuid().v4(),
              userId: rule.userId,
              accountId: rule.accountId,
              categoryId: Value(rule.categoryId),
              type: rule.type,
              amount: rule.amount,
              occurredAt: next,
              note: Value(rule.note),
              recurringRuleId: Value(rule.id),
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
          generated++;
        }
        next = nextRecurringDate(
          next,
          rule.intervalUnit,
          rule.intervalValue,
          daysOfWeek: dow,
        );
      }

      await _ruleDao.advanceNextRun(rule.id, next, createdAt);
    }
    return generated;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

Set<int> _parseDays(String? csv) => (csv == null || csv.isEmpty)
    ? const {}
    : csv.split(',').map(int.parse).toSet();

/// Tanggal jatuh tempo berikutnya. `Month` di-clamp ke hari terakhir bulan
/// tujuan (31 Jan +1bln -> 28/29 Feb) — PRD #9. `DaysOfWeek` = hari berikutnya
/// yang weekday-nya ada di [daysOfWeek] (1=Senin..7=Minggu).
DateTime nextRecurringDate(
  DateTime from,
  String unit,
  int value, {
  Set<int> daysOfWeek = const {},
}) {
  switch (unit) {
    case 'Day':
      return from.add(Duration(days: value));
    case 'Week':
      return from.add(Duration(days: value * 7));
    case 'Month':
      final target = from.month - 1 + value;
      final year = from.year + target ~/ 12;
      final month = target % 12 + 1;
      final lastDay = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, from.day < lastDay ? from.day : lastDay);
    case 'DaysOfWeek':
      if (daysOfWeek.isEmpty) return from.add(const Duration(days: 1));
      var d = from.add(const Duration(days: 1));
      while (!daysOfWeek.contains(d.weekday)) {
        d = d.add(const Duration(days: 1));
      }
      return d;
    default:
      return from;
  }
}
