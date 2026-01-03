import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/errors/stocks_adjustments_exception.dart';

class StocksAdjustmentsService {
  final SupabaseClient _client;
  StocksAdjustmentsService(this._client);

  // AXE A — Les ajustements sont la SEULE façon officielle de corriger le stock après validation.
  Future<void> createAdjustment({
    required String mouvementType, // 'RECEPTION' | 'SORTIE'
    required String mouvementId,    // uuid
    required double deltaAmbiant,
    double delta15c = 0.0,
    required String reason,
  }) async {
    // 1) Normaliser + valider
    final type = mouvementType.trim().toUpperCase();
    final id = mouvementId.trim();
    final r = reason.trim();

    if (type != 'RECEPTION' && type != 'SORTIE') {
      throw StocksAdjustmentsException(
        "Type de mouvement invalide (attendu: RECEPTION ou SORTIE).",
      );
    }
    if (id.isEmpty) {
      throw StocksAdjustmentsException("Identifiant du mouvement invalide.");
    }
    if (deltaAmbiant == 0) {
      throw StocksAdjustmentsException(
        "Delta ambiant invalide : la valeur ne peut pas être 0.",
      );
    }
    if (r.length < 10) {
      throw StocksAdjustmentsException(
        "Raison trop courte : minimum 10 caractères.",
      );
    }

    // 2) Récupérer l'utilisateur authentifié
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StocksAdjustmentsException(
        'Utilisateur non authentifié: impossible de créer un ajustement.',
      );
    }
    final userId = user.id;

    // 3) Insert (payload minimal - DB triggers complètent le reste)
    try {
      // 🔴 TEMP DEBUG AXE A — à supprimer après diagnostic
      debugPrint(
        '🧾 [AXE A][stocks_adjustments] payload: mouvement_type=$type mouvement_id=$id delta_ambiant=$deltaAmbiant delta_15c=$delta15c created_by=$userId',
      );

      await _client.from('stocks_adjustments').insert({
        'mouvement_type': type,
        'mouvement_id': id,
        'delta_ambiant': deltaAmbiant,
        'delta_15c': delta15c,
        'reason': r,
        'created_by': userId,
      });
    } on PostgrestException catch (e) {
      // 🔴 TEMP DEBUG AXE A — à supprimer après diagnostic
      debugPrint('❌ [AXE A][stocks_adjustments] Erreur Supabase PostgrestException lors de createAdjustment');
      debugPrint('➡️ message = ${e.message}');
      debugPrint('➡️ details = ${e.details}');
      debugPrint('➡️ hint = ${e.hint}');
      debugPrint('➡️ code = ${e.code}');

      final msg = e.message.toLowerCase();

      // Détection plus robuste des erreurs de droits
      final isRlsOrPerm =
          msg.contains('rls') ||
          msg.contains('row level security') ||
          msg.contains('permission') ||
          msg.contains('not allowed') ||
          msg.contains('insufficient_privilege') ||
          msg.contains('insufficient privilege');

      if (isRlsOrPerm) {
        throw StocksAdjustmentsException(
          "Droits insuffisants : seul un admin peut créer un ajustement.",
        );
      }

      throw StocksAdjustmentsException(
        "Erreur lors de la création de l'ajustement.",
      );
    } catch (error, stackTrace) {
      // 🔴 TEMP DEBUG AXE A — à supprimer après diagnostic
      debugPrint('❌ [AXE A][stocks_adjustments] Erreur brute lors de createAdjustment');
      debugPrint('➡️ error.runtimeType = ${error.runtimeType}');
      debugPrint('➡️ error = $error');
      debugPrint('➡️ stackTrace = $stackTrace');

      // Si erreur Supabase (Postgrest)
      if (error is PostgrestException) {
        debugPrint('🧱 Supabase PostgrestException');
        debugPrint('➡️ message = ${error.message}');
        debugPrint('➡️ details = ${error.details}');
        debugPrint('➡️ hint = ${error.hint}');
        debugPrint('➡️ code = ${error.code}');
      }

      throw StocksAdjustmentsException(
        "Erreur lors de la création de l'ajustement.",
      );
    }
  }
}

