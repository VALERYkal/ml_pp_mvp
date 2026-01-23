
# ✅ 1.1 – Schéma de base de données (Supabase)

## 🧱 Structure Générale

Ce schéma a été conçu pour répondre aux exigences métier de la gestion logistique pétrolière chez Monaluxe, avec un souci de cohérence, de traçabilité et de performances. Il repose sur :

- **UUID** comme identifiant unique pour toutes les tables (même référentielles)
- **Row-Level Security (RLS)** activée pour toutes les tables sensibles
- **Historique (log_actions)** pour toutes les opérations critiques
- **Relation N-N** via des tables de liaison quand nécessaire (multi-citerne)
- **Contraintes nommées** pour plus de lisibilité

## 📂 Référentiels

### `depots`
- `id UUID PRIMARY KEY`
- `nom TEXT`
- `adresse TEXT`
- `created_at TIMESTAMPTZ DEFAULT now()`

### `produits`
- `id UUID PRIMARY KEY`
- `nom TEXT UNIQUE`
- `code TEXT UNIQUE`
- `description TEXT`
- `actif BOOLEAN DEFAULT true`
- `created_at TIMESTAMPTZ DEFAULT now()`

### `clients`, `fournisseurs`, `partenaires`
- `id UUID PRIMARY KEY`
- `nom TEXT UNIQUE`
- `contact_personne`, `email`, `telephone`, `adresse`, `pays`, `note_supplementaire`
- `created_at TIMESTAMPTZ DEFAULT now()`

## 🛢️ Stockage

### `citernes`
- `id UUID PRIMARY KEY`
- `depot_id UUID REFERENCES depots(id) CONSTRAINT fk_citerne_depot`
- `nom TEXT`
- `capacite_totale DOUBLE PRECISION CHECK (>0)`
- `capacite_securite DOUBLE PRECISION CHECK (>=0)`
- `produit_id UUID REFERENCES produits(id) CONSTRAINT fk_citernes_produit_id`
- `localisation TEXT`
- `statut TEXT CHECK ('active', 'inactive', 'maintenance') DEFAULT 'active'`
- `created_at TIMESTAMPTZ DEFAULT now()`

### `prises_de_hauteur`
- `id UUID PRIMARY KEY`
- `citerne_id UUID REFERENCES citernes(id)`
- `volume_mesure DOUBLE PRECISION CHECK (>= 0)`
- `note TEXT`
- `created_at TIMESTAMPTZ DEFAULT now()`

## 🚚 Transport & Réception

### `cours_de_route`
- `id UUID PRIMARY KEY`
- `fournisseur_id UUID REFERENCES fournisseurs(id)`
- `depot_destination_id UUID REFERENCES depots(id)`
- `produit_id UUID REFERENCES produits(id)`
- `plaque_camion`, `plaque_remorque`, `chauffeur_nom`, `transporteur`, `depart_pays`
- `date_chargement DATE`
- `volume NUMERIC`
- `statut TEXT CHECK ('chargement', 'transit', 'frontière', 'arrivé', 'déchargé') DEFAULT 'chargement'`
- `note TEXT`
- `created_at TIMESTAMPTZ DEFAULT now()`

### `receptions`
- `id UUID PRIMARY KEY`
- `cours_de_route_id UUID REFERENCES cours_de_route(id)`
- `citerne_id UUID REFERENCES citernes(id)`
- `produit_id UUID REFERENCES produits(id)`
- `partenaire_id UUID REFERENCES partenaires(id)`
- `index_avant DOUBLE PRECISION`
- `index_apres DOUBLE PRECISION`
- `volume_corrige_15c DOUBLE PRECISION`
- `temperature_ambiante_c DOUBLE PRECISION`
- `densite_a_15 DOUBLE PRECISION`
- `proprietaire_type TEXT CHECK ('MONALUXE', 'PARTENAIRE') DEFAULT 'MONALUXE'`
- `note TEXT`
- `created_at TIMESTAMPTZ DEFAULT now()`

## 📤 Sortie

### `sorties_produit`
- `id UUID PRIMARY KEY`
- `produit_id UUID REFERENCES produits(id)`
- `client_id UUID REFERENCES clients(id)`
- `partenaire_id UUID REFERENCES partenaires(id)`
- `volume_corrige_15c DOUBLE PRECISION`
- `temperature_ambiante_c DOUBLE PRECISION`
- `densite_a_15 DOUBLE PRECISION`
- `proprietaire_type TEXT CHECK ('MONALUXE', 'PARTENAIRE') DEFAULT 'MONALUXE'`
- `note TEXT`
- `created_at TIMESTAMPTZ DEFAULT now()`

### `sortie_citerne` ✅ [Ajouté pour gérer les multi-citernes]
- `id UUID PRIMARY KEY`
- `sortie_id UUID REFERENCES sorties_produit(id)`
- `citerne_id UUID REFERENCES citernes(id)`
- `volume DOUBLE PRECISION`

## 📊 Stock

### `stocks_journaliers`
- `id UUID PRIMARY KEY`
- `citerne_id UUID REFERENCES citernes(id)`
- `produit_id UUID REFERENCES produits(id)`
- `date_jour DATE`
- `stock_ambiant DOUBLE PRECISION`
- `stock_15c DOUBLE PRECISION`

## 👤 Profils & Permissions

### `profils`
- `id UUID PRIMARY KEY`
- `user_id UUID REFERENCES auth.users(id)`
- `nom_complet TEXT`
- `email TEXT`
- `role TEXT CHECK ('admin', 'directeur', 'gerant', 'opérateur', 'lecture', 'pca')`
- `depot_id UUID REFERENCES depots(id)`
- `created_at TIMESTAMPTZ DEFAULT now()`

## 🧾 Journalisation

### `log_actions`
- `id UUID PRIMARY KEY`
- `user_id UUID REFERENCES auth.users(id)`
- `action TEXT`
- `module TEXT`
- `niveau TEXT CHECK ('INFO', 'WARNING', 'CRITICAL') DEFAULT 'INFO'`
- `details JSONB`
- `cible_id UUID` ✅ [Ajouté pour tracer l'élément concerné]
- `created_at TIMESTAMPTZ DEFAULT now()`

## 📌 Remarques complémentaires

- **Toutes les unités** sont exprimées clairement dans les champs : litres, °C, etc.
- **Contraintes nommées** à intégrer dans les migrations PostgreSQL pour faciliter le debug et l’évolution.
- **Transactions recommandées** pour les opérations critiques (réceptions, sorties).
- **Multi-citerne** géré via `sortie_citerne`.

✅ **Statut** : Ce schéma est validé pour la phase de développement du MVP.
