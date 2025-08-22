# ✅ ML_PP MVP – Checklist de Développement Technique

## 📁 Organisation Générale
- [x] Arborescence du projet conforme à la structure Clean Architecture
- [x] Séparation des modules par feature : auth, cours_route, receptions, etc.
- [x] Providers centralisés (Riverpod)
- [x] Fichiers de modèle dans `lib/core/models/`
- [x] Services métiers dans `lib/core/services/`
- [x] Schéma Supabase validé et importé
- [x] Configuration `supabase_flutter` en place
- [x] Variables d’environnement (URL, anon key) sécurisées

---

## 🔐 Authentification & Profils
- [x] Auth via `supabase_flutter` (email/password)
- [x] Récupération du `Profil` post-login
- [x] Système de rôles complet : admin, directeur, gérant, opérateur, pca, lecture
- [x] Redirection GoRouter selon rôle
- [x] Gestion de session et déconnexion
- [x] RLS activé sur la table `profils`

---

## 🚛 Cours de Route
- [x] Formulaire de création avec tous les champs requis
- [x] Statut dynamique : chargement → transit → frontière → arrivé → déchargé
- [x] Redirection vers réception après statut `arrivé`
- [x] Affichage des cours actifs (≠ déchargés)
- [x] Affichage séparé des cours déchargés

---

## 📥 Réceptions Produit
- [x] Formulaire de réception relié à un `cours_de_route`
- [x] Calcul automatique du volume corrigé à 15 °C
- [x] Prise en compte du type de propriétaire (Monaluxe / partenaire)
- [ ] Répartition multi-citerne
- [x] Mono-citerne (MVP validé)
- [x] Validation selon rôle
- [x] Logs : RECEPTION_CREEE, RECEPTION_VALIDE, etc.

---

## 📤 Sorties Produit
- [ ] Sélection multi-citerne (répartition par citerne)
- [x] Mono-citerne (MVP validé)
- [x] Validation par gérant/directeur/admin uniquement
- [x] Calculs à 15 °C
- [x] Stock décrémenté par propriétaire
- [x] Logs : SORTIE_CREEE, SORTIE_VALIDE, etc.

---

## 🛢 Citernes
- [x] Lecture seule
- [x] Alimentation initiale manuelle dans Supabase
- [x] Règles métier : type de produit, capacité sécurité, statut actif/inactif

---

## 📊 Stocks Journaliers
- [x] Génération auto après réception ou sortie
- [x] Volume brut et volume 15 °C
- [x] Donnée figée, non modifiable (sauf admin)
- [x] Visualisation par filtre (citerne, produit, date, propriétaire)
- [x] Logs : STOCK_JOURNALIER_GENERE

---

## 🧾 Journalisation
- [x] Insertion dans `log_actions` à chaque étape critique
- [x] Niveau (INFO, WARNING, CRITICAL)
- [x] Lien vers user_id et module concerné
- [x] Lecture filtrable dans l’interface admin

---

## 📁 Référentiels (Clients, Produits, Dépôts, Fournisseurs)
- [x] Accès lecture seule
- [x] Alimentation initiale via interface Supabase
- [x] UI consultable avec recherche + tri

---

## ⚙️ Qualité & Sécurité
- [x] Row-Level Security activée sur toutes les tables critiques
- [x] Messages d’erreur métiers clairs
- [x] Validation des formulaires complète (volume, densité, temp)
- [x] Tests unitaires des services
- [x] Tests d’intégration (redirection, saisie, validation)
- [x] Séparation stricte logique métier / UI

---

## 🧪 Scénarios de Test Clés
- [x] Essai de réception dans une citerne inactive
- [x] Tentative de sortie de volume trop élevé
- [x] Validation par un rôle non autorisé
- [x] Calcul volume 15 °C incorrect
- [x] Récupération du bon rôle au login
- [x] Connexion/déconnexion + navigation GoRouter

---

## 📚 Glossaire
- Volume corrigé à 15 °C
- Cours de route
- BL / CMR
- Propriétaire produit
- RLS (Row-Level Security)
- Capacité de sécurité

---

## 🗂 À livrer aux développeurs
- [x] `ML_PP_MVP PRD.md`
- [x] `supabase_schema.sql`
- [x] `README.md` (explication des tables)
- [x] `checklist_dev.md`
- [x] Dossier `/lib` structuré avec `models/`, `services/`, `screens/`, `widgets/`

---

