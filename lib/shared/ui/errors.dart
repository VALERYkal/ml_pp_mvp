// 📌 Module : Shared UI - Errors
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Utilitaires pour la gestion d'erreurs humanisées

import 'package:supabase_flutter/supabase_flutter.dart';

/// Transforme les erreurs techniques en messages user-friendly
/// 
/// [e] : L'erreur à humaniser
/// 
/// Retourne un message d'erreur compréhensible par l'utilisateur
/// 
/// Exemple d'utilisation :
/// ```dart
/// try {
///   await service.updateStatut(id, newStatut);
/// } catch (e) {
///   final message = humanizePostgrest(e);
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(message)),
///   );
/// }
/// ```
String humanizePostgrest(Object e) {
  if (e is! PostgrestException) return 'Erreur inattendue. Réessayez.';
  
  final m = e.message.toLowerCase();
  
  // Erreurs de permissions
  if (m.contains('permission') || m.contains('row level security')) {
    return 'Action non autorisée pour votre rôle.';
  }
  
  // Erreurs de contraintes de clés étrangères
  if (m.contains('foreign key') || m.contains('violates foreign key')) {
    return 'Références invalides (vérifiez fournisseur/produit).';
  }
  
  // Erreurs de champs requis
  if (m.contains('not null') || m.contains('null value')) {
    return 'Un champ requis est manquant.';
  }
  
  // Erreurs de contraintes uniques
  if (m.contains('unique') || m.contains('duplicate key')) {
    return 'Cette valeur existe déjà.';
  }
  
  // Erreurs de validation
  if (m.contains('check') || m.contains('constraint')) {
    return 'Données invalides. Vérifiez les valeurs saisies.';
  }
  
  // Erreurs de connexion
  if (m.contains('connection') || m.contains('network')) {
    return 'Problème de connexion. Vérifiez votre réseau.';
  }
  
  // Erreurs de timeout
  if (m.contains('timeout')) {
    return 'Délai d\'attente dépassé. Réessayez.';
  }
  
  // Erreur par défaut
  return 'Erreur de mise à jour. Réessayez.';
}
