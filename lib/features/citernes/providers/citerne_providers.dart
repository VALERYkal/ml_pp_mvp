import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/citerne_service.dart';
// NOUVEAUX IMPORTS pour utiliser la même source de données que le dashboard et Stocks
import '../../stocks/data/stocks_kpi_providers.dart';
import '../../stocks/domain/depot_stocks_snapshot.dart';
import '../../profil/providers/profil_provider.dart';
import '../../stocks_journaliers/providers/stocks_providers.dart';
import '../../../data/repositories/stocks_kpi_repository.dart';

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

/// Provider pour récupérer le stock actuel d'une citerne/produit
/// Clé : (citerneId, produitId)
/// Retourne : Map<String, double> avec 'ambiant' et 'c15'
final stockActuelProvider = Riverpod.FutureProvider.family<Map<String, double>, (String, String)>((ref, params) async {
  final (citerneId, produitId) = params;
  final service = ref.read(citerneServiceProvider);
  return await service.getStockActuel(citerneId, produitId);
});

/// Provider pour récupérer les snapshots de stock agrégés pour les citernes
/// Utilise la même source de données que le dashboard et le module Stocks (v_stocks_citerne_global_daily)
/// MAIS inclut aussi les citernes vides (sans stock) pour un affichage complet
final citerneStocksSnapshotProvider = Riverpod.FutureProvider.autoDispose<DepotStocksSnapshot>((ref) async {
  // 1) Récupérer le depotId depuis le profil
  final profil = ref.watch(profilProvider).valueOrNull;
  final depotId = profil?.depotId;
  
  if (depotId == null || depotId.isEmpty) {
    // Si pas de depotId, retourner un snapshot vide
    return DepotStocksSnapshot(
      dateJour: DateTime.now(),
      isFallback: false,
      totals: DepotGlobalStockKpi(
        depotId: '',
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
  
  // 2) Récupérer la date sélectionnée (ou utiliser maintenant) et normaliser
  // PHASE 3: Normaliser la date une seule fois de manière stable
  final selectedDate = ref.watch(stocksSelectedDateProvider);
  final dateJour = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  
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
  
  // 4) Récupérer les stocks (await) depuis depotStocksSnapshotProvider
  final snapshot = await ref.watch(
    depotStocksSnapshotProvider(
      DepotStocksSnapshotParams(
        depotId: depotId,
        dateJour: dateJour,
      ),
    ).future,
  );
  
  // 5) Créer un index des stocks par (citerneId, produitId)
  final stockByKey = <String, CiterneGlobalStockSnapshot>{};
  for (final stockRow in snapshot.citerneRows) {
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
        // Citerne avec stock : utiliser les données de v_stocks_citerne_global_daily
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
  
  // 8) Récupérer les totaux et owners depuis le snapshot (pour cohérence avec dashboard)
  final totals = snapshot.totals;
  
  final owners = snapshot.owners;
  
  return DepotStocksSnapshot(
    dateJour: dateJour,
    isFallback: snapshot.isFallback,
    totals: totals,
    owners: owners,
    citerneRows: citerneRows,
  );
});

/// Provider legacy pour compatibilité (utilise stock_actuel)
/// TODO: Peut être supprimé si plus utilisé ailleurs
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