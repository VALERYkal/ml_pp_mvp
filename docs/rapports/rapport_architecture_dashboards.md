#  RAPPORT TECHNIQUE - ARCHITECTURE DES DASHBOARDS
## ML_PP MVP - Système de Gestion Logistique Pétrolière

---

** Date :** 17 septembre 2025  
** Équipe :** Développement ML_PP MVP  
** Version :** 2.0.0  
** Statut :**  Production  

---

##  RÉSUMÉ EXÉCUTIF

Ce rapport présente l'architecture complète du système de dashboards de ML_PP MVP, une application Flutter de gestion logistique pour produits pétroliers. Le système fournit des indicateurs clés de performance (KPIs) en temps réel pour 6 rôles utilisateurs différents, avec une architecture modulaire et scalable.

###  Objectifs Atteints
-  **Interface unifiée** : Dashboards cohérents pour tous les rôles
-  **Performance optimisée** : Chargement rapide avec cache intelligent
-  **Responsive design** : Adaptation automatique mobile/desktop
-  **Architecture modulaire** : Composants réutilisables et maintenables
-  **Temps réel** : Mise à jour automatique des données

---

##  ARCHITECTURE TECHNIQUE

### 1. Structure Modulaire

`
lib/features/dashboard/
 screens/                    # 6 dashboards spécialisés par rôle
    dashboard_admin_screen.dart      # Admin complet
    dashboard_operateur_screen.dart  # Opérateur avec actions rapides
    dashboard_directeur_screen.dart # Directeur (via RoleDashboard)
    dashboard_gerant_screen.dart    # Gérant (via RoleDashboard)
    dashboard_pca_screen.dart       # PCA (via RoleDashboard)
    dashboard_lecture_screen.dart   # Lecture seule (via RoleDashboard)
 widgets/                    # Composants réutilisables
    role_dashboard.dart     # Dashboard commun (4 rôles)
    kpi_tiles.dart         # Widgets KPI spécialisés
    dashboard_shell.dart    # Shell responsive
 providers/                  # Gestion d'état et logique métier
    admin_trends_provider.dart      # Graphiques tendances
    activites_recentes_provider.dart # Logs système
    admin_kpi_provider.dart         # KPIs admin
    directeur_kpi_provider.dart     # KPIs directeur
    citernes_sous_seuil_provider.dart # Alertes citernes
 models/                     # Modèles de données
     activite_recente.dart

lib/features/kpi/               # Système KPI centralisé
 providers/                  # 5 providers KPI spécialisés
    cours_kpi_provider.dart         # Camions en route/attente
    receptions_kpi_provider.dart    # Réceptions du jour
    stocks_kpi_provider.dart        # Stocks actuels
    sorties_kpi_provider.dart       # Sorties du jour
    balance_kpi_provider.dart       # Balance (réceptions-sorties)
 models/                     # Modèles KPI
    kpi_models.dart
 widgets/                    # Widgets KPI
     kpi_summary_card.dart
     kpi_split_card.dart

lib/shared/ui/modern_components/ # Composants UI modernes
 modern_kpi_card.dart        # Carte KPI avec animations Material 3
 dashboard_grid.dart         # Grille responsive adaptative
 dashboard_header.dart       # En-tête avec salutation personnalisée
`

### 2. Gestion d'État avec Riverpod

#### Providers Principaux
- **coursKpiProvider** : Données des camions en route et en attente
- **receptionsKpiProvider** : Statistiques des réceptions du jour
- **stocksTotalsProvider** : Totaux des stocks actuels
- **sortiesKpiProvider** : Statistiques des sorties du jour
- **balanceTodayProvider** : Calcul de la balance (réceptions - sorties)

#### Invalidation Temps Réel
`dart
// Providers d'invalidation pour mise à jour automatique
ref.watch(coursRealtimeInvalidatorProvider);
ref.watch(stocksRealtimeInvalidatorProvider);
ref.watch(sortiesRealtimeInvalidatorProvider);
`

#### Filtrage Automatique par Profil
`dart
// Paramètres automatiques selon le profil utilisateur
final coursParam = ref.watch(coursDefaultParamProvider);
final depotId = profil?.depotId; // Filtrage automatique par dépôt
`

### 3. Composants UI Modernes

#### ModernKpiCard
- **Design Material 3** avec gradients et ombres
- **Animations** : Scale et fade au tap
- **Métriques détaillées** : Affichage de sous-métriques
- **Navigation** : Tap pour aller aux détails
- **États** : Loading, Error, Data avec gestion appropriée

#### DashboardGrid
- **Responsive** : Adaptation automatique selon la taille d'écran
- **Breakpoints** : Mobile (1 col), Tablet (2 cols), Desktop (3 cols)
- **Espacement** : Marges et padding adaptatifs

#### DashboardSection
- **Titres hiérarchisés** : Titre principal + sous-titre
- **Actions contextuelles** : Boutons d'action optionnels
- **Espacement cohérent** : Marges standardisées

---

##  DASHBOARDS PAR RÔLE

### 1. Dashboard Admin (dashboard_admin_screen.dart)

