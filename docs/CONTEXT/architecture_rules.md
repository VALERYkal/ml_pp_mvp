# ARCHITECTURE RULES — ML_PP MVP

## ROLE
Définir les règles absolues du système, protéger les zones critiques et empêcher toute dérive technique ou IA.

## UPDATE FREQUENCY
Uniquement si une règle structurelle du système change.

## SCOPE
Ce fichier fixe le cadre contraignant du système.

Il fait autorité sur :
- les règles d’architecture
- les interdictions critiques
- le comportement attendu de l’IA

Il ne remplace pas :
- system_invariants.md (qui contient le détail des invariants métier)

Relation entre les documents :
- architecture_rules.md → cadre global (non négociable)
- system_invariants.md → invariants détaillés
- current_checkpoint.md → état opérationnel

Toute contradiction entre ces documents doit être résolue explicitement.

## ORDRE DE VÉRITÉ SYSTÈME

1. Base de données (source de vérité absolue)
2. Invariants métier (system_invariants.md)
3. Code applicatif
4. Pack canonique
5. Documentation secondaire

Règles :

- En cas de conflit :
  - toujours s’aligner sur la DB et les invariants
  - jamais l’inverse

- Le pack canonique est une représentation contrôlée de la réalité.
  Il doit rester aligné avec la DB.

## INVARIANTS NON NÉGOCIABLES

Les invariants métier détaillés sont définis dans system_invariants.md.

Principes fondamentaux à respecter en toute circonstance :

- La DB est la source de vérité
- Le stock est calculé uniquement en DB
- Les calculs volumétriques sont réalisés uniquement en DB
- La logique métier critique ne doit pas être implémentée côté frontend
- Les opérations métier validées sont immuables
- Toute modification du système doit préserver les invariants existants

## RÈGLES DB

La base de données est le cœur du système.

Toute modification doit être considérée comme critique.

---

### MODIFICATIONS

- Toute modification passe par migration
- Aucune modification directe en production
- Les changements doivent être versionnés

---

### OBJETS CRITIQUES

Sont considérés comme critiques :

- triggers
- fonctions
- vues de stock (ex: v_stock_actuel)

Toute modification de ces objets :
- nécessite une validation explicite
- doit être testée en staging

---

### INTERDICTIONS

Il est interdit de :

- modifier directement la DB en production
- bypass les triggers
- recalculer le stock hors DB
- dupliquer la logique métier côté application

---

### STAGING → PRODUCTION

Toute évolution doit suivre :

1. migration staging
2. validation
3. déploiement production

**Référence normative :** **`STAGING`** est l’environnement où la **logique critique** (stock, volumétrie, triggers métier) doit être **validée** avant toute application en **`PROD`**. Sauf **exception explicitement gouvernée** (runbook, décision tracée), il n’y a pas de « contournement » de cette séquence.

---

### ALIGNEMENT

- staging et production doivent rester alignés
- tout écart doit être identifié et corrigé
- tout écart STAGING / PROD sur **logique critique** (stock, volumétrie, triggers métier) doit être **corrigé sans délai** après constat
- le **pipeline stock** (réception / sortie) est une zone **P0**
- toute **divergence sur les volumes @15 °C** dans ce pipeline est **bloquante** jusqu’à résolution

## RÈGLES FRONTEND

Le frontend ne doit jamais implémenter une machine d’état métier parallèle à la base.

Exemple interdit:
- état local différent de `statut`
- enum métier non aligné DB
- logique de transition indépendante

Le frontend n’est pas une source de vérité.

Son rôle est de :
- afficher les données
- orchestrer les actions utilisateur
- appliquer les règles d’interface
- transmettre les données à la DB

---

### INTERDICTIONS

Le frontend ne doit jamais :

- recalculer le stock métier
- recalculer la volumétrie métier
- reproduire la logique métier critique de la DB
- supposer qu’un document secondaire prévaut sur la DB

---

### RESPONSABILITÉS

Le frontend peut :

- valider les champs pour l’expérience utilisateur
- guider la saisie
- afficher des états et messages
- appliquer les règles de navigation
- consommer les sources canoniques

---

### PRIORITÉ

En cas de conflit entre frontend et DB :
- la DB a toujours raison

## NON-RÉGRESSION

Les zones stables du système ne doivent pas être modifiées sans justification explicite.

Zones particulièrement sensibles :
- Réception
- Stock
- Moteur ASTM
- Triggers, fonctions et vues critiques

---

### RÈGLE

Toute modification sur une zone stable doit :

- être explicitement justifiée
- respecter les invariants existants
- être validée en staging si elle touche la DB
- mettre à jour le pack canonique si nécessaire

---

### INTERDICTION

Il est interdit de :

- refactorer une zone stable sans besoin réel
- modifier une zone stable “par simplification”
- changer un comportement critique sans validation explicite

## RÈGLES IA CRITIQUES

L’IA doit agir dans un cadre strict.

---

### INTERDICTIONS

L’IA ne doit jamais :

- inventer une structure de base de données
- supposer un comportement métier non confirmé
- modifier un objet critique sans validation
- contourner les règles définies dans ce document

---

### COMPORTEMENT ATTENDU

L’IA doit :

- s’appuyer sur le pack canonique
- respecter l’ordre de vérité système
- vérifier la DB si nécessaire
- rester dans le périmètre défini

---

### EN CAS DE DOUTE

L’IA doit :

- demander confirmation
- ou proposer sans exécuter

## QUAND VÉRIFIER LA DB

La vérification de la base de données est obligatoire dans les cas suivants :

- modification de la DB proposée
- logique métier critique
- incohérence détectée
- doute sur le stock ou la volumétrie

---

### SINON

- se fier au pack canonique
- ne pas sur-interroger la DB inutilement

## MODE DE TRAVAIL

Toute intervention doit suivre l’ordre suivant :

1. Lire current_checkpoint.md
2. Appliquer architecture_rules.md
3. Identifier les zones concernées via architecture_map.md
4. Vérifier la DB si nécessaire
5. Proposer une solution dans le périmètre autorisé
6. Valider en staging si la DB est impactée
7. Mettre à jour le pack canonique si nécessaire
