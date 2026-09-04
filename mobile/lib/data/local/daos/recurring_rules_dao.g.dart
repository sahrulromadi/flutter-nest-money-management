// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rules_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringRulesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecurringRulesTable get recurringRules => attachedDatabase.recurringRules;
  RecurringRulesDaoManager get managers => RecurringRulesDaoManager(this);
}

class RecurringRulesDaoManager {
  final _$RecurringRulesDaoMixin _db;
  RecurringRulesDaoManager(this._db);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(
        _db.attachedDatabase,
        _db.recurringRules,
      );
}
