#  RAPPORT TECHNIQUE - ARCHITECTURE DES DASHBOARDS
## ML_PP MVP - Syst�me de Gestion Logistique P�troli�re

---

** Date :** 17 septembre 2025  
** �quipe :** D�veloppement ML_PP MVP  
** Version :** 2.0.0  
** Statut :**  Production  

---

##  R�SUM� EX�CUTIF

Ce rapport pr�sente l'architecture compl�te du syst�me de dashboards de ML_PP MVP, une application Flutter de gestion logistique pour produits p�troliers. Le syst�me fournit des indicateurs cl�s de performance (KPIs) en temps r�el pour 6 r�les utilisateurs diff�rents, avec une architecture modulaire et scalable.

###  Objectifs Atteints
-  **Interface unifi�e** : Dashboards coh�rents pour tous les r�les
-  **Performance optimis�e** : Chargement rapide avec cache intelligent
-  **Responsive design** : Adaptation automatique mobile/desktop
-  **Architecture modulaire** : Composants r�utilisables et maintenables
-  **Temps r�el** : Mise � jour automatique des donn�es

---

##  ARCHITECTURE TECHNIQUE

### 1. Structure Modulaire

`
lib/features/dashboard/
 screens/                    # 6 dashboards sp�cialis�s par r�le
    dashboard_admin_screen.dart      # Admin complet
    dashboard_operateur_screen.dart  # Op�rateur avec actions rapides
    dashboard_directeur_screen.dart # Directeur (via RoleDashboard)
    dashboard_gerant_screen.dart    # G�rant (via RoleDashboard)
    dashboard_pca_screen.dart       # PCA (via RoleDashboard)
    dashboard_lecture_screen.dart   # Lecture seule (via RoleDashboard)
 widgets/                    # Composants r�utilisables
    role_dashboard.dart     # Dashboard commun (4 r�les)
    kpi_tiles.dart         # Widgets KPI sp�cialis�s
    dashboard_shell.dart    # Shell responsive
 providers/                  # Gestion d'�tat et logique m�tier
    admin_trends_provider.dart      # Graphiques tendances
    activites_recentes_provider.dart # Logs syst�me
    admin_kpi_provider.dart         # KPIs admin
    directeur_kpi_provider.dart     # KPIs directeur
    citernes_sous_seuil_provider.dart # Alertes citernes
 models/                     # Mod�les de donn�es
     activite_recente.dart

lib/features/kpi/               # Syst�me KPI centralis�
 providers/                  # 5 providers KPI sp�cialis�s
    cours_kpi_provider.dart         # Camions en route/attente
    receptions_kpi_provider.dart    # R�ceptions du jour
    stocks_kpi_provider.dart        # Stocks actuels
    sorties_kpi_provider.dart       # Sorties du jour
    balance_kpi_provider.dart       # Balance (r�ceptions-sorties)
 models/                     # Mod�les KPI
    kpi_models.dart
 widgets/                    # Widgets KPI
     kpi_summary_card.dart
     kpi_split_card.dart

lib/shared/ui/modern_components/ # Composants UI modernes
 modern_kpi_card.dart        # Carte KPI avec animations Material 3
 dashboard_grid.dart         # Grille responsive adaptative
 dashboard_header.dart       # En-t�te avec salutation personnalis�e
`

### 2. Gestion d'�tat avec Riverpod

#### Providers Principaux
- **coursKpiProvider** : Donn�es des camions en route et en attente
- **receptionsKpiProvider** : Statistiques des r�ceptions du jour
- **stocksTotalsProvider** : Totaux des stocks actuels
- **sortiesKpiProvider** : Statistiques des sorties du jour
- **balanceTodayProvider** : Calcul de la balance (r�ceptions - sorties)

#### Invalidation Temps R�el
`dart
// Providers d'invalidation pour mise � jour automatique
ref.watch(coursRealtimeInvalidatorProvider);
ref.watch(stocksRealtimeInvalidatorProvider);
ref.watch(sortiesRealtimeInvalidatorProvider);
`

