// 📌 Libellés / tri / couleurs UI uniquement (données issues de `v_fournisseur_facture_lot`).

import 'package:flutter/material.dart';

/// Statut de synthèse affiché (aucune logique métier ; combinaison lecture des champs vue).
String getStatutGlobal({
  required String statutRapprochement,
  required String statutPaiement,
}) {
  final sr = statutRapprochement.trim().toUpperCase();
  final sp = statutPaiement.trim().toUpperCase();

  if (sr == 'LITIGE') return 'LITIGE';
  if (sr == 'A_RAPPROCHER') return 'A_CONTROLER';
  if (sp == 'A_PAYER') return 'A_PAYER';
  if (sp == 'PARTIEL') return 'EN_COURS';
  if (sp == 'PAYE' || sp == 'PAYÉ') return 'SOLDE';
  return 'A_PAYER';
}

/// Priorité de tri : LITIGE → A_CONTROLER → A_PAYER → EN_COURS → SOLDE
int statutGlobalSortKey(String code) {
  switch (code.trim()) {
    case 'LITIGE':
      return 0;
    case 'A_CONTROLER':
      return 1;
    case 'A_PAYER':
      return 2;
    case 'EN_COURS':
      return 3;
    case 'SOLDE':
      return 4;
    default:
      return 2;
  }
}

/// Couleurs Material (synthèse liste / dashboard).
Color couleurStatutGlobal(String code) {
  switch (code.trim()) {
    case 'LITIGE':
      return const Color(0xFFD32F2F);
    case 'A_CONTROLER':
      return const Color(0xFFFF9800);
    case 'A_PAYER':
      return const Color(0xFFFFC107);
    case 'EN_COURS':
      return const Color(0xFF1976D2);
    case 'SOLDE':
      return const Color(0xFF388E3C);
    default:
      return const Color(0xFF757575);
  }
}
