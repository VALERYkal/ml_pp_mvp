# Rapport de correction — Migration vers v_stock_actuel_snapshot

**Date** : 27 décembre 2025  
**Module concerné** : Stocks / Citernes / Dashboard KPI  
**Type** : Correction critique de cohérence des données

---

## Contexte

Plusieurs écrans (Citernes, Stocks, Dashboard KPI) affichaient un stock incohérent.

**Exemple observé** : Dépôt affiché **9 000 L**, alors que le cumul Réceptions – Sorties donne **14 400 L**.

**Problème critique** : Les décideurs ne peuvent pas piloter le dépôt si les volumes affichés ne représentent pas le stock réel "présent".

---

## Diagnostic

### Problème racine

- `stocks_journaliers` est alimenté uniquement sur la date des mouvements via triggers.
- Il ne contient **pas un "snapshot courant" propagé jour après jour**.
- Les vues basées sur `max(date_jour)` (`v_stocks_citerne_global`, `v_kpi_stock_global` selon cas) peuvent donc retourner une valeur partielle (ex: uniquement la dernière réception du jour le plus récent).

### Impact

- Les citernes avec mouvements récents (même jour) apparaissent avec leur stock correct.
- Les citernes avec derniers mouvements antérieurs (jours précédents) ne sont pas incluses dans le calcul.
- Résultat : **totaux partiels, incohérents avec la réalité physique du dépôt**.

---

## Décision

✅ **Option B (DB-STRICT / Stock actuel recalculé) validée** :

**Source de vérité UI** = vue snapshot "stock actuel" (`v_stock_actuel_snapshot`) qui reflète le stock présent (cumul des mouvements), indépendamment des trous de dates dans `stocks_journaliers`.

### Justification

- La vue `v_stock_actuel_snapshot` calcule le dernier état connu de chaque citerne.
- Elle agrège correctement MONALUXE + PARTENAIRE.
- Elle est indépendante des dates de mise à jour de chaque citerne.
- Elle garantit une cohérence totale avec la réalité physique.

---

## Implémentation réalisée (Patch A)

### A1 — Repository

**Fichier** : `lib/data/repositories/stocks_kpi_repository.dart`

**Changement** :
- Ajout de la méthode `fetchCiterneStocksFromSnapshot()` qui lit depuis `v_stock_actuel_snapshot`.
- Support des filtres optionnels : `depotId`, `citerneId`, `produitId`.
- Retourne `List<Map<String, dynamic>>` pour flexibilité.

**Code ajouté** :
```dart
Future<List<Map<String, dynamic>>> fetchCiterneStocksFromSnapshot({
  String? depotId,
  String? citerneId,
  String? produitId,
}) async {
  final query = _client
      .from('v_stock_actuel_snapshot')
      .select<List<Map<String, dynamic>>>();

  if (depotId != null) query.eq('depot_id', depotId);
  if (citerneId != null) query.eq('citerne_id', citerneId);
  if (produitId != null) query.eq('produit_id', produitId);

  query.order('citerne_nom', ascending: true);

  final rows = await query;
  return (rows as List).cast<Map<String, dynamic>>();
}
```

---

### A2 — Providers Citernes

**Fichier** : `lib/features/citernes/providers/citerne_providers.dart`

**Changement** :
- `citerneStocksSnapshotProvider` lit désormais depuis `fetchCiterneStocksFromSnapshot()`.
- Remplacement de l'appel à `depotStocksSnapshotProvider` (qui utilisait `v_stocks_citerne_global_daily`).
- Mapping adaptatif des clés (`stock_ambiant` vs `stock_ambiant_total`).
- Calcul des totaux depuis les snapshots agrégés.

**Impact** :
- L'écran Citernes affiche désormais le stock réel présent dans chaque citerne.
- Les dates peuvent différer entre citernes (dernier mouvement de chacune).

---

### A3.1 — Dashboard KPI "Stock total dépôt"

**Fichier** : `lib/features/stocks/data/stocks_kpi_providers.dart`  
**Fichier** : `lib/features/dashboard/widgets/role_dashboard.dart`

#### A3.1.1 — Nouveau provider

**Changement** :
- Ajout de `depotGlobalStockFromSnapshotProvider` qui agrège les stocks depuis `v_stock_actuel_snapshot`.
- Retourne un record avec `amb`, `v15`, et `nbTanks`.

