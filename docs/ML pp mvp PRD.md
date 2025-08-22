
# PRD – ML_PP MVP v3.0

## 📌 Objectif général
Créer une application de gestion logistique pétrolière pour Monaluxe permettant de suivre les flux de carburant à travers les modules : authentification, cours de route, réception, sorties, citernes, stock journalier, logs et dashboard.

---

## ✅ Modules Inclus dans le MVP

### 🔐 Authentification
- Connexion sécurisée via Supabase
- Gestion des rôles : admin, directeur, gérant, opérateur, pca, lecture

### 🛣 Cours de Route
- Création dès le chargement chez le fournisseur
- Champs : produit, plaques, transporteur, date, volume, etc.
- Statuts : chargement → transit → frontière → arrivé
- Une fois le statut “arrivé” atteint, déclenchement du formulaire de réception
- Les cours “déchargés” ne sont plus visibles dans la liste principale

### 📥 Réception Produit
#### Cas 1 : Propriétaire = Monaluxe
- Liée à un cours de route
- Validation par admin/directeur/gérant
- Vérification des documents, mesure volume, température, densité
- Calcul volume 15°C
- Affectation à une citerne compatible
- Mise à jour stock Monaluxe
- Journalisation (log_actions)

#### Cas 2 : Propriétaire = Partenaire
- Sans lien avec un cours de route
- Même processus métier que ci-dessus
- Affectation à une citerne théoriquement partagée
- Stock non intégré au stock disponible Monaluxe

### 📤 Sortie Produit
- Dédution du stock Monaluxe ou partenaire
- Sélection produit + citerne + propriétaire
- Mesure volume brut/température/densité
- Calcul du volume à 15°C
- Journalisation (log_actions)
- Multi-citerne → Une sortie peut puiser dans plusieurs citernes

### 🛢 Citernes
- Champs : nom, capacité, sécurité, produit, statut (active/inactive)
- Lecture seule sauf pour admin
- Gestion théorique des volumes par propriétaire
- Pas de mélange de produits, mais mélange de propriétaires autorisé
- Journalisation : création, modification, désactivation

### 📊 Stocks Journaliers
- Générés automatiquement après chaque réception/sortie validée
- Lecture seule sauf action manuelle admin
- Affichage brut / 15 °C / par citerne / par propriétaire
- Exportables en CSV ou PDF

### 📚 Référentiels (Lecture seule via Supabase)
- Fournisseurs
- Produits
- Dépôts
- Clients
- Citernes
**⚠️ Alimentation manuelle via Supabase (admin uniquement)**

### 📈 Dashboard
- Récap volumes stockés, reçus, sortis
- Filtres : date, produit, citerne, propriétaire
- Alertes :
  - ❗ Seuil de sécurité bas
  - 🛢 Citerne vide ou inactive
  - 🚫 Erreur de validation d’une sortie ou réception
  - 🔐 Tentative d’accès non autorisé

### 🧾 Logs
- Toutes actions critiques sont historisées
- Exemples : RECEPTION_CREEE, SORTIE_VALIDE, CITERNE_MODIFIEE
- Visible selon rôle

---

## 🛡 Sécurité & Permissions (Supabase RLS)
- 🔐 Authentification : via Supabase (JWT)
- 🧾 RLS activées par table
- Tables sécurisées par rôle utilisateur
- Audit trail pour chaque action critique

---

## ❗ Gestion des erreurs critiques
- ❌ Volume > capacité citerne → erreur bloquante
- ❌ Volume négatif → rejet de l’enregistrement
- ❌ Saisie dans citerne inactive → rejet
- ⚠ Rôle non autorisé → interdiction d’action (lecture seule)

---

## 🧪 Tests critiques recommandés
- ✅ Tester qu’un opérateur ne peut pas valider une réception
- ✅ Valider une sortie sur une citerne partagée (stock partenaire)
- ✅ Vérifier que les volumes à 15 °C sont calculés correctement
- ✅ Recalcul des stocks après réception/sortie
- ✅ Vérifier comportement des alertes du dashboard

---

## 📖 Glossaire des termes métier
| Terme                  | Définition |
|------------------------|------------|
| Volume à 15 °C         | Volume corrigé à température de référence |
| BL/CMR                 | Bordereau de Livraison / Convention Marchandise Routière |
| Capacité de sécurité   | Volume réservé pour la sécurité (ex. incendie) |
| Partenaire             | Client ou fournisseur tiers non-Monaluxe |
| Cours de route         | Transport entrant de produits avant réception |
| RLS (Row Level Security)| Mécanisme de filtrage par utilisateur Supabase |

---

