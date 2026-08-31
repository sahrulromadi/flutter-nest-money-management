import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_client_provider.dart';
import '../../data/remote/goals_api.dart';

final goalsApiProvider = Provider<GoalsApi>((ref) {
  return GoalsApi(ref.watch(apiClientProvider).dio);
});

final goalsListProvider = FutureProvider.autoDispose<List<GoalDto>>((ref) {
  return ref.watch(goalsApiProvider).getAll();
});
