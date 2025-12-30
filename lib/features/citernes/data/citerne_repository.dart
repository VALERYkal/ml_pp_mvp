import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/citerne_stock_snapshot.dart';

/// Repository pour les données de citernes.
///
/// Consomme directement la vue SQL `v_citerne_stock_snapshot_agg`
/// qui expose 1 ligne = 1 citerne avec stock total (MONALUXE + PARTENAIRE).
class CiterneRepository {
  final SupabaseClient _client;

  CiterneRepository(this._client);

  /// Récupère les snapshots de stock agrégés pour toutes les citernes d'un dépôt.
  ///
  /// La vue SQL `v_citerne_stock_snapshot_agg` effectue déjà l'agrégation
  /// MONALUXE + PARTENAIRE côté base de données.
  ///
  /// [depotId] : ID du dépôt pour lequel récupérer les citernes.
  ///
  /// Retourne une liste de snapshots, une par citerne, triée par nom.
  Future<List<CiterneStockSnapshot>> fetchCiterneStockSnapshots({
    required String depotId,
  }) async {
    final res = await _client
        .from('v_citerne_stock_snapshot_agg')
        .select()
        .eq('depot_id', depotId)
        .order('citerne_nom');

    return (res as List<dynamic>)
        .map((e) => CiterneStockSnapshot.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
