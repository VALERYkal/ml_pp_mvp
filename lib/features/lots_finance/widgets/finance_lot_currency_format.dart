String formatUsd(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts.first;
  final fracPart = parts.length > 1 ? parts[1] : '00';

  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final posFromEnd = intPart.length - i;
    buf.write(intPart[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buf.write(' ');
    }
  }

  return '${buf.toString()}.$fracPart USD';
}
