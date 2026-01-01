import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/citerne_stock_snapshot.dart';

/// Repository pour les données de citernes.
///
/// ⚠️ AXE A — CONTRAT STOCK ACTUEL
/// Toute lecture de stock "actuel" DOIT provenir de v_stock_actuel.
/// Les vues snapshot sont dépréciées pour l'opérationnel.
class CiterneRepository {
  final SupabaseClient _client;

  CiterneRepository(this._client);

  /// Récupère les snapshots de stock agrégés pour toutes les citernes d'un dépôt.
  ///
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Lit depuis v_stock_actuel et agrège côté Dart par citerne_id.
  /// Stock physique d'une citerne = somme de TOUTES les lignes de v_stock_actuel
  /// ayant le même citerne_id, tous propriétaires confondus.
  ///
  /// [depotId] : ID du dépôt pour lequel récupérer les citernes.
  ///
  /// Retourne une liste de snapshots, une par citerne, triée par nom.
  Future<List<CiterneStockSnapshot>> fetchCiterneStockSnapshots({
    required String depotId,
  }) async {
    // 1) Lire depuis v_stock_actuel (source de vérité canonique)
    final res = await _client
        .from('v_stock_actuel') // ✅ SOURCE CANONIQUE AXE A
        .select()
        .eq('depot_id', depotId);

    final rows = List<Map<String, dynamic>>.from(res as List);

    // 2) Agréger par citerne_id (somme de tous les propriétaires)
    final Map<String, ({
      String citerneId,
      String citerneNom,
      String produitId,
      String produitNom,
      String depotId,
      double stockAmbiant,
      double stock15c,
      DateTime lastUpdatedAt,
    })> byCiterne = {};

    for (final row in rows) {
      final citerneId = row['citerne_id'] as String?;
      if (citerneId == null) continue;

      final stockAmbiant = (row['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
      final stock15c = (row['stock_15c'] as num?)?.toDouble() ?? 0.0;

      if (!byCiterne.containsKey(citerneId)) {
        // Première ligne pour cette citerne
        final updatedAtStr = row['updated_at'] as String?;
        final lastUpdatedAt = updatedAtStr != null
            ? DateTime.parse(updatedAtStr)
            : DateTime.now();

        byCiterne[citerneId] = (
          citerneId: citerneId,
          citerneNom: (row['citerne_nom'] as String?) ?? 'Citerne',
          produitId: (row['produit_id'] as String?) ?? '',
          produitNom: (row['produit_nom'] as String?) ?? '',
          depotId: (row['depot_id'] as String?) ?? depotId,
          stockAmbiant: stockAmbiant,
          stock15c: stock15c,
          lastUpdatedAt: lastUpdatedAt,
        );
      } else {
        // Agrégation : additionner les volumes
        final current = byCiterne[citerneId]!;
        final updatedAtStr = row['updated_at'] as String?;
        final lastUpdatedAt = updatedAtStr != null
            ? DateTime.parse(updatedAtStr)
            : current.lastUpdatedAt;
        // Prendre la date la plus récente
        final maxDate = lastUpdatedAt.isAfter(current.lastUpdatedAt)
            ? lastUpdatedAt
            : current.lastUpdatedAt;

        byCiterne[citerneId] = (
          citerneId: current.citerneId,
          citerneNom: current.citerneNom,
          produitId: current.produitId,
          produitNom: current.produitNom,
          depotId: current.depotId,
          stockAmbiant: current.stockAmbiant + stockAmbiant,
          stock15c: current.stock15c + stock15c,
          lastUpdatedAt: maxDate,
        );
      }
    }

    // 3) Récupérer les capacités depuis la table citernes
    final citerneIds = byCiterne.keys.toList();
    final capacitesMap = <String, ({double capaciteTotale, double capaciteSecurite})>{};

    if (citerneIds.isNotEmpty) {
      final citernesRes = await _client
          .from('citernes')
          .select('id, capacite_totale, capacite_securite')
          .in_('id', citerneIds);

      for (final c in (citernesRes as List)) {
        final id = c['id'] as String?;
        if (id == null) continue;
        final capTot = (c['capacite_totale'] as num?)?.toDouble() ?? 0.0;
        final capSec = (c['capacite_securite'] as num?)?.toDouble() ?? 0.0;
        capacitesMap[id] = (
          capaciteTotale: capTot,
          capaciteSecurite: capSec,
        );
      }
    }

    // 4) Construire les snapshots
    final snapshots = <CiterneStockSnapshot>[];
    for (final entry in byCiterne.entries) {
      final citerneId = entry.key;
      final data = entry.value;
      final capacites = capacitesMap[citerneId];

      snapshots.add(
        CiterneStockSnapshot(
          citerneId: data.citerneId,
          citerneNom: data.citerneNom,
          depotId: data.depotId,
          produitId: data.produitId,
          stockAmbiantTotal: data.stockAmbiant,
          stock15cTotal: data.stock15c,
          lastSnapshotAt: data.lastUpdatedAt,
          capaciteTotale: capacites?.capaciteTotale ?? 0.0,
          capaciteSecurite: capacites?.capaciteSecurite ?? 0.0,
        ),
      );
    }

    // 5) Trier par nom de citerne
    snapshots.sort((a, b) => a.citerneNom.compareTo(b.citerneNom));

    return snapshots;
  }
}
