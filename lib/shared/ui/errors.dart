// 📌 Module : Shared UI - Errors
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Utilitaires pour la gestion d'erreurs humanisées

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/shared/utils/error_humanizer.dart';

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
  return ErrorHumanizer.humanizeError(e);
}
