// ?? Module : Cours de Route - Audit Logs
// ?? Description : Service de logging des transitions d'état CDR

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cdr_etat.dart';

/// Service de logging des transitions d'état CDR
///
/// Enregistre toutes les transitions d'état pour l'audit et la traçabilité.
class CdrLogsService {
  /// Client Supabase injecté via le constructeur
  final SupabaseClient _supabase;

  /// Constructeur avec injection du client Supabase
  CdrLogsService.withClient(this._supabase);

  /// Enregistre une transition d'état
  ///
  /// [cdrId] : Identifiant du cours de route
  /// [from] : État de départ
  /// [to] : État d'arrivée
  /// [userId] : Identifiant de l'utilisateur qui effectue la transition
  /// [at] : Timestamp de la transition (optionnel, défaut: maintenant)
  ///
  /// Retourne :
  /// - `Future<void>` : Succès de l'opération
  ///
  /// Gestion d'erreur :
  /// - `PostgrestException` : Erreur de communication avec Supabase
  /// - `Exception` : Erreur de conversion des données
  Future<void> logTransition({
    required String cdrId,
    required CdrEtat from,
    required CdrEtat to,
    required String userId,
    DateTime? at,
  }) async {
    try {
      final payload = {
        'cdr_id': cdrId,
        'from': from.name,
        'to': to.name,
        'user_id': userId,
        'at': (at ?? DateTime.now()).toIso8601String(),
      };

      await _supabase.from('cdr_logs').insert(payload);
    } on PostgrestException catch (e) {
      // Log l'erreur mais ne pas faire échouer la transition
      print('Erreur lors de l\'enregistrement du log CDR: ${e.message}');
      rethrow;
    } catch (e) {
      // Log l'erreur mais ne pas faire échouer la transition
      print('Erreur inattendue lors de l\'enregistrement du log CDR: $e');
      rethrow;
    }
  }
}

