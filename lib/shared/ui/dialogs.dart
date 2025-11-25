import 'package:flutter_riverpod/flutter_riverpod.dart';
// ?? Module : Shared UI - Dialogs
// ?? Auteur : Valery Kalonga
// ?? Date : 2025-01-27
// ?? Description : Utilitaires pour les dialogs de confirmation

import 'package:flutter/material.dart';

/// Affiche un dialog de confirmation flexible
///
/// [context] : Contexte Flutter
/// [title] : Titre du dialog
/// [message] : Message de confirmation
/// [confirmLabel] : Texte du bouton de confirmation (défaut: 'Confirmer')
/// [cancelLabel] : Texte du bouton d'annulation (défaut: 'Annuler')
/// [danger] : Si true, utilise des couleurs d'alerte (défaut: false)
///
/// Retourne :
/// - `true` : L'utilisateur a confirmé
/// - `false` : L'utilisateur a annulé
///
/// Exemple d'utilisation :
/// ```dart
/// final confirmed = await confirmAction(
///   context,
///   title: 'Supprimer le cours ?',
///   message: 'Cette action est irréversible.',
///   confirmLabel: 'Supprimer',
///   danger: true,
/// );
/// ```
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              danger ? Icons.warning : Icons.help_outline,
              color: danger ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? Colors.red : null,
              foregroundColor: danger ? Colors.white : null,
            ),
            child: Text(confirmLabel),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    },
  );

  return result ?? false;
}

/// Affiche un dialog d'information simple
///
/// [context] : Contexte Flutter
/// [title] : Titre du dialog
/// [message] : Message d'information
/// [buttonLabel] : Texte du bouton (défaut: 'OK')
///
/// Exemple d'utilisation :
/// ```dart
/// await showInfoDialog(
///   context,
///   title: 'Information',
///   message: 'Opération terminée avec succès.',
/// );
/// ```
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'OK',
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonLabel),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    },
  );
}

/// Affiche un dialog d'erreur avec bouton de retry
///
/// [context] : Contexte Flutter
/// [title] : Titre du dialog
/// [message] : Message d'erreur
/// [onRetry] : Fonction à exécuter lors du retry
/// [retryLabel] : Texte du bouton retry (défaut: 'Réessayer')
///
/// Exemple d'utilisation :
/// ```dart
/// await showErrorDialog(
///   context,
///   title: 'Erreur de connexion',
///   message: 'Impossible de se connecter au serveur.',
///   onRetry: () => ref.invalidate(provider),
/// );
/// ```
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onRetry,
  String retryLabel = 'Réessayer',
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(retryLabel),
            ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    },
  );
}

