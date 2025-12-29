// 📌 Module : Citernes - Service minimal pour validations réception

import 'package:supabase_flutter/supabase_flutter.dart';

class CiterneInfo {
  final String id;
  final double capaciteTotale;
  final double capaciteSecurite;
  final String statut; // 'active' | 'inactive' | 'maintenance'
  final String produitId;

  CiterneInfo({
    required this.id,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.statut,
    required this.produitId,
  });

  factory CiterneInfo.fromMap(Map<String, dynamic> m) {
    return CiterneInfo(
      id: m['id'] as String,
      capaciteTotale: (m['capacite_totale'] as num).toDouble(),
      capaciteSecurite: (m['capacite_securite'] as num).toDouble(),
      statut: m['statut'] as String? ?? 'active',
      produitId: m['produit_id'] as String,
    );
  }
}

class CiterneService {
  final SupabaseClient _client;
  CiterneService.withClient(this._client);

  /// Formate une date en YYYY-MM-DD pour la base de données
  String _fmtYmd(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  /// Récupère le stock actuel pour une citerne et un produit à une date donnée
  /// 
  /// LEGACY: Utilise la vue SQL `stock_actuel` (ancienne source de vérité).
  /// 
  /// ⚠️ DEPRECATED: Cette méthode est conservée uniquement pour compatibilité avec ReceptionService.
  /// Pour le module Citernes, utiliser `CiterneRepository.fetchCiterneStockSnapshots()` (v_citerne_stock_snapshot_agg) à la place.
  /// 
  /// [citerneId] : ID de la citerne
  /// [produitId] : ID du produit
  /// [date] : Date optionnelle (par défaut aujourd'hui)
  /// 
  /// Retourne : Map avec 'ambiant' et 'c15' (volumes en litres)
  @Deprecated('Legacy method using stock_actuel. Kept for ReceptionService compatibility. Use CiterneRepository.fetchCiterneStockSnapshots() for Citernes.')
  Future<Map<String, double>> getStockActuel(
    String citerneId, 
    String produitId, 
    {DateTime? date}
  ) async {
    final dateJour = _fmtYmd(date ?? DateTime.now());
    
    try {
      final res = await _client
          .from('stock_actuel')
          .select('stock_ambiant, stock_15c')
          .eq('citerne_id', citerneId)
          .eq('produit_id', produitId)
          .eq('date_jour', dateJour)
          .maybeSingle();

      if (res == null) {
        return {'ambiant': 0.0, 'c15': 0.0};
      }

      final m = res as Map<String, dynamic>;
      return {
        'ambiant': (m['stock_ambiant'] as num?)?.toDouble() ?? 0.0,
        'c15': (m['stock_15c'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      // En cas d'erreur, retourner des valeurs par défaut
      return {'ambiant': 0.0, 'c15': 0.0};
    }
  }

  Future<CiterneInfo?> getById(String id) async {
    final res = await _client
        .from('citernes')
        .select('id, capacite_totale, capacite_securite, statut, produit_id')
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return CiterneInfo.fromMap(res as Map<String, dynamic>);
  }
}


