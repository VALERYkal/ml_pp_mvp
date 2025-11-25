import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/citerne_service.dart';

class CiterneRow {
  final String id;
  final String nom;
  final String? produitId;
  final double? capaciteTotale;
  final double? capaciteSecurite;
  final double? stockAmbiant;
  final double? stock15c;
  final DateTime? dateStock;

  CiterneRow({
    required this.id,
    required this.nom,
    this.produitId,
    this.capaciteTotale,
    this.capaciteSecurite,
    this.stockAmbiant,
    this.stock15c,
    this.dateStock,
  });

  bool get belowSecurity =>
      capaciteSecurite != null &&
      (stock15c ?? stockAmbiant ?? 0.0) < capaciteSecurite!;
  double get ratioFill => capaciteTotale != null && capaciteTotale! > 0
      ? ((stock15c ?? stockAmbiant ?? 0.0) / capaciteTotale!).clamp(0.0, 1.0)
      : 0.0;
}

/// Provider pour le service CiterneService
final citerneServiceProvider = Provider<CiterneService>((ref) {
  return CiterneService.withClient(Supabase.instance.client);
});

/// Provider pour récupérer le stock actuel d'une citerne/produit
/// Clé : (citerneId, produitId)
/// Retourne : Map<String, double> avec 'ambiant' et 'c15'
final stockActuelProvider =
    FutureProvider.family<Map<String, double>, (String, String)>((
      ref,
      params,
    ) async {
      final (citerneId, produitId) = params;
      final service = ref.read(citerneServiceProvider);
      return await service.getStockActuel(citerneId, produitId);
    });

final citernesWithStockProvider = FutureProvider<List<CiterneRow>>((ref) async {
  final sb = Supabase.instance.client;

  // 1) Citernes (toutes)  adapte si tu filtres par dépôt/produit/actif
  final citernes =
      await sb
              .from('citernes')
              .select('id, nom, capacite_totale, capacite_securite, produit_id')
              .eq('statut', 'active')
              .order('nom', ascending: true)
          as List;

  if (citernes.isEmpty) return [];

  final ids = citernes.map((e) => e['id'] as String).toList();
  final prodIds = citernes
      .map((e) => e['produit_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  // 2) Dernier stock par citerne/produit depuis la vue `stock_actuel`
  final stocks =
      await sb
              .from('stock_actuel')
              .select(
                'citerne_id, produit_id, stock_ambiant, stock_15c, date_jour',
              )
              .inFilter('citerne_id', ids)
              .inFilter('produit_id', prodIds)
          as List;

  // Indexer par (citerne_id, produit_id)
  final stockByKey = <String, Map<String, dynamic>>{};
  for (final s in stocks) {
    final key = '${s['citerne_id']}|${s['produit_id']}';
    stockByKey[key] = s as Map<String, dynamic>;
  }

  DateTime? _parseDate(d) {
    if (d == null) return null;
    try {
      return DateTime.parse(d.toString());
    } catch (_) {
      return null;
    }
  }

  // 3) Assemblage
  return citernes.map((c) {
    final cid = c['id'] as String;
    final pid = c['produit_id'] as String?;
    final key = pid == null ? null : '$cid|$pid';
    final s = key == null ? null : stockByKey[key];

    return CiterneRow(
      id: cid,
      nom: (c['nom'] as String?) ?? 'Citerne',
      produitId: pid,
      capaciteTotale: (c['capacite_totale'] as num?)?.toDouble(),
      capaciteSecurite: (c['capacite_securite'] as num?)?.toDouble(),
      stockAmbiant: (s?['stock_ambiant'] as num?)?.toDouble(),
      stock15c: (s?['stock_15c'] as num?)?.toDouble(),
      dateStock: _parseDate(s?['date_jour']),
    );
  }).toList();
});

