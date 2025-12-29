import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/citerne_service.dart';
// LEGACY: Imports conservés uniquement pour les providers legacy (citerneStocksSnapshotProvider, citernesWithStockProvider)
import '../../stocks/data/stocks_kpi_providers.dart';
import '../../stocks/domain/depot_stocks_snapshot.dart';
import '../../profil/providers/profil_provider.dart';
import '../../../data/repositories/stocks_kpi_repository.dart';
import '../data/citerne_repository.dart';
import '../domain/citerne_stock_snapshot.dart';

class CiterneRow {
  final String id;
  final String nom;
  final String? produitId;
  final double? capaciteTotale;
  final double? capaciteSecurite;
  final double? stockAmbiant;
  final double? stock15c;
  final DateTime? dateStock;

  CiterneRow({
    required this.id,
    required this.nom,
    this.produitId,
    this.capaciteTotale,
    this.capaciteSecurite,
    this.stockAmbiant,
    this.stock15c,
    this.dateStock,
  });

  bool get belowSecurity => 
      capaciteSecurite != null && (stock15c ?? stockAmbiant ?? 0.0) < capaciteSecurite!;
  double get ratioFill => 
      capaciteTotale != null && capaciteTotale! > 0 
          ? ((stock15c ?? stockAmbiant ?? 0.0) / capaciteTotale!).clamp(0.0, 1.0) 
          : 0.0;
}

/// Provider pour le service CiterneService
final citerneServiceProvider = Riverpod.Provider<CiterneService>((ref) {
  return CiterneService.withClient(Supabase.instance.client);
});

/// Provider pour le repository CiterneRepository
final citerneRepositoryProvider = Riverpod.Provider<CiterneRepository>((ref) {
  return CiterneRepository(Supabase.instance.client);
});

