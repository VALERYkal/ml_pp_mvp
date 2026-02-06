# Runbook — Stock externe dépôt ami (citerne logique)

**Document** : Procédure et cadre opérationnel pour la solution temporaire "stock externe dépôt ami"  
**Version** : 1.0  
**Date** : 2026-02-06  
**Périmètre** : PROD — documentation uniquement (aucune modification de code MVP)

---

## 1. Pourquoi cette solution existe

- **Besoin temporaire** : Comptabiliser le stock Monaluxe physiquement situé chez un dépôt partenaire (dépôt ami), sans attendre une évolution fonctionnelle de l’application.
- **Objectifs** :
  - Rendre ce stock **visible** dans le système (stocks, dashboard).
  - Permettre des **sorties clients** depuis ce dépôt ami (livraisons).
  - Conserver la **propriété Monaluxe** du stock (comptabilité interne).
- **Contrainte** : Aucun changement de code MVP (lib/), ni de tests, ni de scripts — solution 100 % côté données (Supabase).

> **Pourquoi on ne touche pas au code MVP**  
> La solution repose sur l’utilisation d’une **citerne logique** dans la table `citernes` existante. L’application affiche déjà les citernes actives et gère réceptions/sorties par citerne. En ajoutant une ligne en base (via SQL Editor), on obtient une “citerne externe” sans toucher à Flutter ni aux seeds. Évolution temporaire, réversible, et traçable.

---

## 2. Principe : citerne logique externe

- **Citerne logique** = une ligne dans `public.citernes` qui représente un stock physiquement **hors site Monaluxe** (dépôt ami).
- **Localisation physique** : Externe ; **propriété** : Monaluxe conservée.
- **Référentiel** : Même dépôt technique que le site principal (`depot_id` = dépôt Monaluxe) pour rester dans le périmètre RLS/métier actuel, avec un **nom** et une **localisation** explicites (ex. "SEP CONGO", "DEPOT AMI 2") pour éviter toute confusion avec TANK1–TANK6.

**Exemple en place** :
- Citerne : **SEP CONGO**
- Produit : AGO (Gasoil/Diesel)
- Capacité : 1 000 000 L
- Usage : Stock Monaluxe chez partenaire ; sorties clients depuis ce dépôt ami.

---

## 3. Règles non négociables

| Règle | Description |
|-------|-------------|
| **Produit unique** | Uniquement **AGO** (Gasoil/Diesel) — produit_id `22222222-2222-2222-2222-222222222222`. |
| **Notes obligatoires** | Toute réception et toute sortie sur une citerne “dépôt ami” doivent avoir une **note** explicite (origine, client, contexte). |
| **Pas de réceptions dépôt Monaluxe** | Les réceptions sur citernes dépôt ami ne doivent **pas** être utilisées pour enregistrer des livraisons arrivant au dépôt Monaluxe principal (TANK1–TANK6). |
| **Fin de période** | En fin de période d’usage : **mise à zéro du stock** (sorties ou ajustement documenté) puis **mise en statut `inactive`** de la citerne (voir encadré ci-dessous). |

> **Fin de période : mise inactive**  
> Lorsque le stock externe dépôt ami n’est plus utilisé :  
> 1) S’assurer que le stock théorique de la citerne est à zéro (sorties ou procédure documentée).  
> 2) Mettre la citerne en **statut `inactive`** : `UPDATE public.citernes SET statut = 'inactive' WHERE nom = 'SEP CONGO';` (ou nom concerné).  
> 3) Ne pas supprimer la ligne tant que des réceptions/sorties y sont liées (historique). Documenter la date et la raison de l’inactivation.

---

## 4. Risques et mitigation

| Risque | Mitigation |
|--------|------------|
| Mauvais usage (réception sur la mauvaise citerne) | Règles opérationnelles : notes obligatoires ; formation ; contrôle des réceptions/sorties par citerne. |
| Mélange stock physique / logique | Nom et localisation explicites (ex. "Stock externe Monaluxe - Depot ami X (temporaire)"). Pas d’usage des citernes dépôt ami pour le dépôt Monaluxe principal. |
| Confusion dans les rapports | Vérifier dashboard et listes citernes après création ; s’assurer que la citerne externe est bien identifiée par son nom. |

---

## 5. Checklist de validation après création

Après toute création ou modification de citerne externe, vérifier :

