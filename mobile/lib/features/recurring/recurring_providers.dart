import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_client_provider.dart';
import '../../data/remote/recurring_rules_api.dart';

final recurringRulesApiProvider = Provider<RecurringRulesApi>((ref) {
  return RecurringRulesApi(ref.watch(apiClientProvider).dio);
});

final recurringRulesListProvider =
    FutureProvider.autoDispose<List<RecurringRuleDto>>((ref) {
  return ref.watch(recurringRulesApiProvider).getAll();
});
