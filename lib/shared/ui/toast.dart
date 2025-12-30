// 📌 Module : Shared UI - Toast
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Utilitaires pour les toasts uniformes

import 'package:flutter/material.dart';

/// Types de toast disponibles
enum ToastType { success, error, info, warning }

/// Affiche un toast uniforme avec anti-chevauchement
///
/// [context] : Contexte Flutter
/// [message] : Message à afficher
/// [type] : Type de toast (success, error, info, warning)
/// [duration] : Durée d'affichage (défaut: 3 secondes)
///
/// Exemple d'utilisation :
/// ```dart
/// showAppToast(context, 'Opération réussie', type: ToastType.success);
/// showAppToast(context, 'Erreur de connexion', type: ToastType.error);
/// ```
void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  // Nettoyer les toasts existants pour éviter les chevauchements
  ScaffoldMessenger.of(context).clearSnackBars();

  // Déterminer la couleur selon le type
  final backgroundColor = _getColorForType(type);
  final icon = _getIconForType(type);

  // Afficher le nouveau toast
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

/// Retourne la couleur appropriée selon le type de toast
Color _getColorForType(ToastType type) {
  switch (type) {
    case ToastType.success:
      return Colors.green;
    case ToastType.error:
      return Colors.red;
    case ToastType.warning:
      return Colors.orange;
    case ToastType.info:
      return Colors.blue;
  }
}

/// Retourne l'icône appropriée selon le type de toast
IconData? _getIconForType(ToastType type) {
  switch (type) {
    case ToastType.success:
      return Icons.check_circle;
    case ToastType.error:
      return Icons.error;
    case ToastType.warning:
      return Icons.warning;
    case ToastType.info:
      return Icons.info;
  }
}
