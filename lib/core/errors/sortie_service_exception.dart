/// Exception pour les erreurs SQL/DB lors de la création de sorties
/// 
/// Utilisée pour signaler des erreurs provenant de la base de données (trigger SQL, contraintes, etc.),
/// distincte de `SortieValidationException` qui est pour les validations métier côté Flutter.
class SortieServiceException implements Exception {
  final String message;
  final String? code; // Code erreur SQL (ex: "23505" pour unique violation)
  final String? hint; // Hint de PostgrestException
  
  SortieServiceException(this.message, {this.code, this.hint});
  
  @override
  String toString() => 'SortieServiceException: $message';
}

