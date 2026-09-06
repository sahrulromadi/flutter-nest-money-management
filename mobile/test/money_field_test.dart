import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/money_field.dart';

void main() {
  test('moneyValue buang titik ribuan & non-digit', () {
    expect(moneyValue(''), 0);
    expect(moneyValue('0'), 0);
    expect(moneyValue('546023'), 546023);
    expect(moneyValue('546.023'), 546023);
    expect(moneyValue('Rp 1.234.567'), 1234567);
  });

  test('moneyText format ribuan, kosong kalau <= 0', () {
    expect(moneyText(0), '');
    expect(moneyText(546023), '546.023');
    expect(moneyText(1234567), '1.234.567');
  });
}
