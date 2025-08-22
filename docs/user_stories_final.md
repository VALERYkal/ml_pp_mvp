# 📘 User Stories – ML_PP MVP (Version Finale)

Ce document fusionne les meilleures parties des deux versions fournies : `3.0_user_stories.md` (centré MVP) et `User Stories.md` (structuré et détaillé). Il contient les user stories par rôle, par module, et les fonctionnalités système critiques.

---

## ✅ Authentification & Profils

- En tant qu'utilisateur, je veux me connecter avec mon email et mot de passe pour accéder à l'application.
- En tant qu'admin, je veux créer des profils utilisateurs avec des rôles et un dépôt associé.
- En tant qu'utilisateur, je veux voir mon rôle affiché pour comprendre mes permissions.
- En tant que PCA, je veux une vue globale mais lecture seule pour supervision.
- En tant que développeur, je veux utiliser Supabase Auth + Riverpod pour gérer l'état auth.

---

## 🛢️ Cours de Route

- En tant qu'opérateur, je veux consulter les cours de route affectés à mon dépôt.
- En tant qu'admin, je veux ajouter un cours de route avec toutes les infos nécessaires (camion, chauffeur, volume, etc.).
- En tant que directeur, je veux pouvoir valider ou modifier le statut d’un cours.
- En tant que système, je veux empêcher la duplication de plaques + date de chargement.
- En tant que système, je veux pouvoir avancer automatiquement les statuts selon des règles métier.

---

## 📥 Réceptions

- En tant qu'opérateur, je veux enregistrer une réception liée à un cours de route et une citerne.
- En tant qu’opérateur, je veux répartir la réception entre plusieurs citernes.
- En tant que gérant, je veux valider une réception enregistrée par un opérateur.
- En tant que système, je veux calculer le volume corrigé à 15°C automatiquement.
- En tant que système, je veux refuser une réception si la citerne est pleine ou inactive.

---

## 📤 Sorties Produit

- En tant qu’opérateur, je veux saisir une sortie pour un client ou partenaire.
- En tant qu’opérateur, je veux choisir plusieurs citernes pour une même sortie.
- En tant que gérant/directeur, je veux valider ou rejeter une sortie.
- En tant que système, je veux interdire une sortie si le volume > stock disponible.
- En tant que système, je veux alerter si la capacité de sécurité est dépassée.

---

## 📊 Stock Journalier

- En tant qu’utilisateur, je veux visualiser les stocks par citerne, produit et jour.
- En tant qu’admin, je veux modifier un stock journalier si besoin (source manuelle).
- En tant que système, je veux générer automatiquement les lignes de stock après chaque réception ou sortie validée.
- En tant que PCA, je veux consulter le stock total pour tous les dépôts.

---

## 🧾 Journalisation (Log Actions)

- En tant que système, je veux enregistrer chaque action importante (réception, sortie, validation, rejet).
- En tant qu’admin, je veux voir l’historique des actions avec auteur, date, module, cible.
- En tant que système, je veux que chaque log soit lié à une cible_id (UUID).

---

## ⚙️ Référentiels (Produits, Citernes, Dépôts, etc.)

- En tant qu’admin, je veux pouvoir ajouter ou modifier les produits, dépôts, clients, partenaires, etc.
- En tant qu’utilisateur lecture seule, je veux pouvoir consulter les référentiels sans les modifier.
- En tant que développeur, je veux que les référentiels soient pré-remplis dans Supabase et gérés manuellement au début.

---

## 🔐 Sécurité & Permissions

- En tant qu’admin, je veux activer la sécurité RLS sur les tables sensibles.
- En tant que développeur, je veux pouvoir tester les permissions par rôle sur Supabase.
- En tant que système, je veux appliquer automatiquement les règles RLS selon le rôle et le dépôt de l'utilisateur.

---

## 🧠 Alertes & Automatisations

- En tant que système, je veux déclencher une alerte si une citerne passe sous son seuil de sécurité.
- En tant que système, je veux déclencher une alerte en cas de citerne inactive utilisée dans une opération.
- En tant que directeur, je veux recevoir des synthèses hebdomadaires des mouvements de stock.

---

## 📱 Expérience Utilisateur & Navigation

- En tant qu’utilisateur, je veux que la navigation s’adapte à mon appareil (mobile, desktop).
- En tant qu’utilisateur, je veux voir uniquement les fonctionnalités autorisées selon mon rôle.
- En tant qu’utilisateur, je veux recevoir des confirmations visuelles (snackbar) après chaque action réussie ou échouée.

---

✅ **Statut : validé pour développement et intégration dans Cursor AI.**
