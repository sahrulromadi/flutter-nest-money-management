import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/budget_periods_dao.dart';
import '../local/daos/budgets_dao.dart';
import '../local/daos/transactions_dao.dart';

class BudgetRepository {
  BudgetRepository(this._periodsDao, this._budgetsDao, this._txnDao);

  final BudgetPeriodsDao _periodsDao;
  final BudgetsDao _budgetsDao;
  final TransactionsDao _txnDao;

  Stream<BudgetPeriod?> watchActivePeriod(String userId) =>
      _periodsDao.watchActive(userId);

  Stream<List<Budget>> watchBudgets(String periodId) =>
      _budgetsDao.watchByPeriod(periodId);

  /// Realisasi Expense 1 kategori dalam rentang periode — reaktif.
  Stream<double> watchSpent(String categoryId, DateTime from, DateTime to) =>
      _txnDao.watchExpenseForCategory(categoryId, from, to);

  /// Tutup periode aktif (`ended_at` = sehari sebelum periode baru), buka periode baru.
  Future<void> startNewPeriod(String userId, DateTime startedAt) async {
    final now = DateTime.now().toUtc();
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    final active = await _periodsDao.findActive(userId);
    if (active != null) {
      await _periodsDao.updateFields(
        active.id,
        BudgetPeriodsCompanion(
          endedAt: Value(start.subtract(const Duration(days: 1))),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
    }
    await _periodsDao.upsert(
      BudgetPeriodsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        startedAt: start,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Set/update limit budget 1 kategori di periode (unik per period+category).
  Future<void> setBudget({
    required String periodId,
    required String categoryId,
    required double limitAmount,
  }) async {
    final now = DateTime.now().toUtc();
    final existing =
        await _budgetsDao.findByPeriodAndCategory(periodId, categoryId);
    if (existing != null) {
      await _budgetsDao.updateFields(
        existing.id,
        BudgetsCompanion(
          limitAmount: Value(limitAmount),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );
    } else {
      await _budgetsDao.upsert(
        BudgetsCompanion.insert(
          id: const Uuid().v4(),
          budgetPeriodId: periodId,
          categoryId: categoryId,
          limitAmount: limitAmount,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future<void> deleteBudget(String id) =>
      _budgetsDao.softDelete(id, DateTime.now().toUtc());
}
