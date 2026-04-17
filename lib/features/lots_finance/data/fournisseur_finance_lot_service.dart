// 📌 Module : Finance fournisseur lot — Data service
// 🧭 Lecture via vues ; écriture via tables. Aucun recalcul métier côté Dart.

import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FournisseurFinanceLotService {
  FournisseurFinanceLotService(this._client);

  final SupabaseClient _client;

  factory FournisseurFinanceLotService.withClient(SupabaseClient client) {
    return FournisseurFinanceLotService(client);
  }

  static const String _factureView = 'v_fournisseur_facture_lot';
  static const String _rapprochementView = 'v_fournisseur_rapprochement_lot_min';
  static const String _factureTable = 'fournisseur_facture_lot_min';
  static const String _paiementTable = 'fournisseur_paiement_lot_min';

  Future<List<FournisseurFactureLot>> fetchFacturesLot() async {
    final rows = await _client
        .from(_factureView)
        .select<List<Map<String, dynamic>>>('*')
        .order('created_at', ascending: false);

    return rows.map(FournisseurFactureLot.fromMap).toList();
  }

  Future<FournisseurFactureLot?> fetchFactureLotById(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) return null;

    final row = await _client
        .from(_factureView)
        .select<Map<String, dynamic>>('*')
        .eq('facture_id', trimmedId)
        .maybeSingle();

    if (row == null) return null;
    return FournisseurFactureLot.fromMap(row);
  }

  Future<List<FournisseurRapprochementLot>> fetchRapprochementsLot() async {
    final rows = await _client
        .from(_rapprochementView)
        .select<List<Map<String, dynamic>>>('*')
        .order('invoice_no', ascending: false);

    return rows.map(FournisseurRapprochementLot.fromMap).toList();
  }

  Future<FournisseurFactureLot> createFactureLot(
    CreateFournisseurFactureLotInput input,
  ) async {
    final inserted = await _client
        .from(_factureTable)
        .insert(input.toMap())
        .select<Map<String, dynamic>>('id')
        .single();

    final factureId = inserted['id']?.toString().trim() ?? '';
    if (factureId.isEmpty) {
      throw StateError(
        'Insertion facture lot réussie sans id retourné par la table.',
      );
    }

    final facture = await fetchFactureLotById(factureId);
    if (facture == null) {
      throw StateError(
        'Facture lot insérée mais introuvable dans la vue de lecture.',
      );
    }

    return facture;
  }

  Future<void> createPaiementLot(CreateFournisseurPaiementLotInput input) async {
    await _client.from(_paiementTable).insert(input.toMap());
  }

  Future<List<FournisseurPaiementLot>> fetchPaiementsLotByFactureId(
    String factureId,
  ) async {
    final trimmedId = factureId.trim();
    if (trimmedId.isEmpty) return const [];

    final rows = await _client
        .from(_paiementTable)
        .select<List<Map<String, dynamic>>>('*')
        .eq('fournisseur_facture_id', trimmedId)
        .order('date_paiement', ascending: false);

    return rows.map(FournisseurPaiementLot.fromMap).toList();
  }
}
