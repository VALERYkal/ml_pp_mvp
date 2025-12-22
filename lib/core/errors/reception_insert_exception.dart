/// Exception centralisée pour les erreurs d'insertion de réception dans Postgres
/// 
/// Cette exception mappe les erreurs Postgres brutes en messages utilisateur
/// tout en conservant les détails techniques pour les logs.
/// 
/// DB-STRICT: Les réceptions sont créées directement validées via INSERT.
/// Aucune UPDATE/DELETE n'est autorisée (sauf admin compensation, hors scope).
class ReceptionInsertException implements Exception {
  /// Message utilisateur-friendly
  final String userMessage;
  
  /// Code d'erreur Postgres (ex: '23505' pour violation unique)
  final String? postgresCode;
  
  /// Message d'erreur Postgres brut
  final String? postgresMessage;
  
  /// Hint Postgres (si disponible)
  final String? hint;
  
  /// Détails bruts de l'erreur (pour logs)
  final dynamic rawDetails;
  
  /// Champ concerné (si identifiable)
  final String? field;
  
  const ReceptionInsertException({
    required this.userMessage,
    this.postgresCode,
    this.postgresMessage,
    this.hint,
    this.rawDetails,
    this.field,
  });
  
  /// Crée une ReceptionInsertException à partir d'une PostgrestException
  factory ReceptionInsertException.fromPostgrest(
    dynamic postgrestException, {
    String? field,
  }) {
    final code = postgrestException.code?.toString();
    final message = postgrestException.message?.toString() ?? '';
    final hint = postgrestException.hint?.toString();
    final details = postgrestException.details;
    
    // Mapping des codes Postgres vers messages utilisateur
    String userMsg;
    
    switch (code) {
      case '23505': // unique_violation
        if (message.contains('receptions_check_produit_citerne')) {
          userMsg = 'Produit incompatible avec la citerne sélectionnée.\n'
              'Vérifiez que la citerne contient bien ce produit.';
        } else if (message.contains('unique') || message.contains('duplicate')) {
          userMsg = 'Cette réception existe déjà.';
        } else {
          userMsg = 'Violation de contrainte unique.';
        }
        break;
        
      case '23503': // foreign_key_violation
        if (message.contains('citerne_id')) {
          userMsg = 'Citerne introuvable ou inaccessible.';
        } else if (message.contains('produit_id')) {
          userMsg = 'Produit introuvable ou inaccessible.';
        } else if (message.contains('cours_de_route_id')) {
          userMsg = 'Cours de route introuvable ou inaccessible.';
        } else if (message.contains('partenaire_id')) {
          userMsg = 'Partenaire introuvable ou inaccessible.';
        } else {
          userMsg = 'Référence invalide.';
        }
        break;
        
      case '23514': // check_violation
        if (message.contains('receptions_check_produit_citerne')) {
          userMsg = 'Produit incompatible avec la citerne sélectionnée.';
        } else if (message.contains('index_apres') || message.contains('index_avant')) {
          userMsg = 'Les indices sont incohérents (index après doit être > index avant).';
        } else if (message.contains('volume_ambiant') || message.contains('volume_corrige_15c')) {
          userMsg = 'Le volume calculé est invalide.';
        } else if (message.contains('proprietaire_type')) {
          userMsg = 'Type de propriétaire invalide.';
        } else if (message.contains('partenaire_id')) {
          userMsg = 'Partenaire obligatoire pour une réception PARTENAIRE.';
        } else {
          userMsg = 'Données invalides selon les règles métier.';
        }
        break;
        
      case '42501': // insufficient_privilege
        userMsg = 'Permissions insuffisantes pour créer une réception.';
        break;
        
      case 'PGRST116': // not found (Supabase)
        userMsg = 'Ressource introuvable.';
        break;
        
      default:
        // Message générique avec hint si disponible
        if (hint != null && hint.isNotEmpty) {
          userMsg = 'Erreur lors de l\'enregistrement: $hint';
        } else if (message.isNotEmpty) {
          // Extraire un message plus lisible si possible
          final cleanMsg = message
              .replaceAll(RegExp(r'^ERROR:\s*'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          userMsg = 'Erreur lors de l\'enregistrement: $cleanMsg';
        } else {
          userMsg = 'Une erreur est survenue lors de l\'enregistrement de la réception.';
        }
    }
    
    return ReceptionInsertException(
      userMessage: userMsg,
      postgresCode: code,
      postgresMessage: message,
      hint: hint,
      rawDetails: details,
      field: field,
    );
  }
  
  @override
  String toString() {
    final parts = <String>[];
    if (field != null) parts.add('field: $field');
    if (postgresCode != null) parts.add('code: $postgresCode');
    if (hint != null) parts.add('hint: $hint');
    
    final detailsStr = parts.isEmpty 
        ? userMessage 
        : '$userMessage (${parts.join(', ')})';
    
    return 'ReceptionInsertException: $detailsStr';
  }
  
  /// Retourne un message détaillé pour les logs (inclut tous les détails techniques)
  String toLogString() {
    return 'ReceptionInsertException {\n'
        '  userMessage: $userMessage\n'
        '  postgresCode: $postgresCode\n'
        '  postgresMessage: $postgresMessage\n'
        '  hint: $hint\n'
        '  field: $field\n'
        '  rawDetails: $rawDetails\n'
        '}';
  }
}

