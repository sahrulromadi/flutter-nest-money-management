// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'periods_dao.dart';

// ignore_for_file: type=lint
mixin _$PeriodsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PeriodsTable get periods => attachedDatabase.periods;
  PeriodsDaoManager get managers => PeriodsDaoManager(this);
}

class PeriodsDaoManager {
  final _$PeriodsDaoMixin _db;
  PeriodsDaoManager(this._db);
  $$PeriodsTableTableManager get periods =>
      $$PeriodsTableTableManager(_db.attachedDatabase, _db.periods);
}
