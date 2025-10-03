import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception_row_vm.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

// Table VM prête à afficher
final receptionsTableProvider = FutureProvider.autoDispose<List<ReceptionRowVM>>((
  ref,
) async {
  final supa = Supabase.instance.client;

  // 1) Réceptions (noyau)
  final recRows = await supa
      .from('receptions')
      .select(
        'id, date_reception, proprietaire_type, produit_id, citerne_id, volume_corrige_15c, volume_ambiant, cours_de_route_id, created_at',
      )
      .order('date_reception', ascending: false);

  final recList = (recRows as List).cast<Map<String, dynamic>>();

  // 2) Référentiels (produits, citernes, fournisseurs)
  final prods = await ref.watch(refs.produitsRefProvider.future);
  final cits = await ref.watch(refs.citernesActivesProvider.future);

  // Récupérer les fournisseurs depuis Supabase
  // Utiliser directement la table 'partenaires' qui semble être le nom correct
  final fournisseursRows = await supa.from('partenaires').select('id, nom');

  print(
    '🔍 DEBUG: Récupération des fournisseurs depuis la table "partenaires"',
  );
  print('🔍 DEBUG: Nombre de fournisseurs trouvés: ${fournisseursRows.length}');

  final fMap = {
    for (final f in (fournisseursRows as List).cast<Map<String, dynamic>>())
      f['id'] as String: f['nom'] as String,
  };

  final pCode = {for (final p in prods) p.id: (p.code)};
  final pNom = {for (final p in prods) p.id: p.nom};
  final cNom = {
    for (final c in cits)
      c.id: (c.nom.isNotEmpty ? c.nom : c.id.substring(0, 8)),
  };

  // 3) Cours de route liés (pour plaques + fournisseur)
  final cdrIds = recList
      .map((r) => r['cours_de_route_id'])
      .whereType<String>()
      .toSet();
  final Map<String, Map<String, dynamic>> cdrMap = {};
  if (cdrIds.isNotEmpty) {
    final cdrRows = await supa
        .from('cours_de_route')
        .select('id, plaque_camion, plaque_remorque, fournisseur_id')
        .in_('id', cdrIds.toList());
    for (final m in (cdrRows as List).cast<Map<String, dynamic>>()) {
      cdrMap[m['id'] as String] = m;
    }
  }

  // Debug: Vérifier les données récupérées
  print('🔍 DEBUG Fournisseurs récupérés: ${fMap.length} fournisseurs');
  print('🔍 DEBUG CDR récupérés: ${cdrMap.length} cours de route');
  for (final entry in fMap.entries.take(3)) {
    print('🔍 DEBUG Fournisseur: ${entry.key} -> ${entry.value}');
  }

  // 4) Construire les VM
  final out = <ReceptionRowVM>[];
  for (final r in recList) {
    final pid = r['produit_id'] as String?;
    final cid = r['citerne_id'] as String?;
    final cdrId = r['cours_de_route_id'] as String?;
    final cdr = cdrId != null ? cdrMap[cdrId] : null;

    final prodLabel = [
      if (pid != null && (pCode[pid] ?? '').isNotEmpty) pCode[pid],
      if (pid != null && (pNom[pid] ?? '').isNotEmpty) pNom[pid],
    ].join(' · ');

    final plaques = _joinNonEmpty([
      cdr?['plaque_camion'] as String?,
      cdr?['plaque_remorque'] as String?,
    ], ' / ');

    // Récupération du nom du fournisseur avec debug
    final fournisseurId = cdr?['fournisseur_id'] as String?;
    final fournisseurNom = fournisseurId != null ? fMap[fournisseurId] : null;

    // Debug pour chaque réception
    print(
      '🔍 DEBUG Réception ${r['id']}: CDR=${cdrId}, fournisseurId=${fournisseurId}, fournisseurNom=${fournisseurNom}',
    );
    if (cdr != null) {
      print('🔍 DEBUG CDR data: $cdr');
    }

    out.add(
      ReceptionRowVM(
        id: r['id'] as String,
        dateReception:
            DateTime.tryParse((r['date_reception'] as String? ?? '')) ??
            DateTime.now(),
        propriete: (r['proprietaire_type'] as String? ?? '').toUpperCase(),
        produitLabel: prodLabel.isEmpty ? '—' : prodLabel,
        citerneNom: cid != null ? (cNom[cid] ?? cid.substring(0, 8)) : '—',
        vol15: (r['volume_corrige_15c'] as num?)?.toDouble(),
        volAmb: (r['volume_ambiant'] as num?)?.toDouble(),
        cdrShort: cdrId != null ? '#${cdrId.substring(0, 8)}' : null,
        cdrPlaques: plaques.isEmpty ? null : plaques,
        fournisseurNom: fournisseurNom,
      ),
    );
  }
  return out;
});

String _joinNonEmpty(List<String?> parts, String sep) {
  final nonEmpty = parts
      .where((s) => (s ?? '').trim().isNotEmpty)
      .cast<String>()
      .toList();
  return nonEmpty.join(sep);
}
