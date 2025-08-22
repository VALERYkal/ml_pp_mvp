/* ===========================================================
   ML_PP MVP — FakeDbPort (tests sans réseau)
   Rôle: Simuler un back-end Supabase pour tester le flux client.
   Pédagogie: On rejoue les validations serveur côté test pour
   couvrir les cas d'erreur et le happy path.
   =========================================================== */
import 'dart:math';
import 'package:ml_pp_mvp/shared/db/db_port.dart';

class FakeDbPort implements DbPort {
  FakeDbPort({
    this.initialStockAmbiant = 0.0,
    this.citerneCapaciteTotale = 100000.0,
    this.citerneCapaciteSecurite = 5000.0,
    this.citerneActive = true,
    this.coursArrive = true,
  });

  // Paramètres de simulation
  double initialStockAmbiant;
  double citerneCapaciteTotale;
  double citerneCapaciteSecurite;
  bool citerneActive;
  bool coursArrive;

  // Mémoire locale
  final Map<String, Map<String, dynamic>> receptions = {};
  final List<Map<String, dynamic>> logs = [];
  final Random _rnd = Random(42);

  // Fixtures référentiels
  // Produits ESS / AGO
  final _produits = <Map<String, dynamic>>[
    {'id': '11111111-1111-1111-1111-111111111111', 'code': 'ESS', 'nom': 'Essence', 'actif': true},
    {'id': '22222222-2222-2222-2222-222222222222', 'code': 'AGO', 'nom': 'Gasoil', 'actif': true},
  ];

  // Une citerne active compatible ESS (adapter si besoin)
  final _citernes = <Map<String, dynamic>>[
    {
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'produit_id': '11111111-1111-1111-1111-111111111111',
      'capacite_totale': 100000.0,
      'capacite_securite': 5000.0,
      'statut': 'active',
    }
  ];

  @override
  Future<Map<String, dynamic>> insertReception(Map<String, dynamic> payload) async {
    // Simuler calc volume_ambiant >= 0 (déjà fait côté client, mais on vérifie)
    final before = (payload['index_avant'] as double?) ?? 0;
    final after  = (payload['index_apres'] as double?) ?? 0;
    final volAmb = (after - before);
    if (before < 0 || after < 0 || !(after > before)) {
      throw Exception('Indices invalides: index_apres doit être > index_avant et >= 0');
    }
    if (volAmb <= 0) {
      throw Exception('Volume ambiant invalide (<=0)');
    }

    // Générer un id "stable"
    final id = 'rx_${_rnd.nextInt(999999)}';
    final rec = Map<String, dynamic>.from(payload);
    rec['id'] = id;
    rec['statut'] = payload['statut'] ?? 'brouillon';
    receptions[id] = rec;

    logs.add({'action': 'RECEPTION_CREEE', 'id': id, 'payload': payload});
    return {'id': id};
  }

  @override
  Future<void> rpcValidateReception(String receptionId) async {
    final rec = receptions[receptionId];
    if (rec == null) {
      throw Exception('Réception introuvable');
    }
    if (rec['statut'] != 'brouillon') {
      throw Exception('Seules les réceptions en brouillon peuvent être validées (statut=${rec['statut']})');
    }

    // Contrôles "serveur"
    // 1) Citerne active
    if (!citerneActive) {
      throw Exception('Citerne non active');
    }

    // 2) Compatibilité stricte: produit de la citerne == produit_id de la réception
    final prodIdRec = rec['produit_id'];
    final citerne = _citernes.firstWhere((c) => c['id'] == rec['citerne_id'], orElse: () => {});
    if (citerne.isEmpty || citerne['produit_id'] != prodIdRec) {
      throw Exception('Produit incompatible avec la citerne');
    }

    // 3) Capacité disponible (snapshot approximatif)
    final capTot = citerneCapaciteTotale;
    final capSec = citerneCapaciteSecurite;
    final stockActuel = initialStockAmbiant;
    final dispo = (capTot - capSec - stockActuel).clamp(0, double.infinity);
    final volAmb = (rec['volume_ambiant'] as double?) ?? 0;
    if (volAmb <= 0) {
      throw Exception('Volume ambiant invalide (<=0)');
    }
    if (volAmb > dispo) {
      throw Exception('Capacité insuffisante (disponible=$dispo, demandé=$volAmb)');
    }

    // 4) Cours de route (si lié) doit être "arrivé"
    if (rec['cours_de_route_id'] != null && !coursArrive) {
      throw Exception('Cours de route non éligible (doit être "arrivé")');
    }

    // 5) Propriété partenaire: partenaire_id requis
    if (rec['proprietaire_type'] == 'PARTENAIRE' && rec['partenaire_id'] == null) {
      throw Exception('partenaire_id requis pour PARTENAIRE');
    }

    // Si tout va bien -> valider
    rec['statut'] = 'validee';
    logs.add({'action': 'RECEPTION_VALIDEE', 'id': receptionId, 'vol_amb': volAmb});
  }

  @override
  Future<List<Map<String, dynamic>>> selectProduitsActifs() async {
    return _produits.where((p) => p['actif'] == true).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectCiternesActives() async {
    final list = List<Map<String, dynamic>>.from(_citernes);
    // injecter stats de capacité/stock simulées
    list[0]['capacite_totale'] = citerneCapaciteTotale;
    list[0]['capacite_securite'] = citerneCapaciteSecurite;
    list[0]['statut'] = citerneActive ? 'active' : 'inactive';
    return list;
  }
}


