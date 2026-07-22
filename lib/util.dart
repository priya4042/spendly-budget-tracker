import 'package:intl/intl.dart';

/// Format an amount as Indian rupees, dropping the decimals when it's a whole number.
String money(double v) {
  final whole = v == v.roundToDouble();
  final f = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: whole ? 0 : 2,
  );
  return f.format(v);
}

String dayLabel(DateTime d) => DateFormat('d MMM yyyy').format(d);
String monthLabel(DateTime d) => DateFormat('MMMM yyyy').format(d);
