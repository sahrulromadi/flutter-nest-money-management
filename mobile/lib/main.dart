import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'features/categories/categories_providers.dart';
import 'features/recurring/recurring_providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const ProviderScope(child: MoneyManagementApp()));
}

class MoneyManagementApp extends ConsumerWidget {
  const MoneyManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Pas app launch: generate transaksi dari recurring rule yang jatuh tempo.
    // Lokal, gak butuh login, best-effort (gak nge-block first frame).
    ref.watch(recurringStartupProvider);
    // Retag transaksi lama tanpa kategori ke kategori sistem "Penyesuaian".
    ref.watch(categoriesBackfillStartupProvider);

    return MaterialApp.router(
      title: 'Money Management',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
