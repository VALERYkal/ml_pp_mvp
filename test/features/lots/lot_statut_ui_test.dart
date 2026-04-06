import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots/lot_statut_ui.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';

void main() {
  test('canCloseLot / canMarkLotAsFactured / CDR edit / readOnly', () {
    expect(canCloseLot(StatutFournisseurLot.ouvert), true);
    expect(canCloseLot(StatutFournisseurLot.cloture), false);
    expect(canMarkLotAsFactured(StatutFournisseurLot.cloture), true);
    expect(canMarkLotAsFactured(StatutFournisseurLot.ouvert), false);
    expect(lotStatutAllowsCdrLinkEdit(StatutFournisseurLot.ouvert), true);
    expect(lotStatutAllowsCdrLinkEdit(StatutFournisseurLot.cloture), false);
    expect(isLotReadOnly(StatutFournisseurLot.facture), true);
    expect(isLotReadOnly(StatutFournisseurLot.cloture), false);
  });
}
