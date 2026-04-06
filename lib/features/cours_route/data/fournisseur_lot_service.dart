// 📌 Module : Cours de Route - Data
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2026-04-06
// 🧭 Description : Service Supabase pour la gestion des lots fournisseur

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/models/fournisseur_lot.dart';

class FournisseurLotService {
  final SupabaseClient _client;

  FournisseurLotService(this._client);

  factory FournisseurLotService.withClient(SupabaseClient client) {
    return FournisseurLotService(client);
  }

  static const String _table = 'fournisseur_lot';

  /// Select standard avec jointures légères pour affichage.
  static const String _selectWithRefs = '''
id,
fournisseur_id,
produit_id,
reference,
date_lot,
statut,
note,
created_at,
updated_at,
fournisseurs(nom),
produits(nom, code)
''';

  /// Récupère tous les lots fournisseur, les plus récents d'abord.
  Future<List<FournisseurLot>> getAll() async {
    final rows = await _client
        .from(_table)
        .select(_selectWithRefs)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => FournisseurLot.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère un lot fournisseur par son id.
  Future<FournisseurLot?> getById(String id) async {
    final row = await _client
        .from(_table)
        .select(_selectWithRefs)
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return FournisseurLot.fromMap(row);
  }

  /// Récupère les lots d'un fournisseur donné.
  Future<List<FournisseurLot>> getByFournisseur(String fournisseurId) async {
    final rows = await _client
        .from(_table)
        .select(_selectWithRefs)
        .eq('fournisseur_id', fournisseurId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => FournisseurLot.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les lots d'un fournisseur pour un produit donné.
  Future<List<FournisseurLot>> getByFournisseurAndProduit({
    required String fournisseurId,
    required String produitId,
  }) async {
    final rows = await _client
        .from(_table)
        .select(_selectWithRefs)
        .eq('fournisseur_id', fournisseurId)
        .eq('produit_id', produitId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => FournisseurLot.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les lots ouverts d'un fournisseur.
  Future<List<FournisseurLot>> getOuvertsByFournisseur(
    String fournisseurId,
  ) async {
    final rows = await _client
        .from(_table)
        .select(_selectWithRefs)
        .eq('fournisseur_id', fournisseurId)
        .eq('statut', StatutFournisseurLot.ouvert.db)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => FournisseurLot.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée un lot fournisseur.
  Future<FournisseurLot> create(FournisseurLot lot) async {
    final payload = _toInsertUpdateMap(lot, includeId: false);

    final row = await _client
        .from(_table)
        .insert(payload)
        .select(_selectWithRefs)
        .single();

    return FournisseurLot.fromMap(row);
  }

  /// Met à jour un lot fournisseur.
  Future<FournisseurLot> update(FournisseurLot lot) async {
    if (lot.id.trim().isEmpty) {
      throw ArgumentError('L\'id du lot est requis pour update().');
    }

    final payload = _toInsertUpdateMap(lot, includeId: false);

    final row = await _client
        .from(_table)
        .update(payload)
        .eq('id', lot.id)
        .select(_selectWithRefs)
        .single();

    return FournisseurLot.fromMap(row);
  }

  /// Supprime un lot fournisseur.
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Compte les lots par statut.
  Future<Map<String, int>> countByStatut() async {
    final lots = await getAll();
    final Map<String, int> counts = {
      StatutFournisseurLot.ouvert.db: 0,
      StatutFournisseurLot.cloture.db: 0,
      StatutFournisseurLot.facture.db: 0,
    };

    for (final lot in lots) {
      counts[lot.statut.db] = (counts[lot.statut.db] ?? 0) + 1;
    }

    return counts;
  }

  Map<String, dynamic> _toInsertUpdateMap(
    FournisseurLot lot, {
    required bool includeId,
  }) {
    final map = <String, dynamic>{
      if (includeId && lot.id.trim().isNotEmpty) 'id': lot.id.trim(),
      'fournisseur_id': lot.fournisseurId.trim(),
      'produit_id': lot.produitId.trim(),
      'reference': lot.reference.trim(),
      'date_lot': lot.dateLot?.toIso8601String().split('T').first,
      'statut': lot.statut.db,
      'note': _emptyToNull(lot.note),
    };

    return map;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}