## 🧠 Instruction pour Cursor AI

À chaque fois que tu complètes une fonctionnalité, une correction ou un test, mets à jour le fichier `CHANGELOG.md` dans le format suivant :

---

## [Unreleased]

### Ajouté
- Décris ici les nouvelles fonctionnalités ou modules ajoutés

### Modifié
- Décris les ajustements, refactorisations ou changements de comportement

### Corrigé
- Décris les bugs ou erreurs corrigés

---

🔁 Si la version du projet évolue (par exemple de 0.1.0 vers 0.2.0), crée une nouvelle section avec la date du jour.

## Exemple :

```md
## [0.2.0] - 2025-08-08

### Ajouté
- Module "Sortie Produit" complet avec formulaire, validation, et journalisation.
- Navigation dynamique multi-rôle avec `GoRouter`.

### Modifié
- Ajustement du modèle `Profil` pour inclure `depot_id`.

### Corrigé
- Erreur de redirection post-login pour rôle "opérateur".
```

📝 Si aucun changement ne correspond à une catégorie, ignore la catégorie (ex : pas besoin de "Corrigé" s’il n’y a pas eu de bug fixé).
