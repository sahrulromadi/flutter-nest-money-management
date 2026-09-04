// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_periods_dao.dart';

// ignore_for_file: type=lint
mixin _$BudgetPeriodsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BudgetPeriodsTable get budgetPeriods => attachedDatabase.budgetPeriods;
  BudgetPeriodsDaoManager get managers => BudgetPeriodsDaoManager(this);
}

class BudgetPeriodsDaoManager {
  final _$BudgetPeriodsDaoMixin _db;
  BudgetPeriodsDaoManager(this._db);
  $$BudgetPeriodsTableTableManager get budgetPeriods =>
      $$BudgetPeriodsTableTableManager(_db.attachedDatabase, _db.budgetPeriods);
}
