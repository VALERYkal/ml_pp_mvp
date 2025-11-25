/* ===========================================================
   ML_PP MVP  citerne_info_provider.dart
   Rôle: fournir un "aperçu capacité" pour la citerne choisie:
   capacité totale, sécurité, stock estimé (RPC), disponible.
   =========================================================== */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CiterneQuickInfo {
  final String id;
  final String nom;
  final double capaciteTotale;
  final double capaciteSecurite;
  final double stockEstime;
  double get disponible => (capaciteTotale - capaciteSecurite - stockEstime)
      .clamp(0, double.infinity);
  CiterneQuickInfo({
    required this.id,
    required this.nom,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.stockEstime,
  });
}

final citerneQuickInfoProvider =
    FutureProvider.family<
      CiterneQuickInfo?,
      ({String citerneId, String produitId})
    >((ref, args) async {
      final client = Supabase.instance.client;

      final row = await client
          .from('citernes')
          .select(
            'id, nom, capacite_totale, capacite_securite, statut, produit_id',
          )
          .eq('id', args.citerneId)
          .single();

      if (row['statut'] != 'active') return null;
      if (row['produit_id'] != args.produitId) return null;

      final stock = await client.rpc(
        'get_last_stock_ambiant',
        params: {'p_citerne': args.citerneId, 'p_produit': args.produitId},
      );

      return CiterneQuickInfo(
        id: row['id'] as String,
        nom: row['nom'] as String,
        capaciteTotale: (row['capacite_totale'] as num).toDouble(),
        capaciteSecurite: (row['capacite_securite'] as num).toDouble(),
        stockEstime: (stock as num?)?.toDouble() ?? 0.0,
      );
    });

