import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_state.dart';
import 'features/reminders/reminder_scheduler.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const ProviderScope(child: MoneyManagementApp()));
}

class MoneyManagementApp extends ConsumerStatefulWidget {
  const MoneyManagementApp({super.key});

  @override
  ConsumerState<MoneyManagementApp> createState() => _MoneyManagementAppState();
}

class _MoneyManagementAppState extends ConsumerState<MoneyManagementApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App dikunci lagi tiap balik dari background (PRD: PIN/biometric lock
    // "tiap dibuka", bukan cuma cold start).
    if (state == AppLifecycleState.resumed) {
      ref.read(authControllerProvider.notifier).relock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Tiap kali app unlocked (buka pertama kali/abis lock screen), refresh
    // reminder — best-effort, gak boleh crash app kalau backend gak bisa
    // diakses (misal offline).
    ref.listen(authControllerProvider, (previous, next) {
      if (next == AuthPhase.unlocked) {
        ref.read(reminderSchedulerProvider).refresh().catchError((_) {});
      }
    });

    return MaterialApp.router(
      title: 'Money Management',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
