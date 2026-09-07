import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/calc_expression.dart';

void main() {
  group('evalExpression', () {
    test('angka polos', () => expect(evalExpression('45000'), 45000));
    test('perkalian', () => expect(evalExpression('3*15000'), 45000));
    test('presedensi × ÷ sebelum + −', () {
      expect(evalExpression('2000+3*500'), 3500);
      expect(evalExpression('10000-2*2500'), 5000);
    });
    test('operator unicode + spasi', () {
      expect(evalExpression('2 × 2500 ÷ 2'), 2500);
      expect(evalExpression('10000 − 3000'), 7000);
    });
    test('000', () => expect(evalExpression('15000+2000'), 17000));
    test('bagi nol → null', () => expect(evalExpression('100/0'), isNull));
    test('operator nyantol → null', () {
      expect(evalExpression('100+'), isNull);
      expect(evalExpression('+100'), isNull);
      expect(evalExpression('1++2'), isNull);
    });
    test('kosong → null', () => expect(evalExpression(''), isNull));
    test('karakter aneh → null', () => expect(evalExpression('1+a'), isNull));
  });

  test('hasOperator', () {
    expect(hasOperator('123'), isFalse);
    expect(hasOperator('1+2'), isTrue);
    expect(hasOperator('2×3'), isTrue);
  });

  test('prettyExpression', () {
    expect(prettyExpression('3*15000'), '3 × 15000');
    expect(prettyExpression('2000+3*500'), '2000 + 3 × 500');
  });
}
