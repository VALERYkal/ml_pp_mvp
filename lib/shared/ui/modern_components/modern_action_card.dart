import 'package:flutter/material.dart';

/// Carte d'action moderne
class ModernActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ModernActionButton> actions;
  final IconData? icon;
  final Color? accentColor;

  const ModernActionCard({
    super.key,
    required this.title,
    required this.actions,
    this.subtitle,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = this.accentColor ?? theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la carte
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon!, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildActions(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    if (actions.length == 1) {
      return SizedBox(
        width: double.infinity,
        child: _buildActionButton(context, theme, actions.first),
      );
    } else if (actions.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildActionButton(context, theme, actions[0])),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton(context, theme, actions[1])),
        ],
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) => _buildActionButton(context, theme, action)).toList(),
      );
    }
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme, ModernActionButton action) {
    if (action.isDanger) {
      return OutlinedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: action.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

/// Classe pour représenter un bouton d'action
class ModernActionButton {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDanger;
  final Color? accentColor;

  const ModernActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isDanger = false,
    this.accentColor,
  });
}
