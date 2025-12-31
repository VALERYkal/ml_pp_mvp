import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CiterneSousSeuil {
  final String id;
  final String nom;
  final double stock;
  final double seuil;
  CiterneSousSeuil(this.id, this.nom, this.stock, this.seuil);
}

final citernesSousSeuilProvider = FutureProvider<List<CiterneSousSeuil>>((
  ref,
) async {
  final supa = Supabase.instance.client;
  final citernes = await supa
      .from('citernes')
      .select('id, nom, capacite_securite');
  final latest = await supa
      .from('v_citerne_stock_snapshot_agg')
      .select('citerne_id, stock_ambiant_total');

  final stockMap = <String, double>{};
  for (final m in (latest as List)) {
    stockMap[m['citerne_id'] as String] =
        (m['stock_ambiant_total'] as num?)?.toDouble() ?? 0.0;
  }

  final list = <CiterneSousSeuil>[];
  for (final c in (citernes as List)) {
    final id = c['id'] as String;
    final nom = (c['nom'] ?? 'Citerne').toString();
    final seuil = (c['capacite_securite'] as num?)?.toDouble() ?? 0.0;
    final stock = stockMap[id] ?? 0.0;
    if (stock < seuil) list.add(CiterneSousSeuil(id, nom, stock, seuil));
  }
  list.sort((a, b) => (a.stock / a.seuil).compareTo(b.stock / b.seuil));
  return list;
});
