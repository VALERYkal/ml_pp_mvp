# Cartographie Flutter → DB (tables / vues / RPC)

**Date** : 2025-12-27  
**Version** : 1.0  
**Objectif** : Documenter les usages réels de chaque table/vue/RPC côté Flutter, basé sur `ripgrep`

---

## Stocks & KPI (cœur du sujet)

### public.v_stock_actuel_snapshot (snapshot temps réel – canonique)

**Statut** : 🟢 CANONIQUE

**Usages Flutter** :

- `lib/data/repositories/stocks_kpi_repository.dart`
  - Source principale "stock actuel" (par citerne/propriétaire) + mapping clés `stock_ambiant(_total)` / `stock_15c(_total)`

- `lib/features/stocks/data/stocks_kpi_providers.dart`
  - Totaux stock dépôt (agrégation côté app)

- `lib/features/dashboard/widgets/role_dashboard.dart`
  - Commenté comme "source de vérité" pour KPI stock total (via providers)

---

### public.v_kpi_stock_global (KPI stock global – canonique)

**Statut** : 🟢 CANONIQUE

**Usages Flutter** :

- `lib/data/repositories/stocks_kpi_repository.dart`

- `lib/features/kpi/providers/kpi_provider.dart`
  - Commentaire : "agrégé par la DB via v_kpi_stock_global"

---

### public.v_stock_actuel_owner_snapshot (owner totals depuis journalier – legacy mal nommé)

