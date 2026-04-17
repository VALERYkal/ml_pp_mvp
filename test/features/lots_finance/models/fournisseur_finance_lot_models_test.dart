import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';

void main() {
  group('FournisseurFactureLot.fromMap', () {
    test('parse une map complète avec types mixtes', () {
      final m = <String, dynamic>{
        'facture_id': 42,
        'invoice_no': 'INV-99',
        'deal_reference': '  DEAL  ',
        'fournisseur_lot_id': 'lot-a',
        'nb_receptions': '3',
        'total_volume_15c': '10.5',
        'total_volume_20c': 20,
        'quantite_facturee_20c': 18.25,
        'ecart_volume_20c': '-1.5',
        'statut_rapprochement': 'ok',
        'prix_unitaire_usd': '2',
        'montant_total_usd': 100.0,
        'montant_regle_usd': '50',
        'solde_restant_usd': 50,
        'statut_paiement': 'partiel',
        'date_facture': '2025-06-01',
        'date_echeance': '2025-07-15T00:00:00.000Z',
        'created_at': '2025-06-02T12:30:00.000Z',
      };

      final f = FournisseurFactureLot.fromMap(m);

      expect(f.factureId, '42');
      expect(f.invoiceNo, 'INV-99');
      expect(f.dealReference, 'DEAL');
      expect(f.fournisseurLotId, 'lot-a');
      expect(f.nbReceptions, 3);
      expect(f.totalVolume15c, 10.5);
      expect(f.totalVolume20c, 20.0);
      expect(f.quantiteFacturee20c, 18.25);
      expect(f.ecartVolume20c, -1.5);
      expect(f.statutRapprochement, 'ok');
      expect(f.prixUnitaireUsd, 2.0);
      expect(f.montantTotalUsd, 100.0);
      expect(f.montantRegleUsd, 50.0);
      expect(f.soldeRestantUsd, 50.0);
      expect(f.statutPaiement, 'partiel');
      expect(f.dateFacture, DateTime.tryParse('2025-06-01'));
      expect(f.dateEcheance, DateTime.tryParse('2025-07-15T00:00:00.000Z'));
      expect(f.createdAt, DateTime.tryParse('2025-06-02T12:30:00.000Z'));
    });

    test('map vide : chaînes vides et numériques à 0, dates null', () {
      final f = FournisseurFactureLot.fromMap({});

      expect(f.factureId, '');
      expect(f.invoiceNo, '');
      expect(f.dealReference, isNull);
      expect(f.fournisseurLotId, '');
      expect(f.nbReceptions, 0);
      expect(f.totalVolume15c, 0.0);
      expect(f.statutRapprochement, '');
      expect(f.statutPaiement, '');
      expect(f.dateFacture, isNull);
      expect(f.dateEcheance, isNull);
      expect(f.createdAt, isNull);
    });

    test('map partielle : champs manquants sans crash', () {
      final f = FournisseurFactureLot.fromMap({
        'facture_id': 'x',
        'invoice_no': 'i',
      });

      expect(f.factureId, 'x');
      expect(f.invoiceNo, 'i');
      expect(f.fournisseurLotId, '');
      expect(f.montantTotalUsd, 0.0);
    });
  });

  group('FournisseurRapprochementLot.fromMap', () {
    test('parse types mixtes', () {
      final m = <String, dynamic>{
        'facture_id': 'f1',
        'invoice_no': 100,
        'deal_reference': null,
        'fournisseur_lot_id': 99,
        'nb_receptions': 2.9,
        'total_volume_15c': '1',
        'total_volume_20c': '2',
        'quantite_facturee_20c': 3,
        'ecart_volume_20c': 0,
        'prix_unitaire_usd': '12.34',
        'montant_total_usd': 99,
        'statut_rapprochement': 'vert',
      };

      final r = FournisseurRapprochementLot.fromMap(m);

      expect(r.factureId, 'f1');
      expect(r.invoiceNo, '100');
      expect(r.dealReference, isNull);
      expect(r.fournisseurLotId, '99');
      expect(r.nbReceptions, 2);
      expect(r.totalVolume15c, 1.0);
      expect(r.prixUnitaireUsd, 12.34);
      expect(r.montantTotalUsd, 99.0);
      expect(r.statutRapprochement, 'vert');
    });

    test('map minimale : valeurs par défaut sûres', () {
      final r = FournisseurRapprochementLot.fromMap({});

      expect(r.factureId, '');
      expect(r.invoiceNo, '');
      expect(r.dealReference, isNull);
      expect(r.ecartVolume20c, 0.0);
    });
  });

  group('CreateFournisseurFactureLotInput.toMap', () {
    test('trim, date_facture YYYY-MM-DD, deal null si vide, date_echeance null', () {
      final input = CreateFournisseurFactureLotInput(
        fournisseurLotId: '  lot-1  ',
        invoiceNo: '  INV  ',
        dealReference: '   ',
        dateFacture: DateTime.utc(2025, 3, 5, 14, 0),
        dateEcheance: null,
        quantiteFacturee20c: 10,
        prixUnitaireUsd: 1.5,
      );

      final map = input.toMap();

      expect(map['fournisseur_lot_id'], 'lot-1');
      expect(map['invoice_no'], 'INV');
      expect(map['deal_reference'], isNull);
      expect(map['date_facture'], '2025-03-05');
      expect(map['date_echeance'], isNull);
      expect(map['quantite_facturee_20c'], 10.0);
      expect(map['prix_unitaire_usd'], 1.5);
    });

    test('deal_reference conservé si non vide ; date_echeance format date', () {
      final input = CreateFournisseurFactureLotInput(
        fournisseurLotId: 'l',
        invoiceNo: 'n',
        dealReference: 'REF',
        dateFacture: DateTime.utc(2025, 1, 1),
        dateEcheance: DateTime.utc(2025, 12, 31),
        quantiteFacturee20c: 0,
        prixUnitaireUsd: 0,
      );

      final map = input.toMap();

      expect(map['deal_reference'], 'REF');
      expect(map['date_echeance'], '2025-12-31');
    });
  });

  group('CreateFournisseurPaiementLotInput.toMap', () {
    test('trim fournisseur_facture_id ; date_paiement si non null ; champs vides → null', () {
      final input = CreateFournisseurPaiementLotInput(
        fournisseurFactureId: '  fac-1  ',
        datePaiement: DateTime.utc(2025, 4, 1, 10, 0),
        montantPayeUsd: 123.45,
        modePaiement: '  ',
        referencePaiement: '',
        note: '   ',
      );

      final map = input.toMap();

      expect(map['fournisseur_facture_id'], 'fac-1');
      expect(map['date_paiement'], '2025-04-01T10:00:00.000Z');
      expect(map['montant_paye_usd'], 123.45);
      expect(map['mode_paiement'], isNull);
      expect(map['reference_paiement'], isNull);
      expect(map['note'], isNull);
    });

    test('sans date_paiement : clé absente ; valeurs non vides conservées', () {
      final input = CreateFournisseurPaiementLotInput(
        fournisseurFactureId: 'id',
        datePaiement: null,
        montantPayeUsd: 1,
        modePaiement: 'virement',
        referencePaiement: 'REF-9',
        note: 'ok',
      );

      final map = input.toMap();

      expect(map.containsKey('date_paiement'), isFalse);
      expect(map['montant_paye_usd'], 1.0);
      expect(map['mode_paiement'], 'virement');
      expect(map['reference_paiement'], 'REF-9');
      expect(map['note'], 'ok');
    });
  });
}
