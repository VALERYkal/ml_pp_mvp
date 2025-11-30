/// Exception métier pour les erreurs de validation de réception
/// 
/// Utilisée pour signaler des erreurs de validation spécifiques au module Réceptions,
/// distinctes des erreurs techniques (PostgrestException, etc.)
class ReceptionValidationException implements Exception {
  final String message;
  final String? field;
  
  const ReceptionValidationException(this.message, {this.field});
  
  @override
  String toString() => field != null 
      ? 'ReceptionValidationException ($field): $message'
      : 'ReceptionValidationException: $message';
}

