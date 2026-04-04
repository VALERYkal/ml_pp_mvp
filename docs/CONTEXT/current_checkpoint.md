# CURRENT CHECKPOINT — ML_PP MVP

## ROLE
Point d’entrée principal pour comprendre l’état actuel du système et agir sans dérive.

## UPDATE FREQUENCY
À chaque modification significative (DB, logique métier, structure, règles).

## LECTURE ORDER
1. current_checkpoint.md
2. architecture_rules.md
3. architecture_map.md
4. DB/critical_objects.md

---

# PROJECT STATUS

- Application en production
- Système logistique stable
- Moteur volumétrique ASTM actif (lookup-grid)
- STAGING et PROD alignés sur les fondamentaux critiques
- DB = source de vérité

---

# FOCUS ACTUEL

- Mise en place du pack canonique IA
- Structuration documentaire
- Sécurisation des interactions IA

---

# ZONES STABLES (NE PAS MODIFIER)

- Réception
- Stock (calcul DB)
- Moteur ASTM
- Triggers, fonctions et vues critiques

---

# ZONES EN COURS

- Documentation canonique
- Gouvernance IA

---

# RISQUES

- Modification des triggers DB
- Altération des vues de stock
- Désalignement staging / prod
- Utilisation de docs non alignés avec la DB

---

# SOURCES DE VÉRITÉ

- DB → vérité métier (stock, volumétrie, logique)
- Invariants → règles
- Code → implémentation
- Pack canonique → représentation contrôlée

---

# ORDRE DE LECTURE IA

1. CONTEXT
2. DB
3. DB_GOVERNANCE
4. REFERENCE
5. SUPPORT

---

# RÈGLES CRITIQUES

- Ne jamais modifier la DB sans migration
- Ne jamais recalculer le stock côté application
- Ne jamais implémenter de logique métier critique en frontend
- Toujours valider staging avant prod
- Ne jamais inventer :
  - tables
  - champs
  - logique métier

---

# QUAND VÉRIFIER LA DB

Vérification obligatoire si :
- modification DB
- logique métier critique
- incohérence détectée
- doute sur stock ou volume

Sinon :
- se fier au pack canonique

---

# COMMANDES IA

- respecte strictement current_checkpoint.md
- vérifie architecture_rules.md
- vérifie la DB si nécessaire
- ne touche pas aux zones stables
- propose sans casser la DB

---

# DEFINITION OF DONE

Une modification est validée si :
- respecte les règles
- ne casse aucune zone stable
- validée en staging si DB impactée
- cohérente avec la DB
- pack canonique mis à jour
