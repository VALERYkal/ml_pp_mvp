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