#### Filtrage Automatique par Profil
`dart
// Param�tres automatiques selon le profil utilisateur
final coursParam = ref.watch(coursDefaultParamProvider);
final depotId = profil?.depotId; // Filtrage automatique par d�p�t
`

### 3. Composants UI Modernes

#### ModernKpiCard
- **Design Material 3** avec gradients et ombres
- **Animations** : Scale et fade au tap
- **M�triques d�taill�es** : Affichage de sous-m�triques
- **Navigation** : Tap pour aller aux d�tails
- **�tats** : Loading, Error, Data avec gestion appropri�e

#### DashboardGrid
- **Responsive** : Adaptation automatique selon la taille d'�cran
- **Breakpoints** : Mobile (1 col), Tablet (2 cols), Desktop (3 cols)
- **Espacement** : Marges et padding adaptatifs

#### DashboardSection
- **Titres hi�rarchis�s** : Titre principal + sous-titre
- **Actions contextuelles** : Boutons d'action optionnels
- **Espacement coh�rent** : Marges standardis�es

---

##  DASHBOARDS PAR R�LE

### 1. Dashboard Admin (dashboard_admin_screen.dart)

#### Sections Sp�cifiques
1. **Vue d'ensemble** : Camions � suivre, Stock total, Balance du jour
2. **Activit�s du jour** : R�ceptions et sorties
3. **Stock par propriétaire** : Répartition MONALUXE vs PARTENAIRE (remplace "Tendances 7 jours")
4. **� surveiller** : Table des citernes sous seuil critique
5. **Activit� r�cente** : Logs syst�me des 24h avec export CSV
6. **Actions rapides** : Bouton flottant pour actions courantes

#### Providers Sp�cialis�s
- **depotStocksSnapshotProvider** : Données stock par propriétaire (remplace adminTrends7dProvider - déprécié)
- **activitesRecentesProvider** : Logs syst�me r�cents
- **citernesSousSeuilProvider** : Citernes n�cessitant attention

#### Fonctionnalit�s Avanc�es
- **Export CSV** : Export des logs d'activit�
- **Surveillance** : Alertes sur citernes critiques
- **Analytics** : Graphiques de tendances

### 2. Dashboard Op�rateur (dashboard_operateur_screen.dart)

#### Sections Sp�cifiques
1. **Vue d'ensemble** : Camions � suivre, Stock total, Balance du jour
2. **Activit�s du jour** : R�ceptions et sorties
3. **Acc�s rapide** : Boutons pour cr�er cours, r�ception, sortie

#### Fonctionnalit�s Op�rationnelles
- **Actions rapides** : Interface simplifi�e pour les t�ches courantes
- **Navigation directe** : Acc�s imm�diat aux formulaires de cr�ation
- **Interface focalis�e** : Design �pur� pour l'efficacit� op�rationnelle

### 3. Dashboards Autres R�les (role_dashboard.dart)

#### R�les Utilisant RoleDashboard
- **Directeur** : Vue globale avec filtrage par d�p�t
- **G�rant** : Vue du d�p�t avec KPIs locaux
- **PCA** : Vue de contr�le avec m�triques cl�s
- **Lecture** : Vue en lecture seule

#### Sections Communes
1. **Vue d'ensemble** : Camions � suivre, Stock total, Balance du jour
2. **Activit�s du jour** : R�ceptions et sorties

---

##  ARCHITECTURE M�TIER

### 1. KPIs Principaux

#### Camions � suivre
- **Donn�es** : Nombre total (en route + en attente)
- **Volumes** : Volume total pr�vu (ambiant + 15C)
- **D�tails** : R�partition par statut
- **Source** : Table cours_de_route avec filtrage par statut

#### Stock total
- **Donn�es** : Volume ambiant et 15C actuels
- **M�tadonn�es** : Derni�re mise � jour
- **Source** : Vue v_citerne_stock_actuel agr�g�e

