// 📌 Module : Lots — Visibilité des actions selon le statut (présentation uniquement).
// 🧭 La DB impose le workflow ; ces helpers ne font que refléter l’UI attendue.

import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';

/// Propose le bouton « Clôturer le lot » (statut `ouvert` uniquement).
bool canCloseLot(StatutFournisseurLot statut) =>
    statut == StatutFournisseurLot.ouvert;

/// Propose le bouton « Marquer comme facturé » (statut `cloture` uniquement).
bool canMarkLotAsFactured(StatutFournisseurLot statut) =>
    statut == StatutFournisseurLot.cloture;

/// Rattachement / détachement CDR autorisés en UI seulement pour un lot ouvert.
bool lotStatutAllowsCdrLinkEdit(StatutFournisseurLot statut) =>
    statut == StatutFournisseurLot.ouvert;

/// Lot facturé : plus aucune action de transition ni de lien CDR côté UI.
bool isLotReadOnly(StatutFournisseurLot statut) =>
    statut == StatutFournisseurLot.facture;
