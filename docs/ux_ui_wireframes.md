
# 📐 2.0 – Maquettes UX/UI (Wireframes) – ML_PP MVP

## 🎯 Objectif
Définir la structure visuelle et le parcours utilisateur des principaux écrans, pour :

- Valider l’ergonomie
- Faciliter le développement Flutter
- Offrir une expérience cohérente à tous les rôles

## 🧩 2.1 – Écrans clés par rôle
Chaque rôle possède un Dashboard personnalisé, accessible après authentification et redirection automatique.

| Rôle      | Dashboard cible         | Fonctionnalités principales visibles                            |
|-----------|--------------------------|------------------------------------------------------------------|
| admin     | AdminDashboardScreen     | Tout (stock, réceptions, sorties, logs)                          |
| directeur | DirecteurDashboardScreen | Vision stratégique, validation, synthèse stock                  |
| gerant    | GerantDashboardScreen    | Suivi journalier, validation, supervision                        |
| operateur | OperateurDashboardScreen | Saisie réceptions et sorties uniquement                          |
| lecture   | LectureDashboardScreen   | Consultation seule                                               |
| pca       | PcaDashboardScreen       | Vue globale lecture seule, toutes les données                    |

## 📝 2.2 – Écrans fonctionnels

### 🛢️ A. Cours de Route – `CoursRouteListScreen`
Liste avec :

- Plaque camion
- Volume prévu
- Statut (badge coloré)
- Bouton "Détails"

Actions :

- + Ajouter (admin/directeur uniquement)
- Modifier / Avancer statut

Filtres :

- Par statut, date, produit

### 📥 B. Réception – `ReceptionFormScreen`
Champs principaux :

- Cours de route associé (dropdown ou champ autocomplete)
- Produit (pré-rempli)
- Citerne (dropdown)
- Volume mesuré
- Température / Densité
- Propriétaire : Monaluxe / Partenaire

Boutons :

- Valider (selon rôle)
- Enregistrer brouillon

### 📤 C. Sortie – `SortieProduitFormScreen`
- Choix client / partenaire
- Multi-citerne possible
- Saisie des volumes par citerne
- Validation stricte (pas de survolume / mélange)

### 📊 D. Stock Journalier – `StockJournalierScreen`
- Liste par jour / produit / citerne
- Lecture seule sauf admin
- Graphique simple : évolution des volumes
- Tag automatique ou manuel

### 🔐 Login – `LoginScreen`
- Champs : Email, Mot de passe
- Actions :
  - Connexion
  - Message d’erreur (auth invalide)
- Redirection automatique vers le bon dashboard selon rôle

## 🧭 2.3 – Navigation multiplateforme

### ✅ ResponsiveScaffold :
- `NavigationRail` sur desktop/tablette
- `BottomNavigationBar` sur mobile
- Affiche la route par rôle (via ShellRoute dans GoRouter)

## 🎨 2.4 – Design System (minimal MVP)

| Élément     | Style recommandé (Material 3)                   |
|-------------|-------------------------------------------------|
| Police      | Inter / Roboto                                  |
| Couleurs    | Primaire : `#146C94` – Secondaire : `#F1F6F9`    |
| Boutons     | `ElevatedButton`, `IconButton`                  |
| Cartes      | `Card` avec coins arrondis (`borderRadius`)     |
| Formulaires | `TextFormField`, validation en temps réel       |
| Feedback    | `Snackbar` pour succès / erreurs                |
| Icônes      | `Icons.edit`, `Icons.delete`, `Icons.check`     |
| Erreurs     | `InputDecoration.errorText` sur champs invalides|

---

## ✅ Statut

Cette base UX/UI permet à une IA ou une équipe Flutter de générer les écrans avec GoRouter + Riverpod. Le parcours est clair, modulaire et adapté aux rôles.
