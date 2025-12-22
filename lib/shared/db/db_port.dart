/* ===========================================================
   ML_PP MVP — DbPort (Port d'accès DB minimal)
   Rôle: Abstraction très légère pour faciliter le test sans réseau.
   =========================================================== */
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DbPort {
  Future<Map<String, dynamic>> insertReception(Map<String, dynamic> payload);
  // DB-STRICT: rpcValidateReception est uniquement pour les tests legacy.
  // Dans le code actif, les réceptions sont créées directement validées via INSERT.
  // Cette méthode ne doit pas être utilisée dans le code de production.
  @Deprecated('DB-STRICT: Utiliser uniquement pour tests legacy. Les réceptions sont créées directement validées.')
  Future<void> rpcValidateReception(String receptionId);
  // Référentiels pour tests (produits, citernes) — renvoyés en brut:
  Future<List<Map<String, dynamic>>> selectProduitsActifs();
  Future<List<Map<String, dynamic>>> selectCiternesActives();
}

/// Adaptateur réel Supabase (non utilisé par les tests, mais prêt pour usage futur).
class SupabaseDbPort implements DbPort {
  final SupabaseClient client;
  SupabaseDbPort(this.client);

  @override
  Future<Map<String, dynamic>> insertReception(Map<String, dynamic> payload) async {
    final Map<String, dynamic> res = await client.from('receptions').insert(payload).select<Map<String, dynamic>>('id').single();
    return res;
  }

  @override
  @Deprecated('DB-STRICT: Utiliser uniquement pour tests legacy. Les réceptions sont créées directement validées.')
  Future<void> rpcValidateReception(String receptionId) async {
    await client.rpc('validate_reception', params: {'p_reception_id': receptionId});
  }

  @override
  Future<List<Map<String, dynamic>>> selectProduitsActifs() async {
    final List<Map<String, dynamic>> rows = await client.from('produits').select<List<Map<String, dynamic>>>('id, code, nom, actif').eq('actif', true);
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> selectCiternesActives() async {
    final List<Map<String, dynamic>> rows = await client.from('citernes')
      .select<List<Map<String, dynamic>>>('id, produit_id, capacite_totale, capacite_securite, statut')
      .eq('statut', 'active');
    return rows;
  }
}


