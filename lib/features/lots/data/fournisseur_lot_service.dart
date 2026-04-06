// 📌 Module : Lots — Data
// 🧭 CRUD table `fournisseur_lot` + lecture / mise à jour FK `cours_de_route.fournisseur_lot_id` uniquement.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';

void _harmonizeCdrRow(Map<String, dynamic> data) {
  if (data.containsKey('chauffeur_nom') && data['chauffeur'] == null) {
    data['chauffeur'] = data['chauffeur_nom'];
  }
  if (data.containsKey('depart_pays') && data['pays'] == null) {
    data['pays'] = data['depart_pays'];
  }
}

/// Accès Supabase : lots fournisseur et liaison optionnelle CDR ↔ lot.
class FournisseurLotService {
  FournisseurLotService(this._client);

  final SupabaseClient _client;

  factory FournisseurLotService.withClient(SupabaseClient client) {
    return FournisseurLotService(client);
  }

  static const String _table = 'fournisseur_lot';
  static const String _cdrTable = 'cours_de_route';

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

  // --- CRUD lot ---

  Future<List<FournisseurLot>> getAll() async {
    final rows = await _client
        .from(_table)
        .select(_selectWithRefs)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => FournisseurLot.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<FournisseurLot?> getById(String id) async {
    final row = await _client
        .from(_table)
        .select(_selectWithRefs)
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return FournisseurLot.fromMap(row);
  }

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

  Future<FournisseurLot> create(FournisseurLot lot) async {
    final payload = _toInsertUpdateMap(lot, includeId: false);

    final row = await _client
        .from(_table)
        .insert(payload)
        .select(_selectWithRefs)
        .single();

    return FournisseurLot.fromMap(row);
  }

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

  /// Passe le lot en statut « clôturé » (champ `statut` uniquement).
  Future<FournisseurLot> closeLot(String lotId) async {
    final trimmed = lotId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('L\'id du lot est requis pour closeLot().');
    }

    final row = await _client
        .from(_table)
        .update({'statut': StatutFournisseurLot.cloture.db})
        .eq('id', trimmed)
        .select(_selectWithRefs)
        .single();

    return FournisseurLot.fromMap(row);
  }

  /// Passe le lot en statut « facturé » (champ `statut` uniquement).
  Future<FournisseurLot> markLotAsFactured(String lotId) async {
    final trimmed = lotId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('L\'id du lot est requis pour markLotAsFactured().');
    }

    final row = await _client
        .from(_table)
        .update({'statut': StatutFournisseurLot.facture.db})
        .eq('id', trimmed)
        .select(_selectWithRefs)
        .single();

    return FournisseurLot.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

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

  // --- Liaison CDR (FK uniquement) ---

  /// Cours de route liés à ce lot.
  Future<List<CoursDeRoute>> getCdrByLot(String lotId) async {
    final rows = await _client
        .from(_cdrTable)
        .select<List<Map<String, dynamic>>>('*')
        .eq('fournisseur_lot_id', lotId)
        .order('date_chargement', ascending: false);

    return rows.map((raw) {
      final data = Map<String, dynamic>.from(raw);
      _harmonizeCdrRow(data);
      return CoursDeRoute.fromMap(data);
    }).toList();
  }

  /// CDR sans lot, même fournisseur et même produit (requête).
  Future<List<CoursDeRoute>> listCdrAvailableForLot({
    required String fournisseurId,
    required String produitId,
  }) async {
    final rows = await _client
        .from(_cdrTable)
        .select<List<Map<String, dynamic>>>('*')
        .eq('fournisseur_id', fournisseurId)
        .eq('produit_id', produitId)
        .is_('fournisseur_lot_id', null)
        .order('date_chargement', ascending: false);

    return rows.map((raw) {
      final data = Map<String, dynamic>.from(raw);
      _harmonizeCdrRow(data);
      return CoursDeRoute.fromMap(data);
    }).toList();
  }

  Future<void> attachCdrToLot(String cdrId, String lotId) async {
    await _client.from(_cdrTable).update({
      'fournisseur_lot_id': lotId,
    }).eq('id', cdrId);
  }

  Future<void> detachCdrFromLot(String cdrId) async {
    await _client.from(_cdrTable).update({
      'fournisseur_lot_id': null,
    }).eq('id', cdrId);
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
