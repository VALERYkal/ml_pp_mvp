// 📌 Module : Stocks journaliers - Service minimal MAJ

import 'package:supabase_flutter/supabase_flutter.dart';

class StocksService {
  final SupabaseClient _client;
  StocksService.withClient(this._client);

  /// Formate une date en YYYY-MM-DD pour la base de données
  String _fmtYmd(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  /// Incrémente (ou crée) la ligne de stock pour (date du jour, citerne, produit)
  Future<void> increment({
    required String citerneId,
    required String produitId,
    required double volumeAmbiant,
    required double volume15c,
    DateTime? dateJour,
  }) async {
    final date = _fmtYmd(dateJour ?? DateTime.now());
    // Upsert naïf: tenter update sinon insert
    final existing = await _client
        .from('stocks_journaliers')
        .select()
        .eq('citerne_id', citerneId)
        .eq('produit_id', produitId)
        .eq('date_jour', date)
        .maybeSingle();

    if (existing != null) {
      final current = existing as Map<String, dynamic>;
      final newAmb = (current['stock_ambiant'] as num).toDouble() + volumeAmbiant;
      final new15 = (current['stock_15c'] as num).toDouble() + volume15c;
      await _client
          .from('stocks_journaliers')
          .update({'stock_ambiant': newAmb, 'stock_15c': new15})
          .eq('id', current['id']);
    } else {
      await _client.from('stocks_journaliers').insert({
        'citerne_id': citerneId,
        'produit_id': produitId,
        'date_jour': date,
        'stock_ambiant': volumeAmbiant,
        'stock_15c': volume15c,
      });
    }
  }

  /// Retourne le stock ambiant (litres) pour la date du jour, sinon 0 si absent.
  Future<double> getAmbientForToday({
    required String citerneId,
    required String produitId,
    DateTime? dateJour,
  }) async {
    final date = _fmtYmd(dateJour ?? DateTime.now());
    final res = await _client
        .from('stocks_journaliers')
        .select('stock_ambiant')
        .eq('citerne_id', citerneId)
        .eq('produit_id', produitId)
        .eq('date_jour', date)
        .maybeSingle();
    if (res == null) return 0.0;
    final m = res as Map<String, dynamic>;
    return (m['stock_ambiant'] as num).toDouble();
  }

  /// Décrémente les stocks journaliers (ambiant & 15°C) pour une citerne/produit.
  /// Symétrique de `increment(...)`. Les volumes passés sont POSITIFS.
  Future<void> decrement({
    required String citerneId,
    required String produitId,
    required double volumeAmbiant,
    required double volume15c,
  }) async {
    // Implémentation simple : réutilise increment avec valeurs négatives
    await increment(
      citerneId: citerneId,
      produitId: produitId,
      volumeAmbiant: -volumeAmbiant,
      volume15c: -volume15c,
    );
  }

  /// Renvoie le stock 15°C du jour pour une citerne/produit.
  Future<double> getV15ForToday({
    required String citerneId,
    required String produitId,
    DateTime? dateJour,
  }) async {
    final row = await _client
        .from('stocks_journaliers')
        .select('stock_15c')
        .eq('citerne_id', citerneId)
        .eq('produit_id', produitId)
        .eq('date_jour', _fmtYmd(dateJour ?? DateTime.now()))
        .maybeSingle();

    if (row == null) return 0.0;
    final v = (row['stock_15c'] as num?)?.toDouble() ?? 0.0;
    return v.isFinite ? v : 0.0;
  }
}