/// Provider pour récupérer les snapshots de stock agrégés pour les citernes
/// 
/// LEGACY: Utilise v_stock_actuel_snapshot comme source de vérité pour le stock actuel des citernes.
/// 
/// ⚠️ DEPRECATED: Ne pas utiliser dans le module Citernes UI.
/// Utiliser `citerneStockSnapshotProvider` (v_citerne_stock_snapshot_agg) à la place.
/// 
/// Conservé temporairement pour compatibilité avec `lib/shared/refresh/refresh_helpers.dart`.
/// Do not use in Citernes UI.
@Deprecated('Use citerneStockSnapshotProvider (v_citerne_stock_snapshot_agg) instead. Kept for refresh_helpers compatibility.')
final citerneStocksSnapshotProvider = Riverpod.FutureProvider.autoDispose<DepotStocksSnapshot>((ref) async {
  // 1) Récupérer le depotId depuis le profil
  final profil = ref.watch(profilProvider).valueOrNull;
  final depotId = profil?.depotId;
  
  if (depotId == null || depotId.isEmpty) {
    if (kDebugMode) {
      debugPrint('⚠️ citerneStocksSnapshotProvider: depotId null → skip');
    }
    throw StateError('DepotId manquant pour chargement des citernes');
  }
  
  // 2) Utiliser la date actuelle normalisée (snapshots sont toujours à jour)
  final now = DateTime.now();
  final dateJour = DateTime(now.year, now.month, now.day);
  
  if (kDebugMode) {
    debugPrint(
      '🔄 citerneStocksSnapshotProvider: start '
      'depotId=$depotId dateJour=$dateJour',
    );
  }
  
  // Guard de régression : vérifier que dateJour est bien normalisé (debug only)
  if (kDebugMode) {
    assert(
      dateJour.hour == 0 && dateJour.minute == 0 && dateJour.second == 0 && dateJour.millisecond == 0,
      '⚠️ citerneStocksSnapshotProvider: dateJour doit être normalisé (YYYY-MM-DD 00:00:00.000)',
    );
  }
  
  // 3) Récupérer toutes les citernes actives du dépôt
  final sb = Supabase.instance.client;
  final citernes = await sb
      .from('citernes')
      .select('id, nom, capacite_totale, capacite_securite, produit_id, depot_id')
      .eq('depot_id', depotId)
      .eq('statut', 'active')
      .order('nom', ascending: true) as List;
  
  if (citernes.isEmpty) {
    return DepotStocksSnapshot(
      dateJour: dateJour,
      isFallback: false,
      totals: DepotGlobalStockKpi(
        depotId: depotId,
        depotNom: '',
        produitId: '',
        produitNom: '',
        stockAmbiantTotal: 0.0,
        stock15cTotal: 0.0,
      ),
      owners: const [],
      citerneRows: const [],
    );
  }
  
  // 4) Récupérer les stocks depuis v_stock_actuel_snapshot
  final repo = ref.read(stocksKpiRepositoryProvider);
  final stockRows = await repo.fetchCiterneStocksFromSnapshot(
    depotId: depotId,
  );
  
  // Helper pour conversion sécurisée
  double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }
  
  // Helper pour conversion date sécurisée
  String _safeDateString(dynamic v) {
    if (v == null) return dateJour.toIso8601String().split('T').first;
    if (v is DateTime) return v.toIso8601String().split('T').first;
    if (v is String) {
      try {
        // Essayer de parser updated_at ou date_jour
        final dt = DateTime.parse(v);
        return dt.toIso8601String().split('T').first;
      } catch (_) {
        // Si échec, utiliser la date actuelle
      }
    }
    return dateJour.toIso8601String().split('T').first;
  }
  
  // Mapper les Map vers CiterneGlobalStockSnapshot
  final stockSnapshots = <CiterneGlobalStockSnapshot>[];
  for (final m in stockRows) {
    try {
      final map = Map<String, dynamic>.from(m);
      
      // Adapter les clés de v_stock_actuel_snapshot vers le format attendu par CiterneGlobalStockSnapshot
      // La vue retourne stock_ambiant et stock_15c (sans _total)
      map['stock_ambiant_total'] = _safeDouble(map['stock_ambiant_total'] ?? map['stock_ambiant']);
      map['stock_15c_total'] = _safeDouble(map['stock_15c_total'] ?? map['stock_15c']);
      
      // Convertir updated_at en date_jour si nécessaire
      map['date_jour'] = _safeDateString(map['date_jour'] ?? map['updated_at']);
      
      // S'assurer que les champs requis existent avec valeurs par défaut
      map['citerne_id'] ??= '';
      map['citerne_nom'] ??= 'Citerne';
      map['produit_id'] ??= '';
      map['produit_nom'] ??= '';
      map['capacite_totale'] = _safeDouble(map['capacite_totale']);
      map['capacite_securite'] = _safeDouble(map['capacite_securite']);
      
      stockSnapshots.add(CiterneGlobalStockSnapshot.fromMap(map));
    } catch (e, stack) {
      // Ignorer les rows incomplètes en mode debug, log en production
      if (kDebugMode) {
        debugPrint('⚠️ citerneStocksSnapshotProvider: Ignoré une row invalide: $e');
        debugPrint('Map: $m');
        debugPrint('Stack: $stack');
      }
      // Continue avec la row suivante sans planter
      continue;
    }
  }
  
  // 5) Créer un index des stocks par (citerneId, produitId)
  final stockByKey = <String, CiterneGlobalStockSnapshot>{};
  for (final stockRow in stockSnapshots) {
    final key = '${stockRow.citerneId}::${stockRow.produitId}';
    stockByKey[key] = stockRow;
  }
  
  // 6) Récupérer les noms des produits pour les citernes vides
  final produitIds = citernes
      .map((c) => c['produit_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();
  
  final produitsMap = <String, String>{};
  if (produitIds.isNotEmpty) {
    final produits = await sb
        .from('produits')
        .select('id, nom')
        .in_('id', produitIds) as List;
    
    for (final p in produits) {
      final id = p['id'] as String?;
      final nom = p['nom'] as String?;
      if (id != null && nom != null) {
        produitsMap[id] = nom;
      }
    }
  }
  
  // 7) Combiner toutes les citernes avec leurs stocks (ou 0 si pas de stock)
  final citerneRows = <CiterneGlobalStockSnapshot>[];
  for (final c in citernes) {
    final citerneId = c['id'] as String;
    final produitId = c['produit_id'] as String?;
    final capaciteTotale = (c['capacite_totale'] as num?)?.toDouble() ?? 0.0;
    final capaciteSecurite = (c['capacite_securite'] as num?)?.toDouble() ?? 0.0;
    final citerneNom = (c['nom'] as String?) ?? 'Citerne';
    
    if (produitId != null && produitId.isNotEmpty) {
      final key = '$citerneId::$produitId';
      final stockRow = stockByKey[key];
      
      if (stockRow != null) {
        // Citerne avec stock : utiliser les données de v_stock_actuel_snapshot
        citerneRows.add(stockRow);
      } else {
        // Citerne sans stock : créer un snapshot avec des valeurs à zéro
        citerneRows.add(
          CiterneGlobalStockSnapshot(
            citerneId: citerneId,
            citerneNom: citerneNom,
            produitId: produitId,
            produitNom: produitsMap[produitId] ?? '',
            dateJour: dateJour,
            stockAmbiantTotal: 0.0,
            stock15cTotal: 0.0,
            capaciteTotale: capaciteTotale,
            capaciteSecurite: capaciteSecurite,
          ),
        );
      }
    }
  }
  
  // 8) Calculer les totaux depuis les stocks snapshot
  final totalAmbiant = stockSnapshots.fold<double>(0.0, (sum, s) => sum + s.stockAmbiantTotal);
  final total15c = stockSnapshots.fold<double>(0.0, (sum, s) => sum + s.stock15cTotal);
  
  // Récupérer le nom du dépôt
  final depotRow = await sb
      .from('depots')
      .select('id, nom')
      .eq('id', depotId)
      .maybeSingle() as Map<String, dynamic>?;
  final depotNom = depotRow?['nom'] as String? ?? '';
  
  final totals = DepotGlobalStockKpi(
    depotId: depotId,
    depotNom: depotNom,
    produitId: '', // Agréger tous les produits
    produitNom: '', // Agréger tous les produits
    stockAmbiantTotal: totalAmbiant,
    stock15cTotal: total15c,
  );
  
  // Pour les owners, utiliser une méthode du repository si disponible, sinon liste vide temporairement
  final owners = <DepotOwnerStockKpi>[]; // TODO: calculer depuis snapshot ou utiliser repo.fetchDepotOwnerTotals()
  
  if (kDebugMode) {
    debugPrint(
      '✅ citerneStocksSnapshotProvider: success '
      'citernes=${citerneRows.length}',
    );
  }
  
  return DepotStocksSnapshot(
    dateJour: dateJour,
    isFallback: false, // v_stock_actuel_snapshot retourne toujours l'état actuel
    totals: totals,
    owners: owners,
    citerneRows: citerneRows,
  );
});

/// Provider legacy pour compatibilité (utilise stock_actuel)
/// 
/// LEGACY: Utilise la vue SQL `stock_actuel` (ancienne source de vérité).
/// 
/// ⚠️ DEPRECATED: Ne pas utiliser dans le module Citernes UI.
/// Utiliser `citerneStockSnapshotProvider` (v_citerne_stock_snapshot_agg) à la place.
/// 
/// Conservé temporairement pour compatibilité avec `lib/features/receptions/screens/reception_form_screen.dart`.
/// Do not use in Citernes UI.
@Deprecated('Use citerneStockSnapshotProvider (v_citerne_stock_snapshot_agg) instead. Kept for reception_form_screen compatibility.')
final citernesWithStockProvider = Riverpod.FutureProvider<List<CiterneRow>>((ref) async {
  final sb = Supabase.instance.client;

  // 1) Citernes (toutes) — adapte si tu filtres par dépôt/produit/actif
  final citernes = await sb
      .from('citernes')
      .select('id, nom, capacite_totale, capacite_securite, produit_id')
      .eq('statut', 'active')
      .order('nom', ascending: true) as List;

  if (citernes.isEmpty) return [];

  final ids = citernes.map((e) => e['id'] as String).toList();
  final prodIds = citernes.map((e) => e['produit_id'] as String?).whereType<String>().toSet().toList();

  // 2) Dernier stock par citerne/produit depuis la vue `stock_actuel`
  final stocks = await sb
      .from('stock_actuel')
      .select('citerne_id, produit_id, stock_ambiant, stock_15c, date_jour')
      .in_('citerne_id', ids)
      .in_('produit_id', prodIds) as List;

  // Indexer par (citerne_id, produit_id)
  final stockByKey = <String, Map<String, dynamic>>{};
  for (final s in stocks) {
    final key = '${s['citerne_id']}|${s['produit_id']}';
    stockByKey[key] = s as Map<String, dynamic>;
  }

  DateTime? _parseDate(d) {
    if (d == null) return null;
    try { return DateTime.parse(d.toString()); } catch (_) { return null; }
  }

  // 3) Assemblage
  return citernes.map((c) {
    final cid = c['id'] as String;
    final pid = c['produit_id'] as String?;
    final key = pid == null ? null : '$cid|$pid';
    final s = key == null ? null : stockByKey[key];

    return CiterneRow(
      id: cid,
      nom: (c['nom'] as String?) ?? 'Citerne',
      produitId: pid,
      capaciteTotale: (c['capacite_totale'] as num?)?.toDouble(),
      capaciteSecurite: (c['capacite_securite'] as num?)?.toDouble(),
      stockAmbiant: (s?['stock_ambiant'] as num?)?.toDouble(),
      stock15c: (s?['stock_15c'] as num?)?.toDouble(),
      dateStock: _parseDate(s?['date_jour']),
    );
  }).toList();
});

/// Provider pour récupérer les snapshots de stock agrégés pour les citernes.
///
/// Consomme directement la vue SQL `v_citerne_stock_snapshot_agg`
/// qui expose 1 ligne = 1 citerne avec stock total (MONALUXE + PARTENAIRE).
///
/// Ne pas réutiliser `depotStocksSnapshotProvider` - ce provider est isolé pour le module Citernes.
final citerneStockSnapshotProvider =
    Riverpod.FutureProvider.autoDispose<List<CiterneStockSnapshot>>((ref) async {
  final profil = ref.watch(profilProvider).valueOrNull;
  final depotId = profil?.depotId;

  if (depotId == null || depotId.isEmpty) {
    if (kDebugMode) {
      debugPrint('⚠️ citerneStockSnapshotProvider: depotId null → skip');
    }
    throw StateError('DepotId manquant pour les citernes');
  }

  final repo = ref.watch(citerneRepositoryProvider);

  if (kDebugMode) {
    debugPrint(
      '🔄 citerneStockSnapshotProvider (SQL agg): depotId=$depotId',
    );
  }

  final data = await repo.fetchCiterneStockSnapshots(depotId: depotId);

  if (kDebugMode) {
    debugPrint(
      '✅ citerneStockSnapshotProvider: ${data.length} citernes',
    );
  }

  return data;
});