/* ===========================================================
   ML_PP MVP — cours_arrives_provider.dart
   Rôle: exposer la liste des cours_de_route au statut "arrivé"
   avec les infos utiles pour aider le choix (camion, produit,
   volume, origine/destination, date).
   =========================================================== */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

class CoursArriveItem {
  final String id;
  final DateTime dateChargement;
  final String? departPays;
  final String? depotNom;
  final String? plaqueCamion;
  final String? fournisseurNom;
  final String? transporteur;
  final String? chauffeur;
  final String statut;
  final String? produitId; // nouvel attribut pour propagation fiable
  final String produitCode;
  final String produitNom;
  final num? volume;
  CoursArriveItem({
    required this.id,
    required this.dateChargement,
    this.departPays,
    this.depotNom,
    this.plaqueCamion,
    this.fournisseurNom,
    this.transporteur,
    this.chauffeur,
    required this.statut,
    this.produitId,
    required this.produitCode,
    required this.produitNom,
    this.volume,
  });

  String get title =>
      '${dateChargement.toIso8601String().split("T").first} – ${departPays ?? "?"} → ${depotNom ?? "?"}';
  String get subtitle =>
      'Fournisseur: ${fournisseurNom ?? "-"} · Prod: ${produitCode} ${produitNom} · Vol: ${volume ?? "-"} · Camion: ${plaqueCamion ?? "-"} · Transp: ${transporteur ?? "-"} · Chauf: ${chauffeur ?? "-"}';
}

// 🚫 PROD-FROZEN: ONLY ARRIVE CDRs are selectable in Réception form. This provider filters by statut='ARRIVE' and is used by reception_form_screen.dart
final coursArrivesProvider = FutureProvider<List<CoursArriveItem>>((ref) async {
  final client = Supabase.instance.client;

  Future<List<dynamic>> _query({required bool useDepartPays}) async {
    final select = useDepartPays
        ? '''
        id, produit_id, date_chargement, depart_pays, volume, plaque_camion, transporteur, chauffeur:chauffeur_nom, statut,
        produit:produits(id,code,nom), depots:depots(nom), fournisseurs:fournisseurs(nom)
      '''
        : '''
        id, produit_id, date_chargement, pays, volume, plaque_camion, transporteur, chauffeur:chauffeur_nom, statut,
        produit:produits(id,code,nom), depots:depots(nom), fournisseurs:fournisseurs(nom)
      ''';
    final res = await client
        .from('cours_de_route')
        .select(select)
        .eq('statut', 'ARRIVE')
        .order('date_chargement', ascending: false)
        .order('created_at', ascending: false);
    return res as List<dynamic>;
  }

  List<dynamic> rows;
  try {
    // Essai 1: colonne depart_pays (schéma récent)
    rows = await _query(useDepartPays: true);
  } catch (_) {
    // Fallback: certaines bases ont 'pays' à la place de 'depart_pays'
    rows = await _query(useDepartPays: false);
  }

  // Charger référentiel produits pour fallback si la jointure ne renvoie rien
  List<refs.ProduitRef> produitsRefs = const [];
  try {
    final repo = ref.read(refs.referentielsRepoProvider);
    produitsRefs = await repo.loadProduits();
  } catch (_) {}

  return rows.map((m) {
    final prod = m['produit'] ?? {};
    final dep = m['depots'] ?? {};
    final four = m['fournisseurs'] ?? {};
    final produitId = m['produit_id'] as String?;
    final dateVal = m['date_chargement'];
    final parsedDate = dateVal == null
        ? DateTime.now()
        : DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
    String code = (prod['code'] ?? '') as String;
    String nom = (prod['nom'] ?? '') as String;
    if ((code.isEmpty || nom.isEmpty) && produitId != null) {
      final match = produitsRefs.where((p) => p.id == produitId);
      if (match.isNotEmpty) {
        code = match.first.code;
        nom = match.first.nom;
      }
    }
    return CoursArriveItem(
      id: m['id'] as String,
      dateChargement: parsedDate,
      departPays: (m['depart_pays'] ?? m['pays']) as String?,
      depotNom: dep['nom'] as String?,
      plaqueCamion: m['plaque_camion'] as String?,
      fournisseurNom: four['nom'] as String?,
      transporteur: m['transporteur'] as String?,
      chauffeur: m['chauffeur'] as String?,
      statut: (m['statut'] ?? 'arrivé') as String,
      produitCode: code,
      produitNom: nom,
      volume: (m['volume'] as num?),
    );
  }).toList();
});
