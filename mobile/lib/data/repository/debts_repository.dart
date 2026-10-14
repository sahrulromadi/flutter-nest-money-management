import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../local/daos/debts_dao.dart';
import '../local/daos/transactions_dao.dart';

class DebtsRepository {
  DebtsRepository(this._dao, this._txnDao);

  final DebtsDao _dao;
  final TransactionsDao _txnDao;

  Stream<List<Debt>> watchAll(String userId) => _dao.watchAll(userId);

  /// Total udah dilunasin = SUM transaksi yang di-tag ke debt ini (reaktif).
  Stream<double> watchProgress(String debtId) => _txnDao.watchDebtTotal(debtId);

  Future<void> create({
    required String userId,
    required String direction,
    required String counterparty,
    required double amount,
    DateTime? dueDate,
    String? note,
  }) {
    final now = DateTime.now().toUtc();
    return _dao.upsert(
      DebtsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        direction: direction,
        counterparty: counterparty,
        amount: amount,
        dueDate: Value(dueDate),
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update({
    required String id,
    String? direction,
    String? counterparty,
    double? amount,
    DateTime? dueDate,
    String? note,
  }) {
    final now = DateTime.now().toUtc();
    return _dao.updateFields(
      id,
      DebtsCompanion(
        direction: direction != null ? Value(direction) : const Value.absent(),
        counterparty:
            counterparty != null ? Value(counterparty) : const Value.absent(),
        amount: amount != null ? Value(amount) : const Value.absent(),
        dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
        note: note != null ? Value(note) : const Value.absent(),
        updatedAt: Value(now),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDelete(id, DateTime.now().toUtc());
}
