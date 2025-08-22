import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../stocks_journaliers/data/stocks_service.dart';

class CiterneWithStock {
  final String id;
  final String nom;
  final String produitId;
  final double capaciteTotale;
  final double capaciteSecurite;
  final String statut;
  final double stockAmbiant;

  const CiterneWithStock({
    required this.id,
    required this.nom,
    required this.produitId,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.statut,
    required this.stockAmbiant,
  });

  bool get belowSecurity => stockAmbiant <= capaciteSecurite;
  double get ratioFill => capaciteTotale > 0 ? (stockAmbiant / capaciteTotale).clamp(0.0, 1.0) : 0.0;
}

final citernesWithStockProvider = Riverpod.FutureProvider<List<CiterneWithStock>>((ref) async {
  final client = Supabase.instance.client;
  try {
    final res = await client
        .from('citernes')
        .select('id, nom, produit_id, capacite_totale, capacite_securite, statut')
        .eq('statut', 'active')
        .order('nom');
    final list = res as List<dynamic>;
    final stocksService = StocksService.withClient(client);
    final List<CiterneWithStock> out = [];
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      final stock = await stocksService.getAmbientForToday(
        citerneId: m['id'] as String,
        produitId: m['produit_id'] as String,
      );
      out.add(CiterneWithStock(
        id: m['id'] as String,
        nom: m['nom']?.toString() ?? 'Citerne',
        produitId: m['produit_id'] as String,
        capaciteTotale: (m['capacite_totale'] as num).toDouble(),
        capaciteSecurite: (m['capacite_securite'] as num).toDouble(),
        statut: m['statut']?.toString() ?? 'active',
        stockAmbiant: stock,
      ));
    }
    return out;
  } on PostgrestException catch (e) {
    debugPrint('❌ citernesWithStockProvider: ${e.message}');
    rethrow;
  }
});

