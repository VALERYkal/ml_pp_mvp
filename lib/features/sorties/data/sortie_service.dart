// 📌 Module : Sorties - Service (validation uniquement)


import 'package:supabase_flutter/supabase_flutter.dart';
import '../../stocks_journaliers/data/stocks_service.dart';

class SortieService {
  final SupabaseClient _client;
  final StocksService Function(SupabaseClient) _stocksServiceFactory;

  SortieService(this._client, {StocksService Function(SupabaseClient)? stocksServiceFactory})
      : _stocksServiceFactory = stocksServiceFactory ?? ((c) => StocksService.withClient(c));

  factory SortieService.withClient(SupabaseClient client) => SortieService(client);

  Future<void> validate({required String sortieId, required bool canValidate}) async {
    if (!canValidate) {
      throw StateError('Droits insuffisants pour valider la sortie');
    }

    // 1) Récupération de la sortie
    final sortie = await _client.from('sorties_produit').select().eq('id', sortieId).single() as Map<String, dynamic>;
    if (sortie['statut'] != 'brouillon') {
      throw ArgumentError('Seules les sorties en brouillon peuvent être validées');
    }

    // 2) Vérifier stock suffisant (owner)
    final citerneId = sortie['citerne_id'];
    final produitId = sortie['produit_id'];
    // final owner = sortie['proprietaire_type']; // 'MONALUXE' | 'PARTENAIRE'
    final volAmb = (sortie['volume_ambiant'] as num?)?.toDouble() ?? 0.0;
    final vol15 = (sortie['volume_corrige_15c'] as num?)?.toDouble() ?? 0.0;

    // Vérifier stock disponible
    final stocksService = _stocksServiceFactory(_client);
    final stockToday = await stocksService.getAmbientForToday(
      citerneId: citerneId,
      produitId: produitId,
    );
    if (volAmb > stockToday) {
      throw StateError('Stock ambiant insuffisant pour valider cette sortie');
    }

    // Vérifier stock 15°C disponible
    final stock15 = await stocksService.getV15ForToday(
      citerneId: citerneId,
      produitId: produitId,
    );
    if (vol15 > stock15) {
      throw StateError('Stock 15°C insuffisant pour valider cette sortie');
    }

    // 3) RPC ou update direct (fallback)
    try {
      await _client.rpc('validate_sortie', params: {'p_sortie_id': sortieId});
    } catch (_) {
      await _client.from('sorties_produit').update({'statut': 'validee'}).eq('id', sortieId);
    }

    // 4) Décrémenter le stock
    await stocksService.decrement(
      citerneId: citerneId,
      produitId: produitId,
      volumeAmbiant: volAmb,
      volume15c: vol15,
    );

    // 5) Log action
    await _client.from('log_actions').insert({
      'action': 'SORTIE_VALIDE',
      'module': 'sorties',
      'niveau': 'INFO',
      'details': {'sortie_id': sortieId},
      'cible_id': sortieId,
    });
  }
}


