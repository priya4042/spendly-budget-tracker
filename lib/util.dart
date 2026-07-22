import 'package:intl/intl.dart';
import 'store.dart';

/// Format an amount using the user's currency symbol (Indian grouping),
/// dropping the decimals when it's a whole number.
String money(double v) {
  final sym = Store.instance.currencySymbol;
  final whole = v == v.roundToDouble();
  final f = NumberFormat.currency(
    locale: 'en_IN',
    symbol: sym,
    decimalDigits: whole ? 0 : 2,
  );
  return f.format(v);
}

String dayLabel(DateTime d) => DateFormat('d MMM yyyy').format(d);
String monthLabel(DateTime d) => DateFormat('MMMM yyyy').format(d);

/// Evaluate a simple arithmetic expression (+ - * /) so the amount field
/// doubles as a calculator, e.g. "200+50*3". Returns null if invalid.
double? evalExpr(String input) {
  final s = input.replaceAll(' ', '');
  if (s.isEmpty) return null;
  // Tokenise into numbers and operators.
  final tokens = <String>[];
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final ch = s[i];
    if ('+-*/'.contains(ch)) {
      if (buf.isEmpty) return null; // no leading/duplicate operator
      tokens.add(buf.toString()); buf.clear();
      tokens.add(ch);
    } else if ((ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || ch == '.') {
      buf.write(ch);
    } else {
      return null;
    }
  }
  if (buf.isEmpty) return null;
  tokens.add(buf.toString());
  // First pass: * and /
  final pass1 = <String>[];
  for (int i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (t == '*' || t == '/') {
      final a = double.tryParse(pass1.removeLast());
      final b = double.tryParse(tokens[++i]);
      if (a == null || b == null) return null;
      if (t == '/' && b == 0) return null;
      pass1.add((t == '*' ? a * b : a / b).toString());
    } else {
      pass1.add(t);
    }
  }
  // Second pass: + and -
  double acc = double.tryParse(pass1.first) ?? (throw StateError('x'));
  for (int i = 1; i < pass1.length; i += 2) {
    final op = pass1[i];
    final n = double.tryParse(pass1[i + 1]);
    if (n == null) return null;
    acc = op == '+' ? acc + n : acc - n;
  }
  return acc;
}
