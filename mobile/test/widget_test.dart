import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App boots ke shell (nav bawah keliatan)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MoneyManagementApp()),
    );
    // Jangan pumpAndSettle — skeleton shimmer ga pernah settle.
    await tester.pump(const Duration(seconds: 1));

    // Login opsional: app langsung ke shell, bukan layar Login.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('More'), findsWidgets);
  });
}
