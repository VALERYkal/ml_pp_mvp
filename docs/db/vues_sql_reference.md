# Référence des Vues SQL

**Date** : 2025-12-27  
**Version** : 3.0  
**Objectif** : Centraliser toutes les vues SQL existantes, leur rôle, leur statut (canonique/legacy), et les points d'entrée Flutter qui les consomment.

⚠️ **Les tables ne sont pas listées ici** (sauf quand une vue est un alias direct), uniquement les views.

---

## 📖 Convention "Statut"

- **CANONIQUE** : source de vérité à privilégier
- **LEGACY** : encore utilisée, à migrer progressivement
- **TECH** : vue technique (support/compat), pas une API métier

---

## 📊 Tableau récapitulatif

| Vue SQL | Statut | Source | Modules Flutter | Colonnes clés |
|---------|--------|--------|-----------------|---------------|
| `v_stock_actuel_snapshot` | 🟢 CANONIQUE | `stocks_snapshot` | `stocks_kpi_repository.dart`, `stocks_kpi_providers.dart` | `stock_ambiant`, `stock_15c` |
| `v_citerne_stock_snapshot_agg` | 🟢 CANONIQUE | `v_stock_actuel_snapshot` | `citerne_repository.dart`, `citerne_list_screen.dart` | `stock_ambiant_total`, `stock_15c_total` |
| `v_kpi_stock_global` | 🟢 CANONIQUE | `v_stock_actuel_snapshot` | `stocks_kpi_repository.dart`, `kpi_provider.dart` | `stock_ambiant_total`, `stock_*_monaluxe`, `stock_*_partenaire` |
| `v_mouvements_stock` | 🟢 CANONIQUE | `receptions`, `sorties_produit` | (Non utilisé actuellement) | `delta_ambiant`, `delta_15c` |
| `v_stock_actuel_owner_snapshot` | 🟡 LEGACY | `stocks_journaliers` | `stocks_kpi_repository.dart`, `stocks_kpi_providers.dart` | `stock_ambiant_total`, `stock_15c_total` |
| `v_citerne_stock_actuel` | 🔶 DEPRECATED | `stocks_journaliers` | `stocks_repository.dart`, `admin_kpi_provider.dart`, `directeur_kpi_provider.dart` | `stock_ambiant`, `stock_15c` |
| `stock_actuel` | 🔶 DEPRECATED | `stocks_journaliers` | `sortie_providers.dart`, `citerne_providers.dart`, `citerne_service.dart` | `stock_ambiant`, `stock_15c` |
| `logs` | 🟡 COMPAT | `log_actions` | `logs_service.dart`, `activites_recentes_provider.dart` | `id`, `created_at`, `module`, `action` |
| `current_user_profile` | ⚪ NON UTILISÉ | (Non utilisé) | - | `id`, `user_id`, `role`, `depot_id` |
| `cours_route` | 🟡 COMPAT | `cours_de_route` | (Non utilisé directement) | `id`, `plaques`, `statut`, `volume` |

---

## 1️⃣ Stock — Snapshot (temps réel)

---

### 1. v_stock_actuel_snapshot

**Statut** : 🟢 CANONIQUE

**Rôle** : Source de vérité "stock actuel" par citerne / produit / propriétaire, basée sur `stocks_snapshot`.

**Dépendances** :
- **Table** : `stocks_snapshot`, `citernes`, `produits`, `depots`

**Colonnes** :
- `citerne_id` (uuid)
- `citerne_nom` (text)
- `produit_id` (uuid)
- `produit_nom` (text)
- `depot_id` (uuid)
- `depot_nom` (text)
- `proprietaire_type` (text) ✅ MONALUXE|PARTENAIRE
- `stock_ambiant` (double precision)
- `stock_15c` (double precision)
- `updated_at` (timestamptz)
- `capacite_totale` (double precision)
- `capacite_securite` (double precision)

