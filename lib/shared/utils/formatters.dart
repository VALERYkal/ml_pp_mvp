import 'package:intl/intl.dart';

/// Ex: 10000  -> "10 000"
///     125000 -> "125 000"
String fmtThousands(num value, {int decimals = 0, String locale = 'fr'}) {
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = decimals
    ..maximumFractionDigits = decimals;
  return f.format(value);
}

/// Ajout du suffixe " L"
String fmtLiters(num liters, {int decimals = 0, String locale = 'fr'}) {
  return '${fmtThousands(liters, decimals: decimals, locale: locale)} L';
}

/// Formatage de date courte (JJ/MM)
String fmtShortDate(DateTime d, {String locale = 'fr'}) {
  return DateFormat('dd/MM', locale).format(d);
}

/// Formatage de litres avec signe (+/-)
String fmtLitersSigned(num liters, {int decimals = 0, String locale = 'fr'}) {
  final sign = liters > 0 ? '+' : '';
  return '$sign${fmtLiters(liters, decimals: decimals, locale: locale)}';
}
