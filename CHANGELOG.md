# 📝 Changelog

Ce fichier documente les changements notables du projet **ML_PP MVP**, conformément aux bonnes pratiques de versionnage sémantique.

## [Unreleased]

### Added
- **DB View:** `public.logs` (compat pour code existant pointant vers `logs`, mappée à `public.log_actions`).
- **DB View:** `public.v_citerne_stock_actuel` (renvoie le dernier stock par citerne via `stocks_journaliers`).
- **Docs:** Pages dédiées aux vues & RLS + notes d'usage pour KPIs Admin/Directeur.
- **Migration (référence):** script SQL pour (re)créer les vues et RLS.
- **KPI "Camions à suivre"** : Architecture modulaire avec repository, provider family et widget générique réutilisable.
- **KPI "Réceptions (jour)"** : Affichage du nombre de camions déchargés avec volumes ambiant et 15°C.
- **Architecture KPI scalable** : Modèles, repositories, providers et widgets génériques pour tous les rôles.
- **Utilitaires de formatage** : Fonction `fmtCompact()` pour affichage compact des volumes.

### 🚀 **SYSTÈME DE WORKFLOW CDR P0** *(Nouveau)*

#### **Gestion d'état des cours de route**
- **Enum `CdrEtat`** : 4 états (planifié, en cours, terminé, annulé) avec matrice de transitions
- **API de transition gardée** : Méthodes `canTransition()` et `applyTransition()` avec validation métier
- **UI de gestion d'état** : Boutons de transition dans l'écran de détail avec validation visuelle
- **Audit des transitions** : Service de logging `CdrLogsService` pour traçabilité complète
- **KPI dashboard** : 4 chips d'état (planifié, en cours, terminé, annulé) dans le dashboard principal

#### **Validations métier intégrées**
- **Transition planifié → terminé** : Interdite (doit passer par "en cours")
- **Transition vers "en cours"** : Vérification des champs requis (chauffeur, citerne)
- **Gestion d'erreur robuste** : Logging best-effort sans faire échouer les transitions

#### **Architecture technique**
- **Modèle d'état** : `lib/features/cours_route/models/cdr_etat.dart`
- **Service de logs** : `lib/features/cours_route/data/cdr_logs_service.dart`
- **Provider KPI** : `lib/features/cours_route/providers/cdr_kpi_provider.dart`
- **Widget KPI** : `CdrKpiTiles` dans le dashboard
- **UI transitions** : Boutons d'état dans `cours_route_detail_screen.dart`

### Changed
- **KPIs Admin/Directeur (app):** lecture du stock courant via `v_citerne_stock_actuel`.  
- **Filtres date/heure (app):** 
  - `receptions.date_reception` (TYPE `date`) → filtre par égalité sur **YYYY-MM-DD** (jour en UTC).  
  - `sorties_produit.date_sortie` (TIMESTAMPTZ) → filtre **[dayStartUTC, dayEndUTC)**.
- **Service CDR** : Ajout des méthodes de transition d'état et KPI avec intégration du service de logs
- **Dashboard principal** : Intégration du widget `CdrKpiTiles` pour affichage des KPIs d'état CDR
- **Annotations JsonKey** : Migration des annotations dépréciées `@JsonKey(ignore: true)` vers `@JsonKey(includeFromJson: false, includeToJson: false)`
- **Génériques Supabase** : Ajout d'arguments de type explicites pour résoudre les warnings d'inférence de type