#### Balance du jour
- **Calcul** : R�ceptions - Sorties
- **Indicateur** : Positif (vert) ou n�gatif (rouge)
- **Tendance** : Pourcentage d'�volution
- **Source** : Agr�gation des tables r�ceptions et sorties_produit

#### R�ceptions du jour
- **Donn�es** : Nombre de camions re�us
- **Volumes** : Volume ambiant et 15C
- **Source** : Table r�ceptions filtr�e par date et statut

#### Sorties du jour
- **Donn�es** : Nombre de camions sortis
- **Volumes** : Volume ambiant et 15C
- **Source** : Table sorties_produit filtr�e par date et statut

### 2. Logique M�tier

#### Filtrage Automatique
- **Par d�p�t** : Selon le profil utilisateur
- **Par date** : Jour courant en UTC
- **Par statut** : Seulement les donn�es valid�es

#### Calculs de Volumes
- **Priorit� 15C** : Si disponible, sinon volume ambiant
- **Agr�gation** : Somme des volumes par p�riode
- **Conversion** : Formatage automatique (L, kL, ML)

#### Gestion des �tats
- **Loading** : Indicateurs de chargement
- **Error** : Gestion d'erreur avec retry
- **Data** : Affichage des donn�es avec formatage

### 3. Sources de Donn�es

#### Tables Principales
- **cours_de_route** : �tat des camions et volumes pr�vus
- **r�ceptions** : R�ceptions valid�es avec volumes
- **sorties_produit** : Sorties valid�es avec volumes
- **stocks_journaliers** : Historique des stocks par citerne
- **citernes** : Capacit�s et seuils de s�curit�

#### Vues Sp�cialis�es
- **v_citerne_stock_actuel** : Dernier stock par citerne
- **logs** : Activit� syst�me (vue de compatibilit�)

#### Filtres Temporels
- **R�ceptions** : Filtrage par date_reception (TYPE DATE)
- **Sorties** : Filtrage par date_sortie (TIMESTAMPTZ)
- **Logs** : Filtrage par created_at (TIMESTAMPTZ)

---

##  FONCTIONNALIT�S AVANC�ES

### 1. Temps R�el
- **Invalidation automatique** : Mise � jour des KPIs lors des changements
- **Providers r�actifs** : R�action aux modifications de donn�es
- **Cache intelligent** : �vite les requ�tes inutiles

### 2. Responsive Design
- **Breakpoints** : Mobile (<800px), Tablet (800-1199px), Desktop (1200px)
- **Grilles adaptatives** : Nombre de colonnes selon l'�cran
- **Composants flexibles** : Adaptation automatique du contenu

### 3. Performance
- **Lazy loading** : Chargement � la demande
- **M�morisation** : Cache des donn�es calcul�es
- **Optimisation** : Requ�tes SQL optimis�es

### 4. Accessibilit�
- **Navigation clavier** : Support des raccourcis
- **Contraste** : Couleurs contrast�es pour la lisibilit�
- **Ic�nes** : Ic�nes explicites pour chaque m�trique

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

### 2. Formatage des Donn�es
`dart
// Utilitaires de formatage centralis�s
fmtLiters(volume)           // Formatage des volumes
fmtShortDate(date)          // Formatage des dates
fmtLitersSigned(delta)      // Formatage avec signe
`

### 3. Navigation
`dart
// Navigation contextuelle
onTap: () => context.go('/cours'),     // Vers les cours
onTap: () => context.go('/r�ceptions'), // Vers les r�ceptions
onTap: () => context.go('/stocks'),     // Vers les stocks
`

### 4. �tats de Chargement
- **Shimmer effects** : Indicateurs visuels de chargement
- **Skeleton screens** : Structure visible pendant le chargement
- **Error boundaries** : Gestion gracieuse des erreurs

---

##  M�TRIQUES ET MONITORING

### 1. KPIs Techniques
- **Temps de chargement** : Performance des requ�tes
- **Taux de cache** : Efficacit� du cache
- **Erreurs** : Monitoring des erreurs de chargement