#### Sections Spécifiques
1. **Vue d'ensemble** : Camions à suivre, Stock total, Balance du jour
2. **Activités du jour** : Réceptions et sorties
3. **Tendances 7 jours** : Graphique en aires (AreaChart)
4. **À surveiller** : Table des citernes sous seuil critique
5. **Activité récente** : Logs système des 24h avec export CSV
6. **Actions rapides** : Bouton flottant pour actions courantes

#### Providers Spécialisés
- **adminTrends7dProvider** : Données pour graphique tendances
- **activitesRecentesProvider** : Logs système récents
- **citernesSousSeuilProvider** : Citernes nécessitant attention

#### Fonctionnalités Avancées
- **Export CSV** : Export des logs d'activité
- **Surveillance** : Alertes sur citernes critiques
- **Analytics** : Graphiques de tendances

### 2. Dashboard Opérateur (dashboard_operateur_screen.dart)

#### Sections Spécifiques
1. **Vue d'ensemble** : Camions à suivre, Stock total, Balance du jour
2. **Activités du jour** : Réceptions et sorties
3. **Accès rapide** : Boutons pour créer cours, réception, sortie

#### Fonctionnalités Opérationnelles
- **Actions rapides** : Interface simplifiée pour les tâches courantes
- **Navigation directe** : Accès immédiat aux formulaires de création
- **Interface focalisée** : Design épuré pour l'efficacité opérationnelle

### 3. Dashboards Autres Rôles (role_dashboard.dart)

#### Rôles Utilisant RoleDashboard
- **Directeur** : Vue globale avec filtrage par dépôt
- **Gérant** : Vue du dépôt avec KPIs locaux
- **PCA** : Vue de contrôle avec métriques clés
- **Lecture** : Vue en lecture seule

#### Sections Communes
1. **Vue d'ensemble** : Camions à suivre, Stock total, Balance du jour
2. **Activités du jour** : Réceptions et sorties

---

##  ARCHITECTURE MÉTIER

### 1. KPIs Principaux

#### Camions à suivre
- **Données** : Nombre total (en route + en attente)
- **Volumes** : Volume total prévu (ambiant + 15C)
- **Détails** : Répartition par statut
- **Source** : Table cours_de_route avec filtrage par statut

#### Stock total
- **Données** : Volume ambiant et 15C actuels
- **Métadonnées** : Dernière mise à jour
- **Source** : Vue v_citerne_stock_actuel agrégée

#### Balance du jour
- **Calcul** : Réceptions - Sorties
- **Indicateur** : Positif (vert) ou négatif (rouge)
- **Tendance** : Pourcentage d'évolution
- **Source** : Agrégation des tables réceptions et sorties_produit

#### Réceptions du jour
- **Données** : Nombre de camions reçus
- **Volumes** : Volume ambiant et 15C
- **Source** : Table réceptions filtrée par date et statut

#### Sorties du jour
- **Données** : Nombre de camions sortis
- **Volumes** : Volume ambiant et 15C
- **Source** : Table sorties_produit filtrée par date et statut

### 2. Logique Métier

#### Filtrage Automatique
- **Par dépôt** : Selon le profil utilisateur
- **Par date** : Jour courant en UTC
- **Par statut** : Seulement les données validées

#### Calculs de Volumes
- **Priorité 15C** : Si disponible, sinon volume ambiant
- **Agrégation** : Somme des volumes par période
- **Conversion** : Formatage automatique (L, kL, ML)

#### Gestion des États
- **Loading** : Indicateurs de chargement
- **Error** : Gestion d'erreur avec retry
- **Data** : Affichage des données avec formatage

### 3. Sources de Données

#### Tables Principales
- **cours_de_route** : État des camions et volumes prévus
- **réceptions** : Réceptions validées avec volumes
- **sorties_produit** : Sorties validées avec volumes
- **stocks_journaliers** : Historique des stocks par citerne
- **citernes** : Capacités et seuils de sécurité

#### Vues Spécialisées
- **v_citerne_stock_actuel** : Dernier stock par citerne
- **logs** : Activité système (vue de compatibilité)

#### Filtres Temporels
- **Réceptions** : Filtrage par date_reception (TYPE DATE)
- **Sorties** : Filtrage par date_sortie (TIMESTAMPTZ)
- **Logs** : Filtrage par created_at (TIMESTAMPTZ)

---

##  FONCTIONNALITÉS AVANCÉES

### 1. Temps Réel
- **Invalidation automatique** : Mise à jour des KPIs lors des changements
- **Providers réactifs** : Réaction aux modifications de données
- **Cache intelligent** : Évite les requêtes inutiles

### 2. Responsive Design
- **Breakpoints** : Mobile (<800px), Tablet (800-1199px), Desktop (1200px)
- **Grilles adaptatives** : Nombre de colonnes selon l'écran
- **Composants flexibles** : Adaptation automatique du contenu

### 3. Performance
- **Lazy loading** : Chargement à la demande
- **Mémorisation** : Cache des données calculées
- **Optimisation** : Requêtes SQL optimisées

### 4. Accessibilité
- **Navigation clavier** : Support des raccourcis
- **Contraste** : Couleurs contrastées pour la lisibilité
- **Icônes** : Icônes explicites pour chaque métrique

