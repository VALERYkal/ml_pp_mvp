// 📌 Module : Lots — Message utilisateur à partir d’une erreur backend (liaison CDR ↔ lot).
// 🧭 Présentation uniquement ; la base reste la source de vérité.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Message affiché lorsqu’aucune correspondance métier lot n’est trouvée.
const String kLotModuleGenericUserError =
    'Une erreur est survenue. Veuillez réessayer.';

/// Normalise le texte pour des comparaisons robustes (casse, apostrophes).
String normalizeLotBackendErrorText(String input) {
  return input
      .toLowerCase()
      .replaceAll('\u2019', "'")
      .replaceAll('’', "'");
}

/// Extrait une chaîne exploitable depuis une exception (PostgREST ou autre).
@visibleForTesting
String extractLotBackendErrorText(Object error) {
  if (error is PostgrestException) {
    final parts = <String>[];
    if (error.message.isNotEmpty) parts.add(error.message);
    final d = error.details;
    if (d != null && d.toString().trim().isNotEmpty) {
      parts.add(d.toString());
    }
    return parts.join(' ');
  }
  final s = error.toString();
  if (s.startsWith('Exception: ')) {
    return s.substring('Exception: '.length);
  }
  return s;
}

/// Mappe les erreurs SQL / PostgREST liées au durcissement lot ↔ CDR vers un libellé UI.
///
/// En debug, les erreurs non mappées sont journalisées avec le texte brut.
String mapLotUserMessage(Object error) {
  final raw = extractLotBackendErrorText(error);
  final n = normalizeLotBackendErrorText(raw);

  if (n.contains(
        'impossible de rattacher : le fournisseur du cdr ne correspond pas',
      )) {
    return 'Ce camion ne peut pas être ajouté à ce lot car le fournisseur ne correspond pas.';
  }

  if (n.contains(
        'impossible de rattacher : le produit du cdr ne correspond pas',
      )) {
    return 'Ce camion ne peut pas être ajouté à ce lot car le produit ne correspond pas.';
  }

  if (n.contains(
        'impossible de modifier le rattachement au lot pour un cdr au statut decharge',
      )) {
    return 'Ce cours de route est déjà déchargé et ne peut plus être modifié.';
  }

  const lotNotOpenFragments = [
    'impossible de rattacher un cdr à un lot qui n\'est pas ouvert',
    'impossible de détacher un cdr d\'un lot qui n\'est pas ouvert',
    'impossible de retirer un cdr d\'un lot qui n\'est pas ouvert',
  ];
  for (final frag in lotNotOpenFragments) {
    if (n.contains(frag)) {
      return "Ce lot n'est plus modifiable.";
    }
  }

  if (n.contains('n\'est pas ouvert') &&
      (n.contains('rattacher') ||
          n.contains('détacher') ||
          n.contains('detacher') ||
          n.contains('retirer'))) {
    return "Ce lot n'est plus modifiable.";
  }

  if (kDebugMode && raw.trim().isNotEmpty) {
    debugPrint('[mapLotUserMessage] non mappé: $raw');
  }
  return kLotModuleGenericUserError;
}
