// 📌 Module : Lots — Vue détail + métriques d’affichage (agrégats sur `cdrs` uniquement)
// 🧭 Pas de logique métier critique ; pas de Flutter ; pas d’I/O.

import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';

/// Données affichées sur l’écran détail lot (lot + cours de route associés).
class LotDetailView {
  const LotDetailView({
    required this.lot,
    required this.cdrs,
  });

  final FournisseurLot lot;
  final List<CoursDeRoute> cdrs;

  /// Synthèse d’exploitation dérivée des CDR déjà chargés (lecture seule).
  LotDetailMetrics get metrics => LotDetailMetrics.fromCdrs(cdrs);
}

/// Agrégats UI calculés à partir de `view.cdrs` (`volume` null → 0).
class LotDetailMetrics {
  const LotDetailMetrics({
    required this.totalCdr,
    required this.countChargement,
    required this.countTransit,
    required this.countFrontiere,
    required this.countArrive,
    required this.countDecharge,
    required this.volumeTotalDeclared,
    required this.volumeArrived,
    required this.volumeDischarged,
    required this.volumeRemainingNonDischarged,
  });

  final int totalCdr;
  final int countChargement;
  final int countTransit;
  final int countFrontiere;
  final int countArrive;
  final int countDecharge;

  final double volumeTotalDeclared;
  final double volumeArrived;
  final double volumeDischarged;
  final double volumeRemainingNonDischarged;

  double get dischargedFraction {
    if (volumeTotalDeclared <= 0) return 0;
    return (volumeDischarged / volumeTotalDeclared).clamp(0.0, 1.0);
  }

  factory LotDetailMetrics.fromCdrs(List<CoursDeRoute> cdrs) {
    var nCh = 0;
    var nTr = 0;
    var nFr = 0;
    var nAr = 0;
    var nDe = 0;
    var volTotal = 0.0;
    var volArrived = 0.0;
    var volDischarged = 0.0;

    for (final c in cdrs) {
      final v = c.volume ?? 0.0;
      volTotal += v;

      switch (c.statut) {
        case StatutCours.chargement:
          nCh++;
          break;
        case StatutCours.transit:
          nTr++;
          break;
        case StatutCours.frontiere:
          nFr++;
          break;
        case StatutCours.arrive:
          nAr++;
          break;
        case StatutCours.decharge:
          nDe++;
          break;
      }

      if (c.statut == StatutCours.arrive || c.statut == StatutCours.decharge) {
        volArrived += v;
      }
      if (c.statut == StatutCours.decharge) {
        volDischarged += v;
      }
    }

    final remaining = (volTotal - volDischarged).clamp(0.0, double.infinity);

    return LotDetailMetrics(
      totalCdr: cdrs.length,
      countChargement: nCh,
      countTransit: nTr,
      countFrontiere: nFr,
      countArrive: nAr,
      countDecharge: nDe,
      volumeTotalDeclared: volTotal,
      volumeArrived: volArrived,
      volumeDischarged: volDischarged,
      volumeRemainingNonDischarged: remaining,
    );
  }
}
