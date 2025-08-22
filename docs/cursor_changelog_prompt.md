# 🔄 Prompt Template – Mise à jour automatique du CHANGELOG.md

À chaque tâche que tu effectues, suis cette structure pour ajouter une entrée dans `CHANGELOG.md`.

## Format Markdown à respecter

### Exemple de bloc à ajouter

## [UNRELEASED]

### Ajouté
- Implémentation du module `receptions`: modèle de données, service Supabase, formulaire de saisie.
- Ajout des validations de température, densité, volume corrigé à 15 °C.
- Gestion des rôles et journalisation de l’action `RECEPTION_CREEE`.

### Modifié
- Ajustement de `cours_de_route` pour ajout de champ `note`.

### Supprimé
- Ancien champ `volume_brut` dans `receptions`.

---

## Instructions supplémentaires

- **Ne jamais modifier les anciennes versions du changelog.**
- Si aucune entrée n’existe pour `[UNRELEASED]`, la créer.
- Résume uniquement ce qui a été **effectivement implémenté** dans cette tâche.
- Toujours respecter la structure : `Ajouté`, `Modifié`, `Supprimé`.

---

🧠 Contexte : Ce changelog est utilisé pour le suivi rigoureux du projet ML_PP MVP. Il doit être mis à jour à chaque modification générée.
