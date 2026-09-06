import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/goals_dao.dart';
import '../local/daos/transactions_dao.dart';

class GoalsRepository {
  GoalsRepository(this._dao, this._txnDao);

  final GoalsDao _dao;
  final TransactionsDao _txnDao;

  Stream<List<Goal>> watchAll(String userId) => _dao.watchAll(userId);

  /// Total terkumpul = SUM transaksi yang di-tag ke goal ini (reaktif).
  Stream<double> watchProgress(String goalId) => _txnDao.watchGoalTotal(goalId);

  Future<void> create({
    required String userId,
    required String name,
    required double targetAmount,
    DateTime? dueDate,
    String? accountId,
  }) {
    final now = DateTime.now().toUtc();
    return _dao.upsert(
      GoalsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        targetAmount: targetAmount,
        dueDate: Value(dueDate),
        accountId: Value(accountId),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDelete(id, DateTime.now().toUtc());
}
