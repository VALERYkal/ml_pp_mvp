# Tests manuels – Trigger Sorties → Stocks journaliers (SEL-1 à SEL-6)

## 1. Contexte & objectif

Ces tests valident le pipeline complet :

`sorties_produit` (INSERT)  
→ trigger `fn_sorties_after_insert()`  
→ appel `stock_upsert_journalier(...)`  
→ mise à jour de `stocks_journaliers` avec séparation par propriétaire  
(MONALUXE / PARTENAIRE) et par citerne.

Objectifs :

- vérifier que chaque sortie produit débite correctement `stocks_journaliers`  
- valider les cas mono-propriétaire et multi-propriétaires (citerne mixte)  
- valider le comportement multi-citernes sur une même journée  
- garantir l’absence d’erreurs de contrainte UNIQUE et d’écritures incohérentes.

## 2. Prérequis globaux
(… contenu complet déjà généré précédemment …)
