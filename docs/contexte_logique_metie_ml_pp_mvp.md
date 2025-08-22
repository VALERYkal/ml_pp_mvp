Contexte Logique Métier – ML_PP MVP
Dernière mise à jour : 2025-08-06
ML_PP MVP est une application logistique offline-first développée pour la société Monaluxe. Elle assure la traçabilité complète d’un litre de carburant depuis son chargement chez le fournisseur jusqu’à sa consommation finale.
Cycle global de la vie d’un produit (carburant)
Fournisseur → Cours de Route → Réception → Citerne → Prises de hauteur / Stocks journaliers / Sorties produit → Client
1. Authentification & Profils
- Connexion via Supabase
- Chaque utilisateur a un profil métier (table `profils`) avec :
  - nom complet
  - rôle (admin, directeur, gérant, pca, lecture)
  - dépôt de rattachement
- Navigation contrôlée par rôle (GoRouter + Shell)
2. Cours de Route
Point d’entrée du carburant dans le circuit logistique.
- Créé dès le chargement chez le fournisseur
- Données : produit, fournisseur, transporteur, plaques, volume, date, pays, dépôt destination
- Statuts évolutifs : chargement → transit → frontière → arrivé → déchargé
- Alimente le module Réception
3. Réception
Validation de l’arrivée du carburant au dépôt.
- Rattachée à un cours de route
- Données : citerne, index compteur, température, densité, volume corrigé, produit, partenaire
- Représente l’entrée physique dans le stock
4. Citernes
- Réservoirs de stockage dans les dépôts
- Données : capacité, type produit, localisation, statut
- Cible des réceptions, source des sorties
- Support des prises de hauteur & stocks journaliers
5. Prises de hauteur
- Mesure manuelle du volume dans une citerne
- Sert à vérifier le stock réel vs théorique
- Peut détecter pertes ou écarts
6. Stocks journaliers
- Historique des quantités par citerne et par jour
- Calculé sur base des réceptions, sorties, prises
- Deux valeurs : stock ambiant et corrigé à 15°C
- Sert à l’audit et suivi logistique
7. Sorties produit
- Traçabilité des litres sortis d’un dépôt
- Données : citerne, produit, client, partenaire, volume 15°C
- Sert à ajuster les stocks, préparer la facturation
8. Fournisseurs, Partenaires, Clients
- Fournisseurs : source de carburant (cours de route)
- Partenaires : co-propriétaires ou acteurs secondaires
- Clients : destinataires des sorties (livraison/facturation)
9. Profils & Rôles
- admin, directeur, gérant, pca, lecture
- Filtrage des accès, routes, modules selon le rôle
- Assignation via table `profils`
10. Journalisation (Log Actions)
- Trace toutes les actions sensibles des utilisateurs
- Données : action, module, niveau, user_id, détails JSON
- Sert à l’audit, la conformité, le suivi de sécurité
Conclusion
Ce document structure la logique métier de ML_PP MVP pour aligner tous les développements (UI, services, tests, API) avec la réalité terrain. Il est à compléter au fur et à mesure avec les cas d’usage spécifiques.
