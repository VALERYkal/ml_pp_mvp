// ?? Module : Cours de Route - Utils
// ?? Auteur : Valery Kalonga
// ?? Date : 2025-09-15
// ?? Description : Actions contextuelles intelligentes pour les cours de route

import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Élément d'action contextuelle
class ContextualAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDanger;
  final Color? color;

  const ContextualAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
    this.color,
  });
}

/// Générateur d'actions contextuelles intelligentes
class ContextualActionsGenerator {
  /// Génère les actions contextuelles selon le statut du cours
  static List<ContextualAction> getActionsForCours(
    CoursDeRoute cours,
    BuildContext context, {
    VoidCallback? onView,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onAdvanceStatus,
    VoidCallback? onCreateReception,
    VoidCallback? onDuplicate,
  }) {
    final actions = <ContextualAction>[];

    // Action "Voir" toujours disponible
    if (onView != null) {
      actions.add(
        ContextualAction(
          label: 'Voir',
          icon: Icons.visibility_outlined,
          onPressed: onView,
        ),
      );
    }

    // Actions selon le statut
    switch (cours.statut) {
      case StatutCours.inconnu:
      case StatutCours.chargement:
        // Cours en chargement
        if (onEdit != null) {
          actions.add(
            ContextualAction(
              label: 'Modifier',
              icon: Icons.edit,
              onPressed: onEdit,
            ),
          );
        }
        if (onAdvanceStatus != null) {
          actions.add(
            ContextualAction(
              label: 'Marquer en transit',
              icon: Icons.local_shipping,
              onPressed: onAdvanceStatus,
              isPrimary: true,
              color: Colors.blue,
            ),
          );
        }
        if (onDelete != null) {
          actions.add(
            ContextualAction(
              label: 'Supprimer',
              icon: Icons.delete,
              onPressed: onDelete,
              isDanger: true,
            ),
          );
        }
        break;

      case StatutCours.transit:
        // Cours en transit
        if (onAdvanceStatus != null) {
          actions.add(
            ContextualAction(
              label: 'Arrivé à la frontière',
              icon: Icons.flag,
              onPressed: onAdvanceStatus,
              isPrimary: true,
              color: Colors.orange,
            ),
          );
        }
        if (onEdit != null) {
          actions.add(
            ContextualAction(
              label: 'Modifier',
              icon: Icons.edit,
              onPressed: onEdit,
            ),
          );
        }
        break;

      case StatutCours.frontiere:
        // Cours à la frontière
        if (onAdvanceStatus != null) {
          actions.add(
            ContextualAction(
              label: 'Marquer arrivé',
              icon: Icons.location_on,
              onPressed: onAdvanceStatus,
              isPrimary: true,
              color: Colors.teal,
            ),
          );
        }
        if (onEdit != null) {
          actions.add(
            ContextualAction(
              label: 'Modifier',
              icon: Icons.edit,
              onPressed: onEdit,
            ),
          );
        }
        break;

      case StatutCours.arrive:
        // Cours arrivé - Action prioritaire : créer réception
        if (onCreateReception != null) {
          actions.add(
            ContextualAction(
              label: 'Créer réception',
              icon: Icons.add_box,
              onPressed: onCreateReception,
              isPrimary: true,
              color: Colors.green,
            ),
          );
        }
        if (onEdit != null) {
          actions.add(
            ContextualAction(
              label: 'Modifier',
              icon: Icons.edit,
              onPressed: onEdit,
            ),
          );
        }
        break;

      case StatutCours.decharge:
        // Cours déchargé - Actions limitées
        if (onDuplicate != null) {
          actions.add(
            ContextualAction(
              label: 'Dupliquer',
              icon: Icons.copy,
              onPressed: onDuplicate,
              color: Colors.blue,
            ),
          );
        }
        // Seuls les admins peuvent modifier/supprimer les cours déchargés
        // Cette logique sera gérée dans l'interface utilisateur
        break;
    }

    // Action "Dupliquer" toujours disponible (sauf pour les cours déchargés où elle est déjà ajoutée)
    if (cours.statut != StatutCours.decharge && onDuplicate != null) {
      actions.add(
        ContextualAction(
          label: 'Dupliquer',
          icon: Icons.copy,
          onPressed: onDuplicate,
        ),
      );
    }

    return actions;
  }