---

##  POINTS D'ATTENTION TECHNIQUE

### 1. Gestion des Erreurs
`dart
// Pattern standard pour tous les KPIs
final kpiData = kpiState.when(
  data: (d) => ModernKpiCard(...),
  loading: () => _buildLoadingCard(...),
  error: (_, __) => _buildErrorCard(...),
);
`

### 2. Formatage des Données
`dart
// Utilitaires de formatage centralisés
fmtLiters(volume)           // Formatage des volumes
fmtShortDate(date)          // Formatage des dates
fmtLitersSigned(delta)      // Formatage avec signe
`

### 3. Navigation
`dart
// Navigation contextuelle
onTap: () => context.go('/cours'),     // Vers les cours
onTap: () => context.go('/réceptions'), // Vers les réceptions
onTap: () => context.go('/stocks'),     // Vers les stocks
`

### 4. États de Chargement
- **Shimmer effects** : Indicateurs visuels de chargement
- **Skeleton screens** : Structure visible pendant le chargement
- **Error boundaries** : Gestion gracieuse des erreurs

---

##  MÉTRIQUES ET MONITORING

### 1. KPIs Techniques
- **Temps de chargement** : Performance des requêtes
- **Taux de cache** : Efficacité du cache
- **Erreurs** : Monitoring des erreurs de chargement

### 2. KPIs Métier
- **Camions en transit** : Suivi opérationnel
- **Volumes traités** : Capacité opérationnelle
- **Balance** : Équilibre entrées/sorties
- **Alertes** : Citernes sous seuil

---

##  MAINTENANCE ET ÉVOLUTION

### 1. Ajout de Nouveaux KPIs
1. Créer le provider dans lib/features/kpi/providers/
2. Définir le modèle dans lib/features/kpi/models/
3. Intégrer dans les dashboards appropriés
4. Ajouter les tests unitaires

### 2. Modification des Dashboards
1. Modifier le composant dans lib/features/dashboard/widgets/
2. Tester sur tous les rôles concernés
3. Mettre à jour la documentation
4. Valider la responsivité

### 3. Optimisations
- **Requêtes SQL** : Optimiser les jointures et filtres
- **Cache** : Ajuster les TTL selon l'usage
- **UI** : Améliorer les animations et transitions

---

##  RESSOURCES ET DOCUMENTATION

### Fichiers Clés
- **Architecture** : lib/features/dashboard/
- **KPIs** : lib/features/kpi/
- **Composants** : lib/shared/ui/modern_components/
- **Tests** : test/features/dashboard/

### Documentation Associée
- **Changelog** : CHANGELOG.md
- **Guides** : docs/ (various guides)
- **API** : Documentation Supabase

---

##  RÉSUMÉ POUR L'ÉQUIPE DEV

### Architecture Actuelle
- **6 dashboards** spécialisés par rôle utilisateur
- **5 KPIs principaux** avec données temps réel
- **Architecture modulaire** avec composants réutilisables
- **Gestion d'état** centralisée avec Riverpod

### Points Forts
-  **Interface cohérente** : Même structure pour tous les rôles
-  **Performance** : Cache intelligent et lazy loading
-  **Responsive** : Adaptation automatique mobile/desktop
-  **Maintenabilité** : Code modulaire et bien structuré

### Améliorations Récentes
-  **Suppression de la redondance** : Section "Cours de route" éliminée
-  **Interface simplifiée** : Focus sur les KPIs essentiels
-  **UX améliorée** : Navigation plus claire et intuitive

### Prochaines Étapes
-  **Temps réel** : Connexion complète avec Supabase
-  **Nouveaux KPIs** : Ajout de métriques supplémentaires
-  **Tests** : Couverture de tests pour les dashboards
-  **Analytics** : Métriques d'usage et performance

---

##  CHECKLIST DE VALIDATION

###  Tests Fonctionnels
- [ ] Tous les KPIs s'affichent correctement
- [ ] Navigation fonctionne sur tous les dashboards
- [ ] Responsive design validé sur mobile/tablet/desktop
- [ ] Gestion d'erreur testée
- [ ] États de chargement validés

###  Tests Techniques
- [ ] Providers Riverpod fonctionnent
- [ ] Cache intelligent opérationnel
- [ ] Requêtes SQL optimisées
- [ ] Performance acceptable (<2s chargement)
- [ ] Pas d'erreurs de compilation

###  Tests Métier
- [ ] Données cohérentes entre les KPIs
- [ ] Filtrage par dépôt fonctionne
- [ ] Calculs de volumes corrects
- [ ] Alertes citernes opérationnelles
- [ ] Export CSV fonctionnel

---

** Généré le :** 17 septembre 2025  
** Par :** Équipe de développement ML_PP MVP  
** Contact :** dev-team@ml-pp-mvp.com  
** Repository :** https://github.com/ml-pp-mvp/dashboard-architecture  

---

*Ce rapport est confidentiel et destiné à l'équipe de développement ML_PP MVP. Toute reproduction ou diffusion non autorisée est interdite.*
