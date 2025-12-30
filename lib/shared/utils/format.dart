String fmtCompact(num v) {
  final d = v.toDouble();
  if (d.abs() >= 1e9) return '${(d / 1e9).toStringAsFixed(1)} B';
  if (d.abs() >= 1e6) return '${(d / 1e6).toStringAsFixed(1)} M';
  if (d.abs() >= 1e3) return '${(d / 1e3).toStringAsFixed(1)} k';
  return d.toStringAsFixed(0);
}