**Statut** : 🟡 LEGACY (mal nommé : ce n'est pas un snapshot temps réel)

**Usages Flutter** :

- `lib/data/repositories/stocks_kpi_repository.dart`

- `lib/features/stocks/data/stocks_kpi_providers.dart`
  - Utilisé par `OwnerStockBreakdownCard` (via providers)

---

### public.v_citerne_stock_snapshot_agg (canonique Citernes)

**Statut** : 🟢 CANONIQUE

**Usages Flutter** :

- `lib/features/citernes/data/citerne_repository.dart`

- `lib/features/citernes/domain/citerne_stock_snapshot.dart`

- `lib/features/citernes/screens/citerne_list_screen.dart`

---

### public.v_citerne_stock_actuel (legacy journalier)

**Statut** : 🔶 LEGACY

**Usages Flutter** :

- `lib/data/repositories/stocks_repository.dart`

- `lib/features/dashboard/providers/admin_kpi_provider.dart`

- `lib/features/dashboard/providers/directeur_kpi_provider.dart`

- `lib/features/dashboard/providers/citernes_sous_seuil_provider.dart`

---

### public.stock_actuel (legacy journalier)

**Statut** : 🔶 LEGACY

**Usages Flutter** :

- `lib/features/citernes/providers/citerne_providers.dart` (legacy provider)

- `lib/features/citernes/data/citerne_service.dart` (legacy)

- `lib/features/sorties/providers/sortie_providers.dart` (citerne + dernier stock legacy)

---

### public.stocks_journaliers (table – historique)

**Statut** : 📊 TABLE (historique)

**Usages Flutter** :

- `lib/data/repositories/stocks_kpi_repository.dart` (lecture directe historique)

⚠️ **Note** : Tout ce qui est "par date" doit rester ici, pas sur snapshot

---

## Sorties

### public.sorties_produit (table)

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/data/repositories/sorties_repository.dart`

- `lib/features/sorties/data/sortie_draft_service.dart` (insert)

- `lib/features/sorties/data/sortie_service.dart` (queries diverses)

- `lib/features/sorties/kpi/sorties_kpi_repository.dart`

- `lib/features/sorties/providers/sortie_providers.dart`

- `lib/features/sorties/providers/sorties_table_provider.dart`

**Dashboard providers** :

- `lib/features/dashboard/providers/admin_kpi_provider.dart`

- `lib/features/dashboard/providers/directeur_kpi_provider.dart`

✅ **Point critique (DB-STRICT)** : L'app insère `sorties_produit` (draft ou validated selon flow).  
Si DB-STRICT impose une RPC `validate_sortie(id)`, il faudra aligner `sortie_draft_service.dart` / `sortie_service.dart`.

---

## Réceptions

### public.receptions (table)

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/data/repositories/receptions_repository.dart`

- `lib/shared/db/db_port.dart` (insert + rpc('validate_reception'))

- `lib/features/receptions/kpi/receptions_kpi_repository.dart`

- `lib/features/receptions/providers/receptions_table_provider.dart`

- `lib/features/receptions/providers/receptions_list_provider.dart`

- `lib/features/receptions/data/reception_service.dart`

**Dashboard providers** :

- `lib/features/dashboard/providers/admin_kpi_provider.dart`

- `lib/features/dashboard/providers/directeur_kpi_provider.dart`

- `lib/features/kpi/providers/kpi_provider.dart`

---

### RPC : public.validate_reception

**Usages Flutter** :

- `lib/shared/db/db_port.dart`

---

## Logs / Audit

### public.logs (vue compat)

**Statut** : 🟡 COMPAT

**Usages Flutter** :

- `lib/features/logs/services/logs_service.dart`

- `lib/features/dashboard/providers/activites_recentes_provider.dart`

- `lib/features/dashboard/providers/admin_kpi_provider.dart` (lit logs)

- `lib/features/dashboard/providers/directeur_kpi_provider.dart` (lit logs)

---

### public.log_actions (table)

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/features/sorties/data/sortie_draft_service.dart` (insert log_actions)

- `lib/features/logs/providers/logs_providers.dart` (select log_actions + joins ref)

---

## Référentiels / sécurité / profils

### public.profils

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/shared/referentiels/role_provider.dart`

- `lib/features/profil/data/profil_service.dart`

- `lib/features/logs/providers/logs_providers.dart` (join/lookup)

---

### public.citernes

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/data/repositories/stocks_repository.dart`

- `lib/shared/db/db_port.dart`

- `lib/shared/referentiels/referentiels.dart`

- `lib/features/receptions/data/citerne_info_provider.dart`

- `lib/features/sorties/data/sortie_draft_service.dart`

- `lib/features/sorties/providers/sortie_providers.dart`

- `lib/features/dashboard/providers/admin_kpi_provider.dart`

- `lib/features/dashboard/providers/directeur_kpi_provider.dart`

- `lib/features/dashboard/providers/citernes_sous_seuil_provider.dart`

- `lib/features/citernes/providers/citerne_providers.dart`

- `lib/features/citernes/data/citerne_service.dart`

---

### public.produits

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/shared/db/db_port.dart`

- `lib/shared/providers/ref_data_provider.dart`

- `lib/shared/referentiels/referentiels.dart`

- `lib/features/sorties/providers/sortie_providers.dart`

- `lib/features/citernes/providers/citerne_providers.dart`

---

### public.depots

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/data/repositories/depots_repository.dart`

- `lib/shared/providers/ref_data_provider.dart`

- `lib/data/repositories/stocks_kpi_repository.dart`

---

### public.clients / public.partenaires

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/features/sorties/providers/sortie_providers.dart`

- `lib/features/sorties/providers/sorties_table_provider.dart`

- `lib/features/receptions/providers/receptions_table_provider.dart`

- `lib/features/receptions/data/partenaires_provider.dart`

---

## Cours de route

### public.cours_de_route

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/data/repositories/cours_de_route_repository.dart`

- `lib/features/receptions/data/cours_arrives_provider.dart`

- `lib/features/receptions/providers/receptions_table_provider.dart`

- `lib/features/receptions/screens/reception_form_screen.dart`

- `lib/features/cours_route/data/cours_de_route_service.dart`

- `lib/features/kpi/providers/kpi_provider.dart`

---

### public.cdr_logs

**Statut** : 📊 TABLE

**Usages Flutter** :

- `lib/features/cours_route/data/cdr_logs_service.dart`

---

## ⚠️ Risques / Incohérences déjà visibles

### Double système Stock

**Problème** : `v_citerne_stock_actuel` / `stock_actuel` (journalier) cohabite avec `v_stock_actuel_snapshot` (temps réel).

**Impact** : Tous les widgets "stock présent maintenant" doivent migrer vers snapshot, sinon incohérences.

**Action** : Migrer progressivement vers les vues snapshot canoniques.

---

### v_stock_actuel_owner_snapshot n'est pas "snapshot temps réel"

**Problème** : `v_stock_actuel_owner_snapshot` n'est pas un "snapshot temps réel" (il est basé sur `stocks_journaliers`).

**Impact** : Confusion possible, décalage potentiel entre "stock actuel" et "dernier journal disponible".

**Action** : À renommer ou remplacer plus tard par une vue owner basée sur `stocks_snapshot`.

---

## 🔗 Références

- **Documentation vues SQL** : `docs/db/vues_sql_reference.md`
- **Documentation centralisée** : `docs/db/vues_sql_reference_central.md`
- **Cartographie par modules** : `docs/db/modules_flutter_db_map.md` (organisation par module fonctionnel)

---

**Dernière mise à jour** : 2025-12-27

