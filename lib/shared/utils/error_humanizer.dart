// ?? Module : Shared Utils
// ?? Description : Humanisation des erreurs de base de données

import 'package:postgrest/postgrest.dart';

/// Utilitaires pour humaniser les erreurs de base de données
class ErrorHumanizer {
  /// Humanise une erreur PostgrestException
  ///
  /// [e] : L'exception PostgrestException
  ///
  /// Retourne :
  /// - `String` : Message d'erreur humanisé en français
  static String humanizePostgrest(PostgrestException e) {
    final message = e.message.toLowerCase();
    final details = e.details?.toString().toLowerCase() ?? '';
    final hint = e.hint?.toString().toLowerCase() ?? '';

    // Erreurs d'authentification et permissions
    if (message.contains('permission denied') || message.contains('row level security')) {
      return 'Accès refusé. Vérifiez vos permissions.';
    }

    // Erreurs de contraintes de clés étrangères
    if (message.contains('foreign key') || message.contains('violates foreign key')) {
      if (details.contains('citerne_id')) {
        return 'Citerne introuvable ou inactive.';
      }
      if (details.contains('produit_id')) {
        return 'Produit introuvable ou inactif.';
      }
      if (details.contains('cours_de_route_id')) {
        return 'Cours de route introuvable.';
      }
      if (details.contains('client_id')) {
        return 'Client introuvable.';
      }
      if (details.contains('partenaire_id')) {
        return 'Partenaire introuvable.';
      }
      return 'Référence invalide. Vérifiez les données sélectionnées.';
    }

    // Erreurs de contraintes CHECK
    if (message.contains('check constraint') || message.contains('violates check constraint')) {
      if (details.contains('index_apres') || details.contains('index_avant')) {
        return 'Indices incohérents : l\'index après doit être supérieur à l\'index avant.';
      }
      if (details.contains('volume') && details.contains('capacite')) {
        return 'Volume supérieur à la capacité disponible de la citerne.';
      }
      if (details.contains('statut')) {
        return 'Statut invalide pour cette opération.';
      }
      if (details.contains('proprietaire_type')) {
        return 'Type de propriétaire invalide.';
      }
      if (details.contains('beneficiaire') ||
          details.contains('client_id') ||
          details.contains('partenaire_id')) {
        return 'Bénéficiaire requis : sélectionnez un client ou un partenaire.';
      }
      return 'Données invalides. Vérifiez les valeurs saisies.';
    }

    // Erreurs de contraintes UNIQUE
    if (message.contains('duplicate key') || message.contains('unique constraint')) {
      if (details.contains('plaque_camion') || details.contains('date_chargement')) {
        return 'Un cours de route existe déjà avec cette plaque et cette date de chargement.';
      }
      return 'Cette entrée existe déjà.';
    }

    // Erreurs de contraintes NOT NULL
    if (message.contains('null value') || message.contains('not null constraint')) {
      if (details.contains('citerne_id')) {
        return 'Citerne requise.';
      }
      if (details.contains('produit_id')) {
        return 'Produit requis.';
      }
      if (details.contains('index_avant') || details.contains('index_apres')) {
        return 'Indices avant et après requis.';
      }
      return 'Champ obligatoire manquant.';
    }

    // Erreurs métier spécifiques
    if (message.contains('produit_citerne_mismatch')) {
      return 'Produit incompatible avec la citerne sélectionnée.';
    }
    if (message.contains('citerne_inactive')) {
      return 'Citerne inactive. Sélectionnez une citerne active.';
    }
    if (message.contains('stock_insuffisant')) {
      return 'Stock insuffisant pour cette sortie.';
    }
    if (message.contains('capacite_depassee')) {
      return 'Capacité de la citerne dépassée.';
    }
    if (message.contains('index_incoherents')) {
      return 'Indices incohérents : vérifiez les valeurs saisies.';
    }
    if (message.contains('immutable_non_brouillon')) {
      return 'Cette entrée ne peut plus être modifiée.';
    }

    // Erreurs de réseau et connexion
    if (message.contains('network') || message.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre réseau.';
    }
    if (message.contains('timeout')) {
      return 'Délai d\'attente dépassé. Réessayez.';
    }

    // Erreurs de validation côté serveur
    if (message.contains('validation') || message.contains('invalid')) {
      return 'Données invalides. Vérifiez les informations saisies.';
    }

    // Erreurs génériques
    if (message.contains('internal server error')) {
      return 'Erreur interne du serveur. Contactez l\'administrateur.';
    }

    // Si aucune correspondance, retourner le message original avec contexte
    return 'Erreur de base de données : ${e.message}';
  }

  /// Humanise une erreur générique
  ///
  /// [error] : L'erreur à humaniser
  ///
  /// Retourne :
  /// - `String` : Message d'erreur humanisé
  static String humanizeError(dynamic error) {
    if (error is PostgrestException) {
      return humanizePostgrest(error);
    }

    final message = error.toString().toLowerCase();

    // Erreurs d'authentification
    if (message.contains('auth') || message.contains('login')) {
      return 'Erreur d\'authentification. Vérifiez vos identifiants.';
    }

    // Erreurs de validation
    if (message.contains('validation') || message.contains('invalid')) {
      return 'Données invalides. Vérifiez les informations saisies.';
    }

    // Erreurs de réseau
    if (message.contains('network') || message.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre réseau.';
    }

    // Erreurs de timeout
    if (message.contains('timeout')) {
      return 'Délai d\'attente dépassé. Réessayez.';
    }

    // Erreurs génériques
    return 'Une erreur inattendue s\'est produite. Réessayez.';
  }

  /// Obtient le niveau de sévérité d'une erreur
  ///
  /// [error] : L'erreur à analyser
  ///
  /// Retourne :
  /// - `String` : Niveau de sévérité ('INFO', 'WARNING', 'ERROR', 'CRITICAL')
  static String getErrorSeverity(dynamic error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();

      // Erreurs critiques
      if (message.contains('permission denied') || message.contains('internal server error')) {
        return 'CRITICAL';
      }

      // Erreurs d'erreur
      if (message.contains('foreign key') ||
          message.contains('check constraint') ||
          message.contains('validation')) {
        return 'ERROR';
      }

      // Erreurs d'avertissement
      if (message.contains('timeout') || message.contains('network')) {
        return 'WARNING';
      }
    }

    return 'ERROR';
  }
}