  /// Génère les actions rapides pour la liste
  static List<ContextualAction> getQuickActionsForCours(
    CoursDeRoute cours,
    BuildContext context, {
    VoidCallback? onView,
    VoidCallback? onAdvanceStatus,
    VoidCallback? onCreateReception,
  }) {
    final actions = <ContextualAction>[];

    // Action "Voir" toujours en premier
    if (onView != null) {
      actions.add(
        ContextualAction(
          label: 'Voir',
          icon: Icons.visibility_outlined,
          onPressed: onView,
        ),
      );
    }

    // Action principale selon le statut
    switch (cours.statut) {
      case StatutCours.inconnu:
      case StatutCours.chargement:
      case StatutCours.transit:
      case StatutCours.frontiere:
        if (onAdvanceStatus != null) {
          actions.add(
            ContextualAction(
              label: _getNextStatusLabel(cours.statut),
              icon: _getNextStatusIcon(cours.statut),
              onPressed: onAdvanceStatus,
              isPrimary: true,
              color: _getNextStatusColor(cours.statut),
            ),
          );
        }
        break;

      case StatutCours.arrive:
        if (onCreateReception != null) {
          actions.add(
            ContextualAction(
              label: 'Créer réception',
              icon: Icons.add_box,
              onPressed: onCreateReception,
              isPrimary: true,
              color: Colors.green,
            ),
          );
        }
        break;

      case StatutCours.decharge:
        // Pas d'action rapide pour les cours déchargés
        break;
    }

    return actions;
  }

  /// Obtient le libellé du prochain statut
  static String _getNextStatusLabel(StatutCours statut) {
    switch (statut) {
      case StatutCours.inconnu:
        return 'Marquer en transit';
      case StatutCours.chargement:
        return 'En transit';
      case StatutCours.transit:
        return 'À la frontière';
      case StatutCours.frontiere:
        return 'Arrivé';
      case StatutCours.arrive:
        return 'Créer réception';
      case StatutCours.decharge:
        return '';
    }
  }

  /// Obtient l'icône du prochain statut
  static IconData _getNextStatusIcon(StatutCours statut) {
    switch (statut) {
      case StatutCours.inconnu:
        return Icons.local_shipping;
      case StatutCours.chargement:
        return Icons.local_shipping;
      case StatutCours.transit:
        return Icons.flag;
      case StatutCours.frontiere:
        return Icons.location_on;
      case StatutCours.arrive:
        return Icons.add_box;
      case StatutCours.decharge:
        return Icons.check;
    }
  }

  /// Obtient la couleur du prochain statut
  static Color _getNextStatusColor(StatutCours statut) {
    switch (statut) {
      case StatutCours.inconnu:
        return Colors.blue;
      case StatutCours.chargement:
        return Colors.blue;
      case StatutCours.transit:
        return Colors.orange;
      case StatutCours.frontiere:
        return Colors.teal;
      case StatutCours.arrive:
        return Colors.green;
      case StatutCours.decharge:
        return Colors.grey;
    }
  }
}

/// Widget pour afficher les actions contextuelles
class ContextualActionsWidget extends StatelessWidget {
  final List<ContextualAction> actions;
  final bool isCompact;

  const ContextualActionsWidget({
    super.key,
    required this.actions,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .take(2)
            .map((action) => _buildCompactButton(action))
            .toList(),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) => _buildButton(action)).toList(),
    );
  }

  Widget _buildButton(ContextualAction action) {
    if (action.isPrimary) {
      return FilledButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon),
        label: Text(action.label),
        style: FilledButton.styleFrom(backgroundColor: action.color),
      );
    }

    if (action.isDanger) {
      return OutlinedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
      );
    }

    return OutlinedButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(foregroundColor: action.color),
    );
  }

  Widget _buildCompactButton(ContextualAction action) {
    return IconButton.filledTonal(
      onPressed: action.onPressed,
      icon: Icon(action.icon),
      tooltip: action.label,
      style: IconButton.styleFrom(
        foregroundColor: action.color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