### Fixed
- **Assertion non-null inutile** : Suppression de `nextEnum!` dans `cours_route_list_screen.dart` pour réduire le bruit de l'analyzer
- **Annotations JsonKey dépréciées** : Correction dans `cours_de_route.dart` pour éviter les warnings de compilation
- **Inférence de type Supabase** : Ajout de génériques explicites pour résoudre les warnings `inference_failure_on_function_invocation`
- Redirection post-login désormais fiable : `GoRouter` branché sur le stream d'auth via `refreshListenable: GoRouterRefreshStream(authStream)`.
- Alignement avec `userRoleProvider` (nullable) : pas de fallback prématuré, attente propre du rôle avant redirection.
- Conflit d'imports résolu : `supabase_flutter` avec `hide Provider` pour éviter l'ambiguïté avec `riverpod.Provider`.
- **Redirection post-login déterministe** : `GoRouterCompositeRefresh` combine les événements d'auth ET les changements de rôle pour une redirection fiable.
- **Erreurs de compilation corrigées** : `WidgetRef` non trouvé, `debugPrint` manquant, types `ProviderRef` vs `WidgetRef`, paramètre `fireImmediately` non supporté.
- **Patch réactivité profil/rôle** : `currentProfilProvider` lié à `currentUserProvider` pour se reconstruire sur changement d'auth et débloquer `/splash`.
- **Correctif définitif /splash** : `reactiveUserProvider` basé sur `appAuthStateProvider` (réactif) au lieu de `currentUserProvider` (snapshot figé), avec `SplashScreen` auto-sortie.
- **Correctif final redirection par rôle** : `ref.listen` déplacé dans `build()`, redirect sans valeurs capturées, cohérence ROLE sans fallback "lecture", logs ciblés pour traçage.
- Erreur `42P01: relation "public.logs" does not exist` en Admin (vue de compatibilité).
- KPIs Directeur incohérents (bornes UTC + stock courant fiable).
- **Erreurs de compilation Admin/Directeur** : Type `ActiviteRecente` manquant, méthodes Supabase incorrectes, paramètres `start`/`startUtc` incohérents.
- **Corrections finales compilation** : Import `ActiviteRecente` dans dashboard_directeur_screen, getters `createdAtFmt` et `userName` ajoutés, méthodes Supabase avec `PostgrestFilterBuilder`.
- **Corrections types finaux** : `activite.details.toString()` pour affichage Map, `var query` pour chaînage Supabase correct.
- **Filtres côté client** : Remplacement des filtres Supabase problématiques par des filtres Dart côté client pour logs_service.
- **Crash layout Admin** : Correction du conflit `RenderFlex` causé par `Spacer()` imbriqué dans `SectionTitle` utilisé dans un `Row` parent.
- **Conflit d'imports Provider** : Résolution du conflit entre `gotrue` et `riverpod` avec alias d'import.

### Notes
- **RLS sur vues :** non supporté. Les policies sont appliquées **sur les tables sources** (`log_actions`, `stocks_journaliers`, `citernes`).  
- Les vues sont **read-only** ; aucune policy créée dessus.  
- Aucune rupture : `public.logs` conserve les noms de colonnes attendus par l'app.

## [1.0.13] - 2025-09-08 — Correction encodage UTF-8 & unification Auth

### 🔧 **CORRECTION ENCODAGE UTF-8**

#### ✅ **PROBLÈMES IDENTIFIÉS**
- **Caractères corrompus** : RÃ´le, EntrÃ©es, DÃ©pÃ´t (Windows-1252 lu comme UTF-8)
- **Encodage incohérent** : Mélange d'encodages dans les fichiers
- **Providers Auth dupliqués** : `auth_provider.dart` et `auth_service_provider.dart`
- **Interface dégradée** : Affichage incorrect des accents français

#### 🎯 **CORRECTIONS APPLIQUÉES**

##### **Configuration UTF-8**
- **VS Code** : `.vscode/settings.json` - Force l'encodage UTF-8
- **Git** : `.gitattributes` - Normalisation automatique des fins de ligne et encodage
- **Fins de ligne** : LF (Unix) pour cohérence cross-platform

##### **Reconversion des fichiers**
- **Script PowerShell** : `tools/recode-to-utf8.ps1` - Reconversion automatique
- **Tous les fichiers** : `.dart`, `.yaml`, `.md`, `.json` traités
- **Encodage uniforme** : UTF-8 sans BOM pour tous les fichiers texte

##### **Correction des chaînes corrompues**
- **Script automatique** : `tools/fix-strings.ps1` - Remplacement des caractères corrompus
- **Corrections appliquées** :
  - `RÃ´le` → `Rôle`
  - `EntrÃ©es` → `Entrées`
  - `DÃ©pÃ´t` → `Dépôt`
  - `RÃ©ceptions` → `Réceptions`
  - `Connexion rÃ©ussie` → `Connexion réussie`
  - `Aucun profil trouvÃ©` → `Aucun profil trouvé`

##### **Unification des providers Auth**
- **Suppression** : `lib/shared/providers/auth_provider.dart` (doublon)
- **Migration** : Vers `lib/shared/providers/auth_service_provider.dart`
- **Mise à jour** : Tous les imports dans les fichiers consommateurs
- **Cohérence** : Un seul provider Auth dans tout le projet

##### **Garde-fous CI/CD**
- **Script de vérification** : `tools/check-utf8.mjs` - Détection automatique des problèmes d'encodage
- **Scripts npm** : `package.json` avec commandes de maintenance
- **Prévention** : Évite la réintroduction de problèmes d'encodage

#### 🔒 **LOGIQUE MÉTIER PRÉSERVÉE À 100%**
- ✅ **Fonctionnalités** intactes
- ✅ **Providers Riverpod** maintenus