1.2 – Architecture Technique
Ce volet décrit la structure technique globale de l’application ML_PP MVP, en mettant en évidence les technologies utilisées, les flux de données, et la gestion de l’état. L’objectif est de guider les développeurs (ou l’IA) dans l’implémentation de manière cohérente, modulaire et évolutive.

🧰 Stack Technique (Technologies utilisées)
Composant	Technologie / Outil	Rôle
Frontend	Flutter (Web/Mobile/Desktop)	Interface utilisateur responsive
Backend-as-a-Service	Supabase (PostgreSQL + Auth + Storage)	API, base de données, authentification, gestion des fichiers
State Management	Riverpod	Gestion de l’état et injection de dépendances
Navigation	GoRouter	Routing dynamique avec ShellRoutes par rôle utilisateur
Stockage local	Hive (optionnel)	Cache local et mode semi-offline
Authentification	Supabase Auth	Connexion par email/password, sécurité RLS
Tests	Flutter test + Mockito	Tests unitaires et d’intégration
Génération code	build_runner, freezed, json_serializable	Génération automatique de modèles et adapters

🔄 Flux de Données Principaux

Utilisateur → UI Flutter → Riverpod Providers → Supabase DB/API
Lecture :

ref.watch(monProvider) appelle un service (ex: CoursRouteService)

Ce service interroge Supabase (via .select(), .eq(), etc.)

Les données sont affichées dans l’interface

Écriture (CRUD) :

L’utilisateur interagit avec un formulaire

Le provider collecte les données et appelle le service (ex: insertCours())

Le service utilise supabase.from('table').insert(data) pour écrire en DB

Un retour succès ou erreur est affiché

Sync semi-offline (optionnel) :

Les données peuvent être stockées temporairement dans Hive

Une tâche de synchronisation peut les envoyer à Supabase quand le réseau revient

🧠 Gestion de l’État avec Riverpod
L’architecture suit les bonnes pratiques de Riverpod 2.x :

Providers de service : chaque module (cours de route, réception…) a un service injectable (via Provider)

Notifier ou AsyncNotifier pour la logique métier ou les états dynamiques

Refactorisation en providers pures + méthodes testables pour faciliter les tests

Exemple : Provider d’authentification

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.withSupabase(Supabase.instance.client);
});
📌 Organisation du Code Flutter (arborescence)
vbnet
Copy
Edit
lib/
├── core/                     # Modèles, constantes, utils
│   └── models/
├── features/
│   ├── auth/
│   ├── cours_route/
│   ├── receptions/
│   ├── sorties/
│   ├── dashboard/
│   └── ...
├── shared/                  # Providers globaux, navigation, composants réutilisables
│   ├── navigation/
│   ├── providers/
│   └── widgets/
└── main.dart
🔐 Sécurité et permissions
RLS (Row-Level Security) activé côté Supabase

Contrôle d’accès renforcé via les rôles définis dans profils

Navigation restreinte via guards dans GoRouter

Audit trail automatique via log_actions

✅ Statut
Cette architecture est validée pour le MVP v0, avec possibilité d’évolution modulaire vers un PWA ou application hybride plus avancée.