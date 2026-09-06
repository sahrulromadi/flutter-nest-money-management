import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/recurring_rules_dao.dart';

class RecurringRulesRepository {
  RecurringRulesRepository(this._dao);

  final RecurringRulesDao _dao;

  Stream<List<RecurringRule>> watchAll(String userId) => _dao.watchAll(userId);

  Future<void> create({
    required String userId,
    required String accountId,
    required String categoryId,
    required String type,
    required double amount,
    String? note,
    required String intervalUnit,
    required int intervalValue,
    String? daysOfWeek,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now().toUtc();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return _dao.upsert(
      RecurringRulesCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        note: Value(note),
        intervalUnit: intervalUnit,
        intervalValue: intervalValue,
        daysOfWeek: Value(daysOfWeek),
        startDate: start,
        nextRunDate: start,
        endDate: Value(endDate == null
            ? null
            : DateTime(endDate.year, endDate.month, endDate.day)),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDelete(id, DateTime.now().toUtc());
}
