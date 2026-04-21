import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';

void main() {
  group('FournisseurFactureLot.fromMap', () {
    test('parse correctement avec types mixtes', () {
      final map = {
        'facture_id': 'id-1',
        'invoice_no': 'INV-001',
        'deal_reference': 'LOT-001',
        'fournisseur_lot_id': 'lot-1',
        'nb_receptions': '2',
        'total_volume_15c': '1000.5',
        'total_volume_20c': 1002,
        'quantite_facturee_20c': 1002.0,
        'ecart_volume_20c': '0.5',
        'statut_rapprochement': 'OK',
        'prix_unitaire_usd': '850',
        'montant_total_usd': 850000,
        'montant_regle_usd': '500000',
        'solde_restant_usd': '350000',
        'statut_paiement': 'PARTIEL',
        'date_facture': '2026-04-12',
        'date_echeance': '2026-05-12',
        'created_at': '2026-04-12T10:00:00Z',
      };

      final result = FournisseurFactureLot.fromMap(map);

      expect(result.factureId, 'id-1');
      expect(result.nbReceptions, 2);
      expect(result.totalVolume15c, closeTo(1000.5, 1e-9));
      expect(result.totalVolume20c, closeTo(1002.0, 1e-9));
      expect(result.montantRegleUsd, 500000);
      expect(result.soldeRestantUsd, 350000);
      expect(result.dateFacture, isNotNull);
    });

    test('fallback safe si null', () {
      final map = <String, dynamic>{};

      final result = FournisseurFactureLot.fromMap(map);

      expect(result.factureId, '');
      expect(result.nbReceptions, isNull);
      expect(result.totalVolume15c, isNull);
    });
  });

  group('CreateFournisseurFactureLotInput.toMap', () {
    test('map correct pour insertion', () {
      final input = CreateFournisseurFactureLotInput(
        fournisseurLotId: ' lot-1 ',
        invoiceNo: ' INV-001 ',
        dealReference: ' ref ',
        dateFacture: DateTime(2026, 4, 12),
        dateEcheance: null,
        quantiteFacturee20c: 1000,
        prixUnitaireUsd: 850,
      );

      final map = input.toMap();

      expect(map['fournisseur_lot_id'], 'lot-1');
      expect(map['invoice_no'], 'INV-001');
      expect(map['deal_reference'], 'ref');
      expect(map['date_facture'], '2026-04-12');
    });
  });

  group('CreateFournisseurPaiementLotInput.toMap', () {
    test('map correct avec nulls', () {
      final input = CreateFournisseurPaiementLotInput(
        fournisseurFactureId: ' fact-1 ',
        datePaiement: null,
        montantPayeUsd: 1000,
        modePaiement: '',
        referencePaiement: null,
        note: ' note ',
      );

      final map = input.toMap();

      expect(map['fournisseur_facture_id'], 'fact-1');
      expect(map['mode_paiement'], isNull);
      expect(map['note'], 'note');
    });
  });
}