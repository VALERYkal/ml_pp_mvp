# 🛢️ ML_PP MVP – Gestion Logistique Pétrolière

## 🎯 Objectif du projet

Ce projet vise à développer une application Flutter connectée à Supabase pour gérer les flux logistiques pétroliers du dépôt **Monaluxe**. Il couvre les modules suivants :
- Suivi des **cours de route**
- Gestion des **réceptions**
- Gestion des **sorties**
- Visualisation et journalisation des **stocks et citernes**
- Traçabilité complète des mouvements
- Rôles utilisateur (admin, directeur, gérant, opérateur, pca)

## 🧱 Stack technique

| Côté client      | Backend / BDD     |
|------------------|-------------------|
| Flutter (Material 3) | Supabase (PostgreSQL, RLS) |
| Riverpod         | Auth (email/password) |
| GoRouter         | Supabase Storage (logs, documents) |
| Hive (optionnel) | Row-Level Security (RLS) |

## 🗂 Structure du projet

ml_pp_mvp/
├── lib/
│ ├── features/
│ │ ├── auth/...
│ │ ├── dashboard/...
│ │ ├── cours_route/...
│ │ ├── receptions/...
│ │ ├── sorties/...
│ │ ├── citernes/...
│ │ ├── stocks_journaliers/...
│ ├── core/
│ │ ├── models/
│ │ ├── services/
│ ├── shared/
│ │ ├── widgets/
│ │ ├── providers/
│ │ ├── navigation/
├── test/
│ ├── unit/
│ ├── integration/
│ ├── e2e/
├── supabase_schema.sql
├── ML_PP_MVP_PRD.md
├── prompts_cursor_ai.md
├── checklist_dev.md
├── README.md

markdown
Copy
Edit

## 📚 Fichiers de référence

| Fichier | Description |
|--------|-------------|
| `ML_PP_MVP_PRD.md` | Document de référence décrivant tous les modules du MVP |
| `supabase_schema.sql` | Schéma complet des tables, RLS et contraintes Supabase |
| `prompts_cursor_ai.md` | Prompts Cursor AI pour générer automatiquement le code |
| `checklist_dev.md` | Liste des tâches à valider par les devs |
| `README.md` | Ce fichier – structure générale du projet |

## ✅ Modules fonctionnels dans ce MVP

- **Authentification** (Supabase)
- **Cours de route** (suivi amont)
- **Réception produit** (volume, température, densité, BL)
- **Sorties produit** (clients, partenaires, volumes sortants)
- **Stocks journaliers** (fige automatiquement après réception/sortie)
- **Citernes** (lecture uniquement sauf admin)
- **Dashboard** (vue synthétique + alertes)
- **Journalisation** (log_actions)

## 🛡️ Sécurité

- Auth via Supabase
- RLS activée par table (cf. `supabase_schema.sql`)
- Accès différencié par rôle : RBAC intégré dans la logique

## 🧪 Tests

- Tests unitaires (Riverpod, Services)
- Tests d’intégration (formulaire + navigation)
- Tests end-to-end à faire avec `flutter_driver` ou `integration_test`
