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

  test('DaysOfWeek — Sen-Jum skip weekend', () {
    const weekdays = {1, 2, 3, 4, 5};
    // 2026-09-04 = Jumat -> next weekday = Senin 2026-09-07
    expect(
      nextRecurringDate(DateTime(2026, 9, 4), 'DaysOfWeek', 1,
          daysOfWeek: weekdays),
      DateTime(2026, 9, 7),
    );
    // Senin -> Selasa
    expect(
      nextRecurringDate(DateTime(2026, 9, 7), 'DaysOfWeek', 1,
          daysOfWeek: weekdays),
      DateTime(2026, 9, 8),
    );
  });

  test('DaysOfWeek — Sen/Rab/Jum', () {
    const mwf = {1, 3, 5};
    // Rabu 2026-09-09 -> Jumat 2026-09-11
    expect(
      nextRecurringDate(DateTime(2026, 9, 9), 'DaysOfWeek', 1, daysOfWeek: mwf),
      DateTime(2026, 9, 11),
    );
    // Jumat -> Senin depan
    expect(
      nextRecurringDate(DateTime(2026, 9, 11), 'DaysOfWeek', 1, daysOfWeek: mwf),
      DateTime(2026, 9, 14),
    );
  });
}