- [ ] **Citernes** : La citerne apparaît dans la liste des citernes (nom, localisation, capacité).
- [ ] **Stocks** : Le stock de la citerne est visible (v_stock_actuel / UI stock actuel).
- [ ] **Dashboard** : Les KPI / totaux reflètent ou distinguent correctement la citerne si applicable.
- [ ] **Réceptions** : Possibilité de créer une réception sur cette citerne ; note renseignée.
- [ ] **Sorties** : Possibilité de créer/valider une sortie depuis cette citerne ; note renseignée.

---

## 6. Procédure SQL Editor — Création d’une citerne externe supplémentaire

Procédure à exécuter dans **Supabase → SQL Editor**, sur l’environnement **PROD** (ou STAGING si validation préalable).

### Étape 1 — Vérifier l’environnement

Exécuter :

```sql
SELECT current_database(), current_schema();
```

S’assurer que l’on travaille bien sur la base et le schéma attendus (ex. projet PROD, schéma `public`). **Ne pas exécuter d’INSERT en production sans vérification.**

### Étape 2 — Récupérer les IDs requis

- **Produit AGO** (Gasoil/Diesel) : `22222222-2222-2222-2222-222222222222`
- **Dépôt** (Dépôt Daipn) : `11111111-1111-1111-1111-111111111111`

Vérification optionnelle :

```sql
SELECT id, nom, code FROM public.produits WHERE code = 'G.O';
SELECT id, nom FROM public.depots WHERE id = '11111111-1111-1111-1111-111111111111';
```

### Étape 3 — INSERT citerne

Créer une **nouvelle citerne** avec un UUID généré, nom explicite, capacité et localisation cohérentes avec la solution “dépôt ami”.

**Exemple pour un 2ᵉ dépôt ami** (convention de nom : "DEPOT AMI 2", capacité 1 000 000 L, alignée sur SEP CONGO) :

```sql
INSERT INTO public.citernes (
  id,
  depot_id,
  nom,
  capacite_totale,
  capacite_securite,
  localisation,
  statut,
  created_at,
  produit_id
) VALUES (
  gen_random_uuid(),
  '11111111-1111-1111-1111-111111111111',
  'DEPOT AMI 2',
  1000000,
  0,
  'Stock externe Monaluxe - Depot ami 2 (temporaire)',
  'active',
  NOW(),
  '22222222-2222-2222-2222-222222222222'
);
```

- **nom** : "DEPOT AMI 2" (ou "DEPOT_AMI_2" selon convention équipe — ici aligné sur un libellé lisible).
- **capacite_totale** : 1 000 000 L (cohérent avec SEP CONGO).
- **localisation** : Texte explicite pour traçabilité et éviter la confusion avec le site principal.

### Étape 4 — Vérification SELECT

Après l’INSERT, vérifier la présence de la citerne :

```sql
SELECT id, nom, depot_id, capacite_totale, localisation, statut, produit_id
FROM public.citernes
WHERE nom IN ('SEP CONGO', 'DEPOT AMI 2')
ORDER BY nom;
```

Contrôler que la nouvelle ligne est bien présente et que les champs sont corrects.

### Étape 5 — Rollback / annulation (documentation)

En cas d’**erreur de saisie** ou de **citerne créée par erreur** (avant toute réception/sortie) :

- **Option A — Mise inactive (recommandé si des mouvements existent)**  
  `UPDATE public.citernes SET statut = 'inactive' WHERE nom = 'DEPOT AMI 2';`  
  Conserver la ligne pour l’historique.

- **Option B — Suppression (uniquement si aucun mouvement)**  
  S’assurer qu’aucune réception ni sortie ne référence la citerne :  
  `SELECT COUNT(*) FROM public.receptions WHERE citerne_id = '<uuid_citerne>';`  
  `SELECT COUNT(*) FROM public.sorties_produit WHERE citerne_id = '<uuid_citerne>';`  
  Si les deux comptes sont 0 :  
  `DELETE FROM public.citernes WHERE id = '<uuid_citerne>';`  
  **Quand** : Immédiatement après création par erreur, avant toute utilisation.

**Quand faire un rollback** : Dès que l’erreur est constatée (mauvais dépôt, mauvais produit, doublon, etc.). En production, privilégier la mise `inactive` sauf cas de création purement erronée sans aucun mouvement.

---

## 7. Références

- **État PROD** : `docs/00_REFERENCE/PROD_STATUS.md`
- **Contrat vues stock** : `docs/db/stocks_views_contract.md`
- **Seed / référentiels** : `staging/sql/seed_staging_prod_like.sql` (citernes TANK1–TANK6 + produits canoniques)

---

**Document créé le** : 2026-02-06  
**Dernière mise à jour** : 2026-02-06  
**Aucune modification** : lib/, test/, scripts/
