import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots/models/lot_detail_view.dart';

CoursDeRoute _cdr({
  required String id,
  required StatutCours statut,
  double? volume,
}) {
  return CoursDeRoute.empty().copyWith(
    id: id,
    fournisseurId: 'f',
    produitId: 'p',
    depotDestinationId: 'd',
    statut: statut,
    volume: volume,
  );
}

void main() {
  group('LotDetailMetrics.fromCdrs', () {
    test('cas vide : 0 CDR, volumes neutres', () {
      final m = LotDetailMetrics.fromCdrs(const []);
      expect(m.totalCdr, 0);
      expect(m.countChargement, 0);
      expect(m.countTransit, 0);
      expect(m.countFrontiere, 0);
      expect(m.countArrive, 0);
      expect(m.countDecharge, 0);
      expect(m.volumeTotalDeclared, 0);
      expect(m.volumeArrived, 0);
      expect(m.volumeDischarged, 0);
      expect(m.volumeRemainingNonDischarged, 0);
      expect(m.dischargedFraction, 0);
    });

    test('cas mixte : compteurs et volumes', () {
      final cdrs = [
        _cdr(id: '1', statut: StatutCours.chargement, volume: 10000),
        _cdr(id: '2', statut: StatutCours.arrive, volume: 5000),
        _cdr(id: '3', statut: StatutCours.decharge, volume: 3000),
      ];
      final m = LotDetailMetrics.fromCdrs(cdrs);

      expect(m.totalCdr, 3);
      expect(m.countChargement, 1);
      expect(m.countTransit, 0);
      expect(m.countFrontiere, 0);
      expect(m.countArrive, 1);
      expect(m.countDecharge, 1);

      expect(m.volumeTotalDeclared, 18000);
      expect(m.volumeArrived, 8000);
      expect(m.volumeDischarged, 3000);
      expect(m.volumeRemainingNonDischarged, 15000);
      expect(m.dischargedFraction, closeTo(3000 / 18000, 1e-9));
    });

    test('volume null → 0', () {
      final m = LotDetailMetrics.fromCdrs([
        _cdr(id: '1', statut: StatutCours.decharge, volume: null),
        _cdr(id: '2', statut: StatutCours.arrive, volume: 2000),
      ]);
      expect(m.volumeTotalDeclared, 2000);
      expect(m.volumeArrived, 2000);
      expect(m.volumeDischarged, 0);
      expect(m.volumeRemainingNonDischarged, 2000);
    });

    test('restant non déchargé ≥ 0', () {
      final m = LotDetailMetrics.fromCdrs([
        _cdr(id: '1', statut: StatutCours.decharge, volume: 5000),
      ]);
      expect(m.volumeRemainingNonDischarged, 0);
      expect(m.dischargedFraction, 1.0);
    });
  });

  group('LotDetailView.metrics', () {
    test('getter aligné sur fromCdrs', () {
      final lot = FournisseurLot.empty().copyWith(
        id: 'l',
        fournisseurId: 'f',
        produitId: 'p',
        reference: 'R',
      );
      final cdrs = [
        _cdr(id: '1', statut: StatutCours.transit, volume: 1000),
      ];
      final view = LotDetailView(lot: lot, cdrs: cdrs);
      expect(view.metrics.totalCdr, 1);
      expect(view.metrics.countTransit, 1);
      expect(view.metrics.volumeTotalDeclared, 1000);
    });
  });
}