**Utilisation Flutter** :
- `lib/data/repositories/stocks_kpi_repository.dart` (`.from('v_stock_actuel_snapshot')`)
- `lib/features/stocks/data/stocks_kpi_providers.dart` (totaux stock dépôt)
- `lib/features/dashboard/widgets/role_dashboard.dart` (commenté "source de vérité")
- `lib/features/citernes/providers/citerne_providers.dart` (legacy provider qui l'utilise encore)

**Notes** :
- ✅ La vue existe bien en DB (confirmée)
- ❌ **NE DOIT JAMAIS être filtrée par date** (représente l'état actuel)
- ⚠️ `updated_at` est informatif, jamais une date métier
- ⚠️ Colonnes exposées : `stock_ambiant` / `stock_15c` (singulier, pas `*_total`)

**Exemple de requête** :
```sql
SELECT 
  citerne_id,
  citerne_nom,
  produit_id,
  produit_nom,
  depot_id,
  depot_nom,
  proprietaire_type,
  stock_ambiant,
  stock_15c,
  updated_at,
  capacite_totale,
  capacite_securite
FROM public.v_stock_actuel_snapshot
WHERE depot_id = 'xxx-xxx-xxx'
ORDER BY citerne_nom
LIMIT 5;
```

---

### 2. v_citerne_stock_snapshot_agg

**Statut** : 🟢 CANONIQUE (Citernes)

**Rôle** : Agrège `v_stock_actuel_snapshot` en stock total par citerne (somme sur propriétaires), utile pour l'écran Citernes.

**Dépendances** :
- **View** : `v_stock_actuel_snapshot`
- **Table** : `citernes`

**Colonnes** :
- `citerne_id` (uuid)
- `citerne_nom` (text)
- `depot_id` (uuid)
- `produit_id` (uuid)
- `stock_ambiant_total` (double precision)
- `stock_15c_total` (double precision)
- `last_snapshot_at` (timestamptz)

**Utilisation Flutter** :
- `lib/features/citernes/data/citerne_repository.dart`
- `lib/features/citernes/screens/citerne_list_screen.dart`

**Notes** :
- ✅ Vue strictement UI (affichage Citernes)
- ❌ Ne pas utiliser pour logique métier (pas de validation)
- ✅ Remplace définitivement `v_citerne_stock_actuel`

**Exemple de requête** :
```sql
SELECT 
  citerne_id,
  citerne_nom,
  depot_id,
  produit_id,
  stock_ambiant_total,
  stock_15c_total,
  last_snapshot_at
FROM public.v_citerne_stock_snapshot_agg
WHERE depot_id = 'xxx-xxx-xxx'
ORDER BY citerne_nom
LIMIT 5;
```

---

### 3. v_kpi_stock_global

**Statut** : 🟢 CANONIQUE (Dashboard KPI)

**Rôle** : KPI "stock global dépôt" + split MONALUXE/PARTENAIRE, basé sur snapshot.

**Dépendances** :
- **View** : `v_stock_actuel_snapshot`

**Colonnes** :
- `depot_id` (uuid)
- `depot_nom` (text)
- `produit_id` (uuid)
- `produit_nom` (text)
- `date_jour` (date) (dérivé de `updated_at`)
- `stock_ambiant_total` (double precision)
- `stock_15c_total` (double precision)
- `stock_ambiant_monaluxe` (double precision)
- `stock_15c_monaluxe` (double precision)
- `stock_ambiant_partenaire` (double precision)
- `stock_15c_partenaire` (double precision)

**Utilisation Flutter** :
- `lib/data/repositories/stocks_kpi_repository.dart` (`.from('v_kpi_stock_global')`)
- `lib/features/kpi/providers/kpi_provider.dart` ("Source de vérité… v_kpi_stock_global")

**Notes** :
- ⚠️ `date_jour` = date d'update (CAST de `updated_at`), pas date métier
- ✅ Vue **strictement visuelle** (KPI uniquement)
- ❌ Ne jamais utiliser pour contrôles métier

**Exemple de requête** :
```sql
SELECT 
  depot_id,
  depot_nom,
  produit_id,
  produit_nom,
  date_jour,
  stock_ambiant_total,
  stock_15c_total,
  stock_ambiant_monaluxe,
  stock_15c_monaluxe,
  stock_ambiant_partenaire,
  stock_15c_partenaire
FROM public.v_kpi_stock_global
WHERE depot_id = 'xxx-xxx-xxx'
LIMIT 5;
```

---

## 2️⃣ Stock — "Owner totals" (⚠️ journalier mais nommé snapshot)

---

### 4. v_stock_actuel_owner_snapshot

**Statut** : 🟡 LEGACY (à clarifier)

**Rôle** : Totaux dépôt par propriétaire et produit, mais calculés depuis `stocks_journaliers` (dernier jour disponible).

**Dépendances** :
- **Table** : `stocks_journaliers`, `citernes`, `depots`, `produits`

**Colonnes** :
- `depot_id` (uuid)
- `depot_nom` (text)
- `produit_id` (uuid)
- `produit_nom` (text)
- `proprietaire_type` (text)
- `date_jour` (date)
- `stock_ambiant_total` (double precision)
- `stock_15c_total` (double precision)

**Utilisation Flutter** :
- `lib/data/repositories/stocks_kpi_repository.dart` (`.from('v_stock_actuel_owner_snapshot')`)
- `lib/features/stocks/data/stocks_kpi_providers.dart` (breakdown owners)
- `lib/features/stocks/widgets/stocks_kpi_cards.dart` (`OwnerStockBreakdownCard`)
- `lib/features/dashboard/widgets/role_dashboard.dart` (détail propriétaire)

**Notes** :
- ⚠️ Le nom "snapshot" est trompeur : ce n'est PAS le moteur snapshot (`stocks_snapshot`)
- ⚠️ C'est une **reconstruction depuis le journal** (`stocks_journaliers`)
- ⚠️ Le champ `date_jour` est informatif (dernière date disponible), jamais filtrant
- ⚠️ Colonnes avec suffixe `_total` (différent de `v_stock_actuel_snapshot`)

**Recommandation doc** :
- Renommer conceptuellement dans la doc : **"owner totals journalier (dernier jour)"**
- (Option future) créer une vue owner totals snapshot pur basée sur `stocks_snapshot` pour éviter la dualité

**Exemple de requête** :
```sql
SELECT 
  depot_id,
  depot_nom,
  produit_id,
  produit_nom,
  proprietaire_type,
  date_jour,
  stock_ambiant_total,
  stock_15c_total
FROM public.v_stock_actuel_owner_snapshot
WHERE depot_id = 'xxx-xxx-xxx'
LIMIT 5;
```

---

## 3️⃣ Stock — Journalier (legacy)

---

### 5. stock_actuel

**Statut** : 🔶 LEGACY

**Rôle** : Dernier `stocks_journaliers` par citerne/produit (sans propriétaire).

**Dépendances** :
- **Table** : `stocks_journaliers`

**Colonnes** :
- `citerne_id` (uuid)
- `produit_id` (uuid)
- `date_jour` (date)
- `stock_ambiant` (float8)
- `stock_15c` (float8)

**Utilisation Flutter** :
- `lib/features/sorties/providers/sortie_providers.dart` (stock dans formulaire)
- `lib/features/citernes/providers/citerne_providers.dart` (legacy)
- `lib/features/citernes/data/citerne_service.dart` (legacy)
- (Probablement utilisé pour compat UI "dernier stock")

**Notes** :
- ⚠️ C'est basé sur `stocks_journaliers` → donc "dernier jour disponible", pas forcément "stock réel maintenant"
- ⚠️ Mélange "historique/journal" avec "stock actuel", ce qui a causé des incohérences
- ❌ Ne gère pas les propriétaires

**Exemple de requête** :
```sql
SELECT 
  citerne_id,
  produit_id,
  date_jour,
  stock_ambiant,
  stock_15c
FROM public.stock_actuel
WHERE citerne_id = 'xxx-xxx-xxx'
LIMIT 5;
```

---

### 6. v_citerne_stock_actuel

**Statut** : 🔶 LEGACY

**Rôle** : Dernier stock journalier par citerne/produit (agrège propriétaires du dernier jour).

**Dépendances** :
- **Table** : `stocks_journaliers`

**Colonnes** :
- `citerne_id` (uuid)
- `produit_id` (uuid)
- `date_jour` (date)
- `stock_ambiant` (float8)
- `stock_15c` (float8)

**Utilisation Flutter** :
- `lib/data/repositories/stocks_repository.dart`
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/dashboard/providers/directeur_kpi_provider.dart`
- `lib/features/dashboard/providers/citernes_sous_seuil_provider.dart`

**Notes** :
- ⚠️ C'est du journalier, pas du snapshot réel
- ⚠️ Incohérences possibles si plusieurs dates existent

**Exemple de requête** :
```sql
SELECT 
  citerne_id,
  produit_id,
  date_jour,
  stock_ambiant,
  stock_15c
FROM public.v_citerne_stock_actuel
WHERE citerne_id = 'xxx-xxx-xxx'
LIMIT 5;
```

---

## 4️⃣ Mouvements

---

### 7. v_mouvements_stock

**Statut** : 🟢 CANONIQUE (mouvements)

**Rôle** : Unifie Réceptions + Sorties (delta + / -) par jour, citerne, produit, dépôt, propriétaire.

**Dépendances** :
- **Tables** : `receptions`, `sorties_produit`, `citernes`

**Colonnes** :
- `date_jour` (date)
- `citerne_id` (uuid)
- `produit_id` (uuid)
- `depot_id` (uuid)
- `proprietaire_type` (text)
- `delta_ambiant` (double precision)
- `delta_15c` (double precision)

**Utilisation Flutter** :
- ➡️ (Pas encore détectée dans rg fourni) → à brancher si besoin (module "mouvements du jour")

**Notes** :
- ✅ `date_jour` = date métier
- ✅ Utile pour "aujourd'hui", "semaine", "période"
- ❌ Pas une vue de stock "actuel" (c'est des deltas)

**Exemple de requête** :
```sql
SELECT 
  date_jour,
  citerne_id,
  produit_id,
  depot_id,
  proprietaire_type,
  delta_ambiant,
  delta_15c
FROM public.v_mouvements_stock
WHERE date_jour >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY date_jour DESC, citerne_id
LIMIT 5;
```

---

## 5️⃣ Logs

---

### 8. logs

**Statut** : 🔧 TECH (compat)

**Rôle** : Vue de compat sur `log_actions` (pour simplifier l'accès côté app).

**Dépendances** :
- **Table** : `log_actions`

**Colonnes** :
- `id` (uuid)
- `created_at` (timestamptz)
- `module` (text)
- `action` (text)
- `niveau` (text)
- `user_id` (uuid)
- `details` (jsonb)

**Utilisation Flutter** :
- `lib/features/logs/services/logs_service.dart` (`.from('logs')`)
- `lib/features/dashboard/providers/activites_recentes_provider.dart`
- `lib/features/dashboard/providers/admin_kpi_provider.dart`

**Notes** :
- ✅ Vue stable et utile
- ✅ Pas concernée par la logique stock
- ✅ À conserver

**Exemple de requête** :
```sql
SELECT 
  id,
  created_at,
  module,
  action,
  niveau,
  user_id,
  details
FROM public.logs
ORDER BY created_at DESC
LIMIT 5;
```

---

## 6️⃣ Auth / Profil

---

### 9. current_user_profile

**Statut** : 🔧 TECH

**Rôle** : Expose le profil de l'utilisateur courant (`auth.uid()`).

**Dépendances** :
- **Tables** : `auth.users`, `profils`

**Contrat colonnes** :
- `id` (uuid)
- `user_id` (uuid)
- `nom_complet` (text)
- `role` (text)
- `depot_id` (uuid)
- `email` (text)
- `created_at` (timestamptz)

**Utilisation Flutter** :
- ➡️ (Pas détectée dans rg fourni) — possible usage futur / SQL direct

**Exemple de requête** :
```sql
SELECT 
  id,
  user_id,
  nom_complet,
  role,
  depot_id,
  email,
  created_at
FROM public.current_user_profile
LIMIT 5;
```

---

## 7️⃣ Cours de route (compat)

---

### 10. cours_route

**Statut** : 🔧 TECH/LEGACY

**Rôle** : Vue "formatée" de `cours_de_route` avec champs UI (plaques concat, chauffeur, etc.)

**Dépendances** :
- **Table** : `cours_de_route`

**Contrat colonnes** :
- `id` (uuid)
- `fournisseur_id` (uuid)
- `depot_destination_id` (uuid)
- `produit_id` (uuid)
- `plaques` (text)
- `chauffeur` (text)
- `transporteur` (text)
- `volume` (numeric)
- `statut` (text)
- `date` (date) - alias `date_chargement`
- `created_at` (timestamptz)

**Utilisation Flutter** :
- ➡️ (Pas détectée dans rg fourni) — le code utilise plutôt la table `cours_de_route`

**Exemple de requête** :
```sql
SELECT 
  id,
  fournisseur_id,
  depot_destination_id,
  produit_id,
  plaques,
  chauffeur,
  transporteur,
  volume,
  statut,
  date,
  created_at
FROM public.cours_route
ORDER BY created_at DESC
LIMIT 5;
```

---

## 📝 Résumé décisions (à garder en tête)

### ✅ Stock "maintenant" (écrans/deciders) = snapshot

Pour tous les écrans et décisions nécessitant le stock actuel réel :
- `v_stock_actuel_snapshot` (par citerne/produit/propriétaire)
- `v_citerne_stock_snapshot_agg` (par citerne, agrégé)
- `v_kpi_stock_global` (par dépôt, split propriétaire)

### ⚠️ Legacy journalier (encore utilisé)

- `stock_actuel` et `v_citerne_stock_actuel` = legacy journalier, encore utilisés par Dashboard + Sorties UI
- À migrer progressivement vers snapshot

### ⚠️ v_stock_actuel_owner_snapshot (confusion naming)

- `v_stock_actuel_owner_snapshot` est journalier mais porte un nom "snapshot"
- **À documenter clairement** pour éviter confusion
- À terme, créer une vraie vue owner snapshot-based

### 📝 Notes techniques

#### Divergences de naming (stock_ambiant vs stock_ambiant_total)

Les vues exposent des colonnes avec des noms différents :

- **`v_stock_actuel_snapshot`** : `stock_ambiant`, `stock_15c` (singulier)
- **`v_citerne_stock_snapshot_agg`** : `stock_ambiant_total`, `stock_15c_total` (avec suffixe `_total`)
- **`v_kpi_stock_global`** : `stock_ambiant_total`, `stock_15c_total` + `stock_ambiant_monaluxe`, etc.
- **`v_stock_actuel_owner_snapshot`** : `stock_ambiant_total`, `stock_15c_total` (avec suffixe `_total`)
- **Vues legacy** (`v_citerne_stock_actuel`, `stock_actuel`) : `stock_ambiant`, `stock_15c` (singulier)

**Garde-fous côté Dart** :
- Le code Flutter utilise souvent `_safeDouble()` qui accepte les deux noms en fallback
- Exemple : `_safeDouble(row['stock_ambiant_total'] ?? row['stock_ambiant'])`

### Snapshot vs Journalier

- **Snapshot** (`v_stock_actuel_snapshot`) : Stock réel présent maintenant, alimenté par triggers
- **Journalier** (`v_stock_actuel_owner_snapshot`, `v_citerne_stock_actuel`, `stock_actuel`) : Basé sur `stocks_journaliers`, peut avoir des trous de dates, dépend de la dernière date disponible

### Date vs updated_at

- **`date_jour`** : Date métier (utilisée dans `v_mouvements_stock` pour filtrer par période)
- **`updated_at`** : Timestamp technique de dernière mise à jour (informatif uniquement dans `v_stock_actuel_snapshot`)
- ⚠️ Ne jamais filtrer `v_stock_actuel_snapshot` par date (utiliser `v_mouvements_stock` pour historique)

---

## 🔗 Références

- **Migrations SQL** : `supabase/migrations/`
- **Repository Flutter principal** : `lib/data/repositories/stocks_kpi_repository.dart`
- **Providers Flutter** : `lib/features/stocks/data/stocks_kpi_providers.dart`
- **Documentation technique** : `docs/db/stocks_views_contract.md`
- **Documentation centralisée** : `docs/db/vues_sql_reference_central.md`
- **Cartographie Flutter → DB** : `docs/db/flutter_db_usage_map.md` (mapping détaillé des usages réels)
- **Cartographie par modules** : `docs/db/modules_flutter_db_map.md` (organisation par module fonctionnel)

---

**Dernière mise à jour** : 2025-12-27
