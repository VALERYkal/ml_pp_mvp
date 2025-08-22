import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminKpis {
  final int erreurs24h;
  final int receptionsJour;
  final int sortiesJour;
  final int citernesSousSeuil;
  final int produitsActifs;
  const AdminKpis({
    required this.erreurs24h,
    required this.receptionsJour,
    required this.sortiesJour,
    required this.citernesSousSeuil,
    required this.produitsActifs,
  });
}

final adminKpiProvider = FutureProvider<AdminKpis>((ref) async {
  final supa = Supabase.instance.client;
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);

  final logsErr = await supa
      .from('logs')
      .select('id')
      .gte('created_at', now.subtract(const Duration(hours: 24)).toIso8601String())
      .in_('niveau', ['ERROR', 'CRITICAL']);
  final recs = await supa
      .from('receptions')
      .select('id')
      .gte('date_reception', dayStart.toIso8601String());
  final sorties = await supa
      .from('sorties')
      .select('id')
      .gte('date_sortie', dayStart.toIso8601String());
  final citSousSeuil = await supa
      .from('citernes')
      .select('id, capacite_totale, capacite_securite, stock_estime')
      .eq('statut', 'active');
  final produitsActifs = await supa
      .from('produits')
      .select('id')
      .eq('actif', true);

  int nbCitSousSeuil = 0;
  for (final m in (citSousSeuil as List)) {
    final stock = (m['stock_estime'] as num?)?.toDouble() ?? 0;
    final seuil = (m['capacite_securite'] as num?)?.toDouble() ?? 0;
    if (stock < seuil) nbCitSousSeuil++;
  }

  return AdminKpis(
    erreurs24h: (logsErr as List).length,
    receptionsJour: (recs as List).length,
    sortiesJour: (sorties as List).length,
    citernesSousSeuil: nbCitSousSeuil,
    produitsActifs: (produitsActifs as List).length,
  );
});

