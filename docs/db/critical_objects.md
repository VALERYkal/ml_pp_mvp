# CRITICAL OBJECTS — ML_PP MVP

## ROLE
Lister les objets DB critiques du système et indiquer les précautions minimales avant toute modification.

## UPDATE FREQUENCY
À chaque changement sur un objet DB critique ou sur sa procédure de contrôle.

## SCOPE
Ce fichier couvre :
- les tables critiques
- les vues critiques
- les triggers critiques
- les fonctions critiques
- les règles minimales de sécurité associées

### ⚠️ WARNING — NOM DE FONCTION / WIRING RÉEL

Les **noms de fonctions** cités dans la documentation (runbooks, anciens dumps, schémas) peuvent **différer** des fonctions **réellement branchées** sur les triggers (ex. doc historique vs `reception_after_ins_trg()` / `sorties_after_insert_trg()`).

**Avant toute modification :** toujours vérifier sur l’instance cible **`pg_trigger`** (définition du trigger → fonction) et **`pg_proc`** / **`pg_get_functiondef`**, pas seulement un document texte.

## TABLES CRITIQUES

Les tables suivantes sont considérées comme critiques :

- cours_de_route
- receptions
- sorties_produit
- stocks_journaliers
- log_actions

### Pourquoi

- cours_de_route → point d’entrée du flux logistique
- receptions → vérité physique d’entrée
- sorties_produit → vérité physique de sortie
- stocks_journaliers → support critique du calcul et du suivi stock
- log_actions → audit et traçabilité

## VUES CRITIQUES

Les vues suivantes sont considérées comme critiques :

- v_stock_actuel

### Pourquoi

- v_stock_actuel → source de vérité métier pour la lecture du stock actuel

### Règle

- Toute lecture métier du stock actuel doit passer par cette vue
- Aucun cache ou snapshot technique ne doit la remplacer comme source de vérité

## TRIGGERS CRITIQUES

Les triggers suivants sont considérés comme critiques :

- triggers liés aux réceptions
- triggers liés aux sorties_produit
- triggers liés au calcul / maintien du stock

### Pourquoi

Ces triggers :
- appliquent la logique métier critique
- calculent ou propagent les effets métier
- garantissent la cohérence des données

### Règle

- Ne jamais modifier un trigger critique sans analyse préalable
- Toute modification doit être testée en staging
- Toute suppression ou neutralisation doit être explicitement justifiée

## FONCTIONS CRITIQUES

Les fonctions suivantes sont considérées comme critiques :

- fonctions du moteur volumétrique ASTM
- fonctions de calcul de stock
- fonctions appliquant des effets métier (réception, sortie)

### Pourquoi

Ces fonctions :
- exécutent la logique métier critique
- garantissent la cohérence des calculs
- impactent directement les données métier

### Règle

- Ne jamais modifier une fonction critique sans validation
- Toute modification doit être testée en staging
- Toute évolution doit passer par migration

---

## DANGERS DB

Les opérations suivantes sont à haut risque :

- modification directe en production
- désactivation ou contournement de triggers
- modification d’une vue de stock sans analyse
- traitement d’un cache comme source de vérité
- modification du moteur volumétrique sans validation complète

---

## PROCÉDURE MINIMALE AVANT MODIFICATION

Avant toute modification d’un objet critique :

1. Identifier l’objet concerné
2. Vérifier s’il est critique (ce document)
3. Comprendre son rôle métier
4. Vérifier l’état staging / production
5. Passer par migration
6. Tester en staging
7. Documenter si nécessaire

---

## REQUÊTES SQL DE VÉRIFICATION

### Lister les triggers d’une table

```sql
SELECT tgname
FROM pg_trigger
WHERE tgrelid = 'public.receptions'::regclass
  AND NOT tgisinternal;
```

(Remplacer `receptions` par le nom de la table concernée, schéma `public` si applicable.)

### Vérifier une vue critique

```sql
SELECT *
FROM pg_views
WHERE schemaname = 'public'
  AND viewname = 'v_stock_actuel';
```

### Lister les fonctions du schéma ASTM

```sql
SELECT p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'astm'
ORDER BY p.proname;
```

### Vérifier les colonnes d’une table

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'receptions';
```
