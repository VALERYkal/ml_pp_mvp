import 'package:intl/intl.dart';

final _int0 = NumberFormat.decimalPattern();
final _fixed1 = NumberFormat.decimalPattern()
  ..minimumFractionDigits = 1
  ..maximumFractionDigits = 1;

String fmtL(double? v, {int fixed = 1}) {
  final x = (v == null || v.isNaN || v.isInfinite) ? 0.0 : v;
  return '${(fixed == 0 ? _int0.format(x) : _fixed1.format(x))} L';
}

String fmtDelta(double? v15c) {
  final x = (v15c == null || v15c.isNaN || v15c.isInfinite) ? 0.0 : v15c;
  final s = x >= 0 ? '+' : '';
  return '$s${fmtL(x.abs())}';
}

String fmtPct(num? v) {
  final x = (v ?? 0).toDouble();
  return '${x.toStringAsFixed(1)}%';
}

String fmtCount(int? n) {
  return _int0.format((n ?? 0).clamp(0, 1 << 31));
}