### 2. KPIs M�tier
- **Camions en transit** : Suivi op�rationnel
- **Volumes trait�s** : Capacit� op�rationnelle
- **Balance** : �quilibre entr�es/sorties
- **Alertes** : Citernes sous seuil

---

##  MAINTENANCE ET �VOLUTION

### 1. Ajout de Nouveaux KPIs
1. Cr�er le provider dans lib/features/kpi/providers/
2. D�finir le mod�le dans lib/features/kpi/models/
3. Int�grer dans les dashboards appropri�s
4. Ajouter les tests unitaires

### 2. Modification des Dashboards
1. Modifier le composant dans lib/features/dashboard/widgets/
2. Tester sur tous les r�les concern�s
3. Mettre � jour la documentation
4. Valider la responsivit�

### 3. Optimisations
- **Requ�tes SQL** : Optimiser les jointures et filtres
- **Cache** : Ajuster les TTL selon l'usage
- **UI** : Am�liorer les animations et transitions

---

##  RESSOURCES ET DOCUMENTATION

### Fichiers Cl�s
- **Architecture** : lib/features/dashboard/
- **KPIs** : lib/features/kpi/
- **Composants** : lib/shared/ui/modern_components/
- **Tests** : test/features/dashboard/

### Documentation Associ�e
- **Changelog** : CHANGELOG.md
- **Guides** : docs/ (various guides)
- **API** : Documentation Supabase

---

##  R�SUM� POUR L'�QUIPE DEV

### Architecture Actuelle
- **6 dashboards** sp�cialis�s par r�le utilisateur
- **5 KPIs principaux** avec donn�es temps r�el
- **Architecture modulaire** avec composants r�utilisables
- **Gestion d'�tat** centralis�e avec Riverpod

### Points Forts
-  **Interface coh�rente** : M�me structure pour tous les r�les
-  **Performance** : Cache intelligent et lazy loading
-  **Responsive** : Adaptation automatique mobile/desktop
-  **Maintenabilit�** : Code modulaire et bien structur�

### Am�liorations R�centes
-  **Suppression de la redondance** : Section "Cours de route" �limin�e
-  **Interface simplifi�e** : Focus sur les KPIs essentiels
-  **UX am�lior�e** : Navigation plus claire et intuitive

### Prochaines �tapes
-  **Temps r�el** : Connexion compl�te avec Supabase
-  **Nouveaux KPIs** : Ajout de m�triques suppl�mentaires
-  **Tests** : Couverture de tests pour les dashboards
-  **Analytics** : M�triques d'usage et performance

---

##  CHECKLIST DE VALIDATION

###  Tests Fonctionnels
- [ ] Tous les KPIs s'affichent correctement
- [ ] Navigation fonctionne sur tous les dashboards
- [ ] Responsive design valid� sur mobile/tablet/desktop
- [ ] Gestion d'erreur test�e
- [ ] �tats de chargement valid�s

###  Tests Techniques
- [ ] Providers Riverpod fonctionnent
- [ ] Cache intelligent op�rationnel
- [ ] Requ�tes SQL optimis�es
- [ ] Performance acceptable (<2s chargement)
- [ ] Pas d'erreurs de compilation

###  Tests M�tier
- [ ] Donn�es coh�rentes entre les KPIs
- [ ] Filtrage par d�p�t fonctionne
- [ ] Calculs de volumes corrects
- [ ] Alertes citernes op�rationnelles
- [ ] Export CSV fonctionnel

---

** G�n�r� le :** 17 septembre 2025  
** Par :** �quipe de d�veloppement ML_PP MVP  
** Contact :** dev-team@ml-pp-mvp.com  
** Repository :** https://github.com/ml-pp-mvp/dashboard-architecture  

---

*Ce rapport est confidentiel et destin� � l'�quipe de d�veloppement ML_PP MVP. Toute reproduction ou diffusion non autoris�e est interdite.*
