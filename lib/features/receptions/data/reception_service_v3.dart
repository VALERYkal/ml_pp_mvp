/* ===========================================================
   ML_PP MVP  ReceptionService_v2 (testable)
   Rôle: Service équivalent à ReceptionService, mais injecté avec un DbPort.
   But: permettre des tests dintégration sans réseau via FakeDbPort.
   =========================================================== */
import 'package:ml_pp_mvp/shared/db/db_port.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';

class ReceptionServiceV2 {
  ReceptionServiceV2(this.dbPort);
  final DbPort dbPort;

  // Caches simples (imitent ReferentielsRepo, côté test seulement)
  List<Map<String, dynamic>>? _produits;
  List<Map<String, dynamic>>? _citernes;

  Future<void> _ensureRefsLoaded() async {
    _produits ??= await dbPort.selectProduitsActifs();
    _citernes ??= await dbPort.selectCiternesActives();
  }

  String? _getProduitIdByCode(String code) {
    final list = _produits ?? [];
    final up = code.toUpperCase();
    for (final m in list) {
      final c = (m['code'] ?? '').toString().toUpperCase();
      if (c == up) return m['id'] as String;
    }
    return null;
  }

  bool _isProduitCompatible(String citerneId, String produitId) {
    final list = _citernes ?? [];
    for (final c in list) {
      if (c['id'] == citerneId) {
        return c['produit_id'] == produitId && c['statut'] == 'active';
      }
    }
    return false;
  }

  Future<String> createDraft(ReceptionInput input) async {
    await _ensureRefsLoaded();

    final produitId = _getProduitIdByCode(input.produitCode);
    if (produitId == null) {
      throw Exception('Produit introuvable (code ${input.produitCode}).');
    }
    if (!_isProduitCompatible(input.citerneId, produitId)) {
      throw Exception('Produit incompatible avec la citerne sélectionnée.');
    }

    final volAmb = computeVolumeAmbiant(input.indexAvant, input.indexApres);
    final vol15 = computeV15(
      volumeAmbiant: volAmb,
      temperatureC: input.temperatureC,
      densiteA15: input.densiteA15,
      produitCode: input.produitCode,
    );

    final payload = {
      'proprietaire_type': input.proprietaireType,
      'partenaire_id': input.proprietaireType == 'PARTENAIRE'
          ? input.partenaireId
          : null,
      'citerne_id': input.citerneId,
      'produit_id': produitId,
      'index_avant': input.indexAvant,
      'index_apres': input.indexApres,
      'temperature_ambiante_c': input.temperatureC,
      'densite_a_15': input.densiteA15,
      'volume_ambiant': volAmb,
      'volume_corrige_15c': vol15,
      'cours_de_route_id': (input.proprietaireType == 'MONALUXE')
          ? input.coursDeRouteId
          : null,
      'note': input.note,
      'statut': 'brouillon',
    };

    final res = await dbPort.insertReception(payload);
    return res['id'] as String;
  }

  Future<void> validateReception(String receptionId) async {
    await dbPort.rpcValidateReception(receptionId);
  }
}

