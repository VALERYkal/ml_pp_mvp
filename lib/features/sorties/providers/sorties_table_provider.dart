import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_row_vm.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

// 🚨 PROD-LOCK: Table Provider pour Sorties - DO NOT MODIFY
// Ce provider construit une liste de SortieRowVM prête à afficher dans PaginatedDataTable.
// Structure: récupère sorties_produit, enrichit avec référentiels (produits, citernes, clients, partenaires).
// Si cette structure est modifiée, mettre à jour:
// - Tests UI (sortie_list_screen_test.dart si applicable)
// - Documentation UX
final sortiesTableProvider = FutureProvider.autoDispose<List<SortieRowVM>>((
  ref,
) async {
  debugPrint('[sortiesTableProvider] fetching...');
  try {
    final supa = Supabase.instance.client;

  // 1) Sorties (noyau)
  final sortiesRows = await supa
      .from('sorties_produit')
      .select(
        'id, date_sortie, proprietaire_type, produit_id, citerne_id, volume_corrige_15c, volume_ambiant, statut, client_id, partenaire_id, created_at',
      )
      .order('date_sortie', ascending: false);

  final sortiesList = (sortiesRows as List).cast<Map<String, dynamic>>();

  // 2) Référentiels (produits, citernes)
  final prods = await ref.watch(refs.produitsRefProvider.future);
  final cits = await ref.watch(refs.citernesActivesProvider.future);

  // Récupérer les clients et partenaires depuis Supabase
  final clientsRows = await supa.from('clients').select('id, nom');

  final clientsMap = {
    for (final c in (clientsRows as List).cast<Map<String, dynamic>>())
      c['id'] as String: (c['nom'] as String?) ?? 'Client inconnu',
  };

  final partenairesRows = await supa.from('partenaires').select('id, nom');

  final partenairesMap = {
    for (final p in (partenairesRows as List).cast<Map<String, dynamic>>())
      p['id'] as String: (p['nom'] as String?) ?? 'Partenaire inconnu',
  };

  final pCode = {for (final p in prods) p.id: (p.code)};
  final pNom = {for (final p in prods) p.id: p.nom};
  final cNom = {
    for (final c in cits)
      c.id: (c.nom.isNotEmpty ? c.nom : c.id.substring(0, 8)),
  };

  // 3) Construire les VM
  final out = <SortieRowVM>[];
  for (final s in sortiesList) {
    final pid = s['produit_id'] as String?;
    final cid = s['citerne_id'] as String?;
    final clientId = s['client_id'] as String?;
    final partenaireId = s['partenaire_id'] as String?;
    final proprietaireType = (s['proprietaire_type'] as String? ?? 'MONALUXE')
        .toUpperCase();

    final prodLabel = [
      if (pid != null && (pCode[pid] ?? '').isNotEmpty) pCode[pid],
      if (pid != null && (pNom[pid] ?? '').isNotEmpty) pNom[pid],
    ].join(' · ');

    // Déterminer le bénéficiaire selon le type de propriétaire
    final beneficiaireNom = () {
      if (proprietaireType == 'MONALUXE' && clientId != null) {
        return clientsMap[clientId];
      } else if (proprietaireType == 'PARTENAIRE' && partenaireId != null) {
        return partenairesMap[partenaireId];
      }
      return null;
    }();

    // Parser date_sortie (peut être TIMESTAMPTZ ou null, fallback sur created_at)
    final dateSortie = () {
      final dateSortieStr = s['date_sortie'] as String?;
      if (dateSortieStr != null) {
        final parsed = DateTime.tryParse(dateSortieStr);
        if (parsed != null) return parsed;
      }
      // Fallback sur created_at si date_sortie est null
      final createdAtStr = s['created_at'] as String?;
      if (createdAtStr != null) {
        final parsed = DateTime.tryParse(createdAtStr);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }();

    out.add(
      SortieRowVM(
        id: s['id'] as String,
        dateSortie: dateSortie,
        propriete: proprietaireType,
        produitLabel: prodLabel.isEmpty ? '—' : prodLabel,
        citerneNom: cid != null ? (cNom[cid] ?? cid.substring(0, 8)) : '—',
        vol15: (s['volume_corrige_15c'] as num?)?.toDouble(),
        volAmb: (s['volume_ambiant'] as num?)?.toDouble(),
        beneficiaireNom: beneficiaireNom,
        statut: (s['statut'] as String? ?? 'brouillon'),
      ),
    );
  }
  debugPrint('[sortiesTableProvider] rows=${out.length}');
  return out;
  } catch (e, st) {
    debugPrint('[sortiesTableProvider] error=$e');
    rethrow;
  }
});
