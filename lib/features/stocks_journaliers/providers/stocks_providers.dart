// ?? Providers pour Stocks journaliers (liste/filtre)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StockRowView {
  final String id;
  final String dateJour; // YYYY-MM-DD
  final String citerneId;
  final String citerneNom;
  final double capaciteTotale;
  final double capaciteSecurite;
  final String produitId;
  final String produitNom;
  final double stockAmbiant;
  final double stock15c;

  const StockRowView({
    required this.id,
    required this.dateJour,
    required this.citerneId,
    required this.citerneNom,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.produitId,
    required this.produitNom,
    required this.stockAmbiant,
    required this.stock15c,
  });
}

class StocksDataWithMeta {
  final List<StockRowView> stocks;
  final String requestedDate;
  final String actualDataDate;
  final bool isFallback;

  const StocksDataWithMeta({
    required this.stocks,
    required this.requestedDate,
    required this.actualDataDate,
    required this.isFallback,
  });
}

enum StockSortKey { ratio, stockAmbiant, stock15c, capaciteTotale }

final stocksSortKeyProvider = StateProvider<StockSortKey>(
  (ref) => StockSortKey.ratio,
);
final stocksSortAscendingProvider = StateProvider<bool>((ref) => false);

final stocksSelectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);
final stocksSelectedProduitIdProvider = StateProvider<String?>((ref) => null);
final stocksSelectedCiterneIdProvider = StateProvider<String?>((ref) => null);

