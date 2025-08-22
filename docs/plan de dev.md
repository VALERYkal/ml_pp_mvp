PLAN DE DÉVELOPPEMENT COMPLET – ML_PP MVP
🔰 Préambule
📆 Objectif MVP opérationnel : 20 septembre 2025

🧠 Outils IA utilisés : Cursor AI, ChatGPT, build_runner, Supabase Studio

📦 Stack : Flutter (Material 3), Supabase, Riverpod, GoRouter, Hive (optionnel)

🔐 Auth : Supabase Auth + RLS (Row-Level Security)

🧱 Phase 1 – Initialisation & Architecture (Jour 1)
Créer projet Flutter avec structure modulaire


flutter create ml_pp_mvp
Configurer le routing avec go_router

Setup d’un ShellRoute dynamique par rôle utilisateur

Redirections login / dashboard

Installer les dépendances


supabase_flutter
flutter_riverpod
go_router
hive (optionnel)
freezed, json_serializable, build_runner
Créer l’architecture dossier

  features/
  shared/
  core/
  main.dart
Configurer Supabase & secrets

Fichier .env

Supabase URL et anon/public key

🔐 Phase 2 – Authentification & Profils (Jours 1–2)
Auth via supabase_flutter

Création du modèle Profil

Charger le profil après login (RLS activé)

Redirection par rôle (admin, opérateur…)

Affichage du Dashboard associé

🧭 Phase 3 – Navigation Responsive (Jour 2–3)
Créer ResponsiveScaffold :

NavigationRail sur desktop/tablette

BottomNavigationBar sur mobile

DashboardShell dynamique (selon rôle)

Intégration des routes :

/dashboard

/cours

/receptions

/sorties

/stocks

/citernes (lecture seule)

/logs

🚚 Phase 4 – Module Cours de Route (Jour 4)
Modèle CoursDeRoute

Liste filtrable + badge de statut

Formulaire de création/modification

Avancement du statut (boutons ou dropdown)

Tests unitaires (mock de Supabase)

📥 Phase 5 – Réceptions (Jour 5)
Formulaire avec :

Choix du cours de route

Produit auto-rempli

Choix citerne

Saisie volume, température, densité

Propriétaire : Monaluxe / Partenaire

Calcul volume corrigé à 15 °C

Enregistrement + validation (RBAC)

Blocage mélange citerne

Journalisation RECEPTION_CREEE, RECEPTION_VALIDE

📤 Phase 6 – Sorties Produit (Jour 6)
Choix du client ou partenaire

Sélection multi-citerne via sortie_citerne

Saisie des volumes

Contrôles :

Pas de mélange

Capacité de sécurité

Citerne active

Volume disponible

Journalisation SORTIE_CREEE, SORTIE_VALIDE

📊 Phase 7 – Stock Journalier (Jour 7)
Généré automatiquement après :

Réception validée

Sortie validée

Liste quotidienne par citerne, produit, propriétaire

Affichage graphique (optionnel)

Lecture seule sauf admin

🔍 Phase 8 – Citernes (Jour 7)
Modèle Citerne

Affichage lecture seule (sauf admin)

Règles : pas de mélange, produit unique

Ajout de prises_de_hauteur (mesures manuelles)

Liste des citernes avec capacités

🧾 Phase 9 – Logs & Sécurité (Jour 8)
log_actions :

Module

Action

Niveau

User ID

cible_id

Audit trail visible (lecture seule)

Mise en place complète des RLS :

Par rôle sur chaque table

Accès uniquement à son dépôt (si nécessaire)

🧪 Phase 10 – Tests et finalisation (Jours 9–10)
Tests automatisés :

Auth + profils

Redirections

Cours de route : création, statut

Réceptions : saisie, validation

Sorties : multi-citerne, validation

Déploiement Supabase

Backup + export SQL

Préparation démo MVP

Scénarios utilisateur

Export de données

🧾 Suivi journalier (exemple pour Cursor AI)
Jour	Modules	Résultat attendu
J1	Auth, archi	Projet Flutter structuré, login opérationnel
J2	Dashboard, navigation	Redirection OK, ResponsiveScaffold actif
J3	Shell, routing	GoRouter dynamique, navigation par rôle
J4	Cours de route	CRUD opérationnel avec logique de statut
J5	Réception	Formulaire fonctionnel, calcul 15°C
J6	Sortie produit	Gestion multi-citerne, validation stricte
J7	Stock, citernes	Génération auto stock + affichage citerne
J8	Log, sécurité	RLS + audit trail
J9–J10	Tests, démo	Couverture test + démo prête