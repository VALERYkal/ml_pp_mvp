/// Exception métier pour les erreurs de validation de sortie
/// 
/// Utilisée pour signaler des erreurs de validation spécifiques au module Sorties,
/// distinctes des erreurs techniques (PostgrestException, etc.)
class SortieValidationException implements Exception {
  final String message;
  final String? field;
  
  const SortieValidationException(this.message, {this.field});
  
  @override
  String toString() => field != null 
      ? 'SortieValidationException ($field): $message'
      : 'SortieValidationException: $message';
}

