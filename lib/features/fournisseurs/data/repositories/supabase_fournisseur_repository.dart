import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/fournisseur.dart';
import '../../domain/repositories/fournisseur_repository.dart';

/// Implémentation read-only du repository fournisseurs via Supabase.
/// Utilise un [SupabaseClient] injecté (pas Supabase.instance en dur).
class SupabaseFournisseurRepository implements FournisseurRepository {
  final SupabaseClient _client;

  SupabaseFournisseurRepository(this._client);

  static const _selectColumns =
      'id, nom, contact_personne, email, telephone, adresse, pays, note_supplementaire, created_at';

  @override
  Future<List<Fournisseur>> fetchAllFournisseurs() async {
    try {
      final res = await _client
          .from('fournisseurs')
          .select(_selectColumns)
          .order('nom', ascending: true);

      final list = res as List;
      return list
          .map((e) =>
              Fournisseur.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Fournisseurs fetchAllFournisseurs: ${e.message}');
    } catch (e) {
      throw Exception('Fournisseurs fetchAllFournisseurs: $e');
    }
  }

  @override
  Future<Fournisseur?> getById(String id) async {
    if (id.isEmpty) return null;
    try {
      final res = await _client
          .from('fournisseurs')
          .select(_selectColumns)
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return Fournisseur.fromJson(Map<String, dynamic>.from(res as Map));
    } on PostgrestException catch (e) {
      throw Exception('Fournisseur getById: ${e.message}');
    } catch (e) {
      throw Exception('Fournisseur getById: $e');
    }
  }
}
