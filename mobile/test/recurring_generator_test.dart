import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/recurring/recurring_generator.dart';

void main() {
  test('Day / Week advance', () {
    expect(nextRecurringDate(DateTime(2026, 1, 10), 'Day', 3), DateTime(2026, 1, 13));
    expect(nextRecurringDate(DateTime(2026, 1, 10), 'Week', 2), DateTime(2026, 1, 24));
  });

  test('Month advance biasa', () {
    expect(nextRecurringDate(DateTime(2026, 1, 15), 'Month', 1), DateTime(2026, 2, 15));
    expect(nextRecurringDate(DateTime(2026, 11, 20), 'Month', 3), DateTime(2027, 2, 20));
  });

  test('Month clamp ke hari terakhir (PRD #9)', () {
    expect(nextRecurringDate(DateTime(2026, 1, 31), 'Month', 1), DateTime(2026, 2, 28));
    expect(nextRecurringDate(DateTime(2028, 1, 31), 'Month', 1), DateTime(2028, 2, 29));
    expect(nextRecurringDate(DateTime(2026, 3, 31), 'Month', 1), DateTime(2026, 4, 30));
  });
}
