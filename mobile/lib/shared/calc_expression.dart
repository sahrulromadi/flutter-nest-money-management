// Kalkulator nominal sederhana buat input transaksi/akun/goal/budget.
// Operator: `+ - * /` dengan presedensi (`* /` diproses duluan), operand
// integer non-negatif. Ga ada kurung, desimal, atau unary minus
// (plan 035 item 2 — out of scope).

final _opChars = RegExp(r'[+\-*/×÷−]');

/// Evaluasi [expr]. Return `null` kalau ekspresinya invalid (operator
/// nyantol, karakter aneh, bagi nol).
num? evalExpression(String expr) {
  final raw = expr
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-');

  // Tokenisasi jadi [num, op, num, op, num, ...].
  final tokens = <String>[];
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final ch = raw[i];
    if (ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39) {
      buf.write(ch);
    } else if (ch == ' ') {
      continue;
    } else if ('+-*/'.contains(ch)) {
      if (buf.isEmpty) return null; // operator tanpa operand kiri
      tokens.add(buf.toString());
      buf.clear();
      tokens.add(ch);
    } else {
      return null; // karakter ga dikenal
    }
  }
  if (buf.isEmpty) return null; // kosong atau diakhiri operator
  tokens.add(buf.toString());

  // Pass 1: * dan /.
  final reduced = <String>[tokens.first];
  for (var i = 1; i < tokens.length; i += 2) {
    final op = tokens[i];
    final rhs = num.parse(tokens[i + 1]);
    if (op == '*' || op == '/') {
      final lhs = num.parse(reduced.removeLast());
      if (op == '/' && rhs == 0) return null;
      reduced.add((op == '*' ? lhs * rhs : lhs / rhs).toString());
    } else {
      reduced
        ..add(op)
        ..add(rhs.toString());
    }
  }

  // Pass 2: + dan -.
  var acc = num.parse(reduced.first);
  for (var i = 1; i < reduced.length; i += 2) {
    final rhs = num.parse(reduced[i + 1]);
    acc = reduced[i] == '+' ? acc + rhs : acc - rhs;
  }
  return acc;
}

/// Ada operator di [expr]? (buat mutusin nampilin baris `= hasil` atau ngga.)
bool hasOperator(String expr) => _opChars.hasMatch(expr);

/// Versi tampil: `*` `/` `-` jadi `× ÷ −`.
String prettyExpression(String expr) => expr
    .replaceAll('*', ' × ')
    .replaceAll('/', ' ÷ ')
    .replaceAll('-', ' − ')
    .replaceAll('+', ' + ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