final stocksListProvider = FutureProvider<StocksDataWithMeta>((ref) async {
  final client = Supabase.instance.client;
  final date = ref.watch(stocksSelectedDateProvider);
  final produitId = ref.watch(stocksSelectedProduitIdProvider);
  final citerneId = ref.watch(stocksSelectedCiterneIdProvider);
  final sortKey = ref.watch(stocksSortKeyProvider);
  final asc = ref.watch(stocksSortAscendingProvider);

  String _fmtYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final dateStr = _fmtYmd(date);
  debugPrint('?? DEBUG Stocks: Recherche pour la date: $dateStr');
  try {
    dynamic query = client
        .from('stocks_journaliers')
        .select(
          'id, date_jour, stock_ambiant, stock_15c, citerne_id, produit_id, citernes(id, nom, capacite_totale, capacite_securite), produits(id, nom)',
        )
        .eq('date_jour', dateStr);
    if (produitId != null) {
      query = query.eq('produit_id', produitId);
    }
    if (citerneId != null) {
      query = query.eq('citerne_id', citerneId);
    }
    // L'ordre par created_at n'existe pas sur stocks_journaliers (pas de colonne) ; on trie en mémoire
    var res = await query;
    debugPrint(
      '?? DEBUG Stocks: Résultat direct pour $dateStr: ${(res as List).length} entrées',
    );

    // Si pas de données pour la date exacte, chercher la date la plus récente précédente
    if ((res as List).isEmpty) {
      debugPrint(
        '?? DEBUG Stocks: Aucune donnée pour $dateStr, recherche de la date précédente...',
      );
      dynamic fallbackQuery = client
          .from('stocks_journaliers')
          .select(
            'id, date_jour, stock_ambiant, stock_15c, citerne_id, produit_id, citernes(id, nom, capacite_totale, capacite_securite), produits(id, nom)',
          )
          .lte('date_jour', dateStr)
          .order('date_jour', ascending: false)
          .limit(100); // Limite pour éviter de récupérer trop de données

      if (produitId != null) {
        fallbackQuery = fallbackQuery.eq('produit_id', produitId);
      }
      if (citerneId != null) {
        fallbackQuery = fallbackQuery.eq('citerne_id', citerneId);
      }

      final fallbackRes = await fallbackQuery;
      debugPrint(
        '?? DEBUG Stocks: Résultat fallback: ${(fallbackRes as List).length} entrées',
      );

      if ((fallbackRes as List).isNotEmpty) {
        // Grouper par citerne/produit et prendre la date la plus récente pour chaque combinaison
        final Map<String, Map<String, dynamic>> latestEntries = {};
        for (final entry in fallbackRes) {
          final m = entry as Map<String, dynamic>;
          final key = '${m['citerne_id']}_${m['produit_id']}';
          final entryDate = m['date_jour'] as String;

          if (!latestEntries.containsKey(key) ||
              latestEntries[key]!['date_jour'].compareTo(entryDate) < 0) {
            latestEntries[key] = m;
          }
        }

        debugPrint(
          '?? DEBUG Stocks: Entrées les plus récentes trouvées: ${latestEntries.length} combinaisons citerne/produit',
        );
        // Remplacer le résultat par les entrées les plus récentes
        res = latestEntries.values.toList();
      }
    }
    final list = (res as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      final cit = (m['citernes'] ?? {}) as Map<String, dynamic>;
      final prod = (m['produits'] ?? {}) as Map<String, dynamic>;
      return StockRowView(
        id: m['id'] as String,
        dateJour: (m['date_jour'] as String),
        citerneId: (m['citerne_id'] as String),
        citerneNom: (cit['nom']?.toString() ?? 'Citerne'),
        capaciteTotale: (cit['capacite_totale'] as num?)?.toDouble() ?? 0,
        capaciteSecurite: (cit['capacite_securite'] as num?)?.toDouble() ?? 0,
        produitId: (m['produit_id'] as String),
        produitNom: (prod['nom']?.toString() ?? 'Produit'),
        stockAmbiant: (m['stock_ambiant'] as num).toDouble(),
        stock15c: (m['stock_15c'] as num).toDouble(),
      );
    }).toList();

    double _ratio(StockRowView s) =>
        s.capaciteTotale > 0 ? (s.stockAmbiant / s.capaciteTotale) : 0.0;

    int _cmp(num a, num b) => a == b ? 0 : (a < b ? -1 : 1);

    list.sort((a, b) {
      var r = 0;
      switch (sortKey) {
        case StockSortKey.ratio:
          r = _cmp(_ratio(a), _ratio(b));
          break;
        case StockSortKey.stockAmbiant:
          r = _cmp(a.stockAmbiant, b.stockAmbiant);
          break;
        case StockSortKey.stock15c:
          r = _cmp(a.stock15c, b.stock15c);
          break;
        case StockSortKey.capaciteTotale:
          r = _cmp(a.capaciteTotale, b.capaciteTotale);
          break;
      }
      if (!asc) r = -r;
      // tie-breaker pour un ordre stable
      if (r == 0) {
        r = a.citerneNom.compareTo(b.citerneNom);
        if (r == 0) r = a.produitNom.compareTo(b.produitNom);
      }
      return r;
    });

    // Déterminer si on utilise des données de fallback
    final isFallback =
        (res as List).isNotEmpty &&
        (res as List).any(
          (e) => (e as Map<String, dynamic>)['date_jour'] != dateStr,
        );

    // Trouver la date la plus récente des données
    String actualDataDate = dateStr;
    if ((res as List).isNotEmpty) {
      final dates = (res as List)
          .map((e) => (e as Map<String, dynamic>)['date_jour'] as String)
          .toList();
      dates.sort((a, b) => b.compareTo(a)); // Tri décroissant
      actualDataDate = dates.first;
    }

    debugPrint(
      '?? DEBUG Stocks: Données retournées - isFallback: $isFallback, actualDataDate: $actualDataDate, count: ${list.length}',
    );

    return StocksDataWithMeta(
      stocks: list,
      requestedDate: dateStr,
      actualDataDate: actualDataDate,
      isFallback: isFallback,
    );
  } on PostgrestException catch (e) {
    debugPrint('? stocksListProvider: ${e.message}');
    rethrow;
  }
});

final stocksProduitsRefProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final res = await Supabase.instance.client
      .from('produits')
      .select('id, nom')
      .order('nom');
  return (res as List<dynamic>)
      .map(
        (e) => {
          'id': (e as Map<String, dynamic>)['id'] as String,
          'nom': e['nom']?.toString() ?? '',
        },
      )
      .toList();
});

final stocksCiternesRefProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final res = await Supabase.instance.client
      .from('citernes')
      .select('id, nom, produit_id')
      .eq('statut', 'active')
      .order('nom');
  return (res as List<dynamic>).map((e) {
    final m = (e as Map<String, dynamic>);
    return {
      'id': m['id'] as String,
      'nom': m['nom']?.toString() ?? '',
      'produit_id': m['produit_id']?.toString() ?? '',
    };
  }).toList();
});

