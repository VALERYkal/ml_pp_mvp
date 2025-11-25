import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DayPoint {
  final DateTime day;
  final double rec;
  final double sort;
  DayPoint(this.day, this.rec, this.sort);
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _isoUtc(DateTime d) =>
    d.toUtc().toIso8601String().split('.').first + 'Z';

final adminTrends7dProvider = FutureProvider<List<DayPoint>>((ref) async {
  final supa = Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final start = DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final end = DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));

  // Réceptions groupées par date_reception (DATE)
  final recRows = await supa
      .from('receptions')
      .select('date_reception, volume_corrige_15c, volume_ambiant, statut')
      .gte('date_reception', _ymd(start))
      .lte('date_reception', _ymd(end));

  // Sorties groupées par jour (TIMESTAMPTZ)
  final sortRows = await supa
      .from('sorties_produit')
      .select('date_sortie, volume_corrige_15c, volume_ambiant, statut')
      .gte('date_sortie', _isoUtc(start))
      .lt('date_sortie', _isoUtc(end));

  final recByDay = <String, double>{};
  for (final m in (recRows as List)) {
    if (m['statut'] != 'validee') continue;
    final day =
        (m['date_reception'] as String?) ?? _ymd(DateTime.now().toUtc());
    final v =
        (m['volume_corrige_15c'] as num?)?.toDouble() ??
        (m['volume_ambiant'] as num?)?.toDouble() ??
        0.0;
    recByDay[day] = (recByDay[day] ?? 0) + v;
  }

  final sortByDay = <String, double>{};
  for (final m in (sortRows as List)) {
    if (m['statut'] != 'validee') continue;
    final dtStr = m['date_sortie'] as String?;
    if (dtStr == null) continue;
    final dt = DateTime.parse(dtStr).toUtc();
    final key = _ymd(DateTime.utc(dt.year, dt.month, dt.day));
    final v =
        (m['volume_corrige_15c'] as num?)?.toDouble() ??
        (m['volume_ambiant'] as num?)?.toDouble() ??
        0.0;
    sortByDay[key] = (sortByDay[key] ?? 0) + v;
  }

  final points = <DayPoint>[];
  for (int i = 0; i < 7; i++) {
    final d = start.add(Duration(days: i));
    final key = _ymd(d);
    points.add(DayPoint(d, recByDay[key] ?? 0, sortByDay[key] ?? 0));
  }
  return points;
});