## ⚠ Risques anticipés
- ⚡ Recalculs de stock fréquents → impact performance
- 📊 Affichage de gros volumes de données (stocks journaliers) → pagination nécessaire
- 🔒 Sécurité des rôles mal définie → exposition des données sensibles
- 🌐 Connectivité lente → fallback partiel offline requis


### SUPPLÉMENT PRD – Version MVP août 2025

#### 1) Réception Produit (mono-citerne, index)
- Limitation MVP
  - Une réception ne peut concerner qu’une seule citerne.
- Données obligatoires (nouveau)
  - `index_avant` (double precision, NOT NULL)
  - `index_apres` (double precision, NOT NULL)
- Calculs
  - Le volume ambiant est déduit de la différence `index_apres - index_avant`.
  - Le volume corrigé à 15 °C est calculé à partir du volume ambiant, de `temperature_ambiante_c` et de `densite_a_15`.
- Clés et intégrité
  - `citerne_id` et `produit_id` sont désormais NOT NULL.
  - La propriété (`proprietaire_type` = MONALUXE | PARTENAIRE) est conservée, avec validations métier inchangées.
- Impacts fonctionnels
  - Validation des indices (≥ 0 et `index_apres > index_avant`).
  - Mise à jour des stocks journaliers (incrément) après validation.

#### 2) Sortie Produit (mono-citerne, bénéficiaire obligatoire)
- Limitation MVP
  - Une sortie ne peut concerner qu’une seule citerne.
- Données obligatoires (nouveau)
  - `index_avant` (double precision, NOT NULL)
  - `index_apres` (double precision, NOT NULL)
  - `citerne_id` et `produit_id` (NOT NULL)
- Bénéficiaire (nouvelle contrainte)
  - Au moins un bénéficiaire doit être défini: `client_id` IS NOT NULL OU `partenaire_id` IS NOT NULL.
- Calculs et mesures
  - Le volume ambiant est déduit de la différence `index_apres - index_avant`.
  - Conserver `volume_corrige_15c`, `temperature_ambiante_c`, `densite_a_15` pour calcul réglementaire.
- Impacts fonctionnels
  - Vérification produit/citerne (pas de mélange).
  - Vérification de disponibilité du stock (stock du jour ≥ volume ambiant).
  - Mise à jour des stocks journaliers (décrément) après validation.

#### 3) Nouvelles contraintes DB
- Réceptions
  ```sql
  ALTER TABLE public.receptions
  ALTER COLUMN citerne_id SET NOT NULL,
  ALTER COLUMN produit_id SET NOT NULL;
  ```
- Sorties produit
  ```sql
  ALTER TABLE public.sorties_produit
  ALTER COLUMN citerne_id SET NOT NULL,
  ALTER COLUMN produit_id SET NOT NULL,
  ADD CONSTRAINT sorties_produit_beneficiaire_check
    CHECK (client_id IS NOT NULL OR partenaire_id IS NOT NULL);
  ```

#### 4) Impact sur les workflows, UI et validations (Flutter)
- Formulaire Réception (MVP)
  - Champs requis: produit, citerne, `index_avant`, `index_apres`.
  - Validations UI:
    - `index_avant >= 0`, `index_apres >= 0`, et `index_apres > index_avant`.
    - produit/citerne sélectionnés.
  - Calculs:
    - Volume ambiant = `index_apres - index_avant`.
    - Volume 15 °C calculé (si `temperature_ambiante_c` et `densite_a_15` fournis; sinon fallback MVP).
  - Stock:
    - Incrément du stock journalier après validation.
- Formulaire Sortie (MVP)
  - Champs requis: produit, citerne, `index_avant`, `index_apres`, et (client OU partenaire).
  - Validations UI:
    - `index_avant >= 0`, `index_apres >= 0`, et `index_apres > index_avant`.
    - produit/citerne sélectionnés.
    - bénéficiaire obligatoire (client ou partenaire).
  - Calculs:
    - Volume ambiant = `index_apres - index_avant`.
    - Volume 15 °C calculé (si mesures fournies; sinon fallback MVP).
  - Stock:
    - Décrément du stock journalier après validation.
- Messagerie d’erreur
  - Messages explicites pour chaque contrainte (indices, sélections, bénéficiaire).
- Tests (unitaires & E2E)
  - Adapter les scénarios pour couvrir:
    - Réception: indices incohérents, citerne inactive, produit incompatible, capacité insuffisante.
    - Sortie: indices incohérents, citerne inactive, produit incompatible, stock insuffisant, bénéficiaire manquant.
  - Vérifier l’impact sur MAJ des stocks journaliers (incrément/décrément) et la journalisation (log_actions).