**Code ajouté** :
```dart
final depotGlobalStockFromSnapshotProvider =
    riverpod.FutureProvider.autoDispose.family<({double amb, double v15, int nbTanks}), String>((
      ref,
      depotId,
    ) async {
      final repo = ref.watch(stocksKpiRepositoryProvider);
      final rows = await repo.fetchCiterneStocksFromSnapshot(depotId: depotId);

      double amb = 0.0;
      double v15 = 0.0;
      final tanks = <String>{};

      for (final r in rows) {
        final m = Map<String, dynamic>.from(r);
        tanks.add(m['citerne_id']?.toString() ?? '');
        amb += (m['stock_ambiant_total'] as num?)?.toDouble()
            ?? (m['stock_ambiant'] as num?)?.toDouble()
            ?? 0.0;
        v15 += (m['stock_15c_total'] as num?)?.toDouble()
            ?? (m['stock_15c'] as num?)?.toDouble()
            ?? 0.0;
      }

      return (amb: amb, v15: v15, nbTanks: tanks.where((e) => e.isNotEmpty).length);
    });
```

#### A3.1.2 — Rebranchement UI

**Changement** :
- Le widget "Stock total" dans le dashboard utilise désormais `depotGlobalStockFromSnapshotProvider`.
- Remplacement de l'ancienne source (`depotStocksSnapshotProvider` avec `v_stocks_citerne_global_daily`).
- Gestion des états (loading, error, fallback).

**Impact** :
- Le KPI "Stock total dépôt" affiche désormais le stock réel présent.
- Cohérence garantie avec l'écran Citernes.

---

## Vérification post-correction

### Résultats observés

| Métrique | Avant correction | Après correction | Statut |
|----------|------------------|------------------|--------|
| Stock total dépôt | 9 000 L ❌ | **14 400 L** ✅ | Corrigé |
| TANK1 | 2 777 L | **8 220 L** ✅ | Corrigé |
| TANK2 | 0 L ❌ | **2 097 L** ✅ | Corrigé |
| TANK3 | 0 L ❌ | **4 083 L** ✅ | Corrigé |

### Détail citernes

- **TANK1** : 8 220 L ✅
- **TANK2** : 2 097 L ✅
- **TANK3** : 4 083 L ✅
- **Total** : 14 400 L ✅

### Notes importantes

Les écarts "journal vs snapshot" identifiés ne sont **pas un bug du snapshot**, mais une limite structurelle de `stocks_journaliers` tel qu'alimenté aujourd'hui (pas de propagation jour après jour, uniquement inserts sur dates de mouvements).

---

## Fichiers modifiés

1. `lib/data/repositories/stocks_kpi_repository.dart`
   - Ajout de `fetchCiterneStocksFromSnapshot()`

2. `lib/features/citernes/providers/citerne_providers.dart`
   - Modification de `citerneStocksSnapshotProvider` pour utiliser le nouveau repository

3. `lib/features/stocks/data/stocks_kpi_providers.dart`
   - Ajout de `depotGlobalStockFromSnapshotProvider`

4. `lib/features/dashboard/widgets/role_dashboard.dart`
   - Rebranchement du KPI "Stock total" sur le nouveau provider

---

## Contraintes respectées

- ✅ **Modifications additives** : Aucune méthode/provider existant n'a été supprimé
- ✅ **Rétrocompatibilité** : Les anciennes sources restent disponibles (pas encore supprimées)
- ✅ **Design inchangé** : Aucune modification de l'UI, uniquement la source de données
- ✅ **Tests** : Aucun test existant n'a été cassé (nouveaux providers non encore testés)

---

## Prochaines étapes (non implémentées dans ce patch)

- [ ] A3.2+ : Rebrancher les autres KPIs du dashboard (breakdown par propriétaire, etc.)
- [ ] Migration complète : Supprimer les anciennes sources une fois toutes les migrations terminées
- [ ] Tests : Ajouter des tests unitaires pour les nouveaux providers
- [ ] Documentation SQL : Documenter la vue `v_stock_actuel_snapshot` si elle n'existe pas encore

---

**Auteur** : Valery Kalonga (avec assistance technique IA)  
**Version** : 1.0  
**Date** : 27 décembre 2025

