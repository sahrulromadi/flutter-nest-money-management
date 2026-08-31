import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App boots and shows Login (belum ada token)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MoneyManagementApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
  });
}
