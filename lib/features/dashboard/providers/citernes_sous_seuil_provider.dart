import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/stocks_kpi_repository.dart';
import '../../profil/providers/profil_provider.dart';

class CiterneSousSeuil {
  final String id;
  final String nom;
  final double stock;
  final double seuil;
  CiterneSousSeuil(this.id, this.nom, this.stock, this.seuil);
}

/// Provider pour les citernes sous seuil de sécurité.
///
/// SOURCE CANONIQUE — inclut adjustments (AXE A)
/// Lit depuis v_stock_actuel via StocksKpiRepository et filtre sur le dépôt du profil utilisateur.
final citernesSousSeuilProvider = FutureProvider<List<CiterneSousSeuil>>((
  ref,
) async {
  // Récupérer le depotId depuis le profil
  final profil = ref.watch(profilProvider).valueOrNull;
  final depotId = profil?.depotId;
  if (depotId == null) {
    // Si pas de depotId, retourner liste vide
    return [];
  }

  final supa = Supabase.instance.client;
  final repo = StocksKpiRepository(supa);

  // SOURCE CANONIQUE — inclut adjustments (AXE A)
  // Récupérer les stocks depuis v_stock_actuel
  final stockRows = await repo.fetchStockActuelRows(depotId: depotId);

  // Agréger par citerne_id (somme de tous les propriétaires)
  final stockMap = <String, double>{};
  for (final row in stockRows) {
    final citerneId = (row['citerne_id'] as String?) ?? '';
    if (citerneId.isEmpty) continue;
    final stockAmbiant = (row['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
    stockMap[citerneId] = (stockMap[citerneId] ?? 0.0) + stockAmbiant;
  }

  // Récupérer les citernes du dépôt avec leurs seuils
  final citernes = await supa
      .from('citernes')
      .select('id, nom, capacite_securite')
      .eq('depot_id', depotId);

  final list = <CiterneSousSeuil>[];
  for (final c in (citernes as List)) {
    final id = (c['id'] as String?) ?? '';
    if (id.isEmpty) continue;
    final nom = (c['nom'] ?? 'Citerne').toString();
    final seuil = (c['capacite_securite'] as num?)?.toDouble() ?? 0.0;
    final stock = stockMap[id] ?? 0.0;
    if (stock < seuil) {
      list.add(CiterneSousSeuil(id, nom, stock, seuil));
    }
  }
  list.sort((a, b) => (a.stock / a.seuil).compareTo(b.stock / b.seuil));
  return list;
});
