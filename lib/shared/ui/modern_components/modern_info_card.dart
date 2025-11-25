import 'package:flutter/material.dart';

/// Carte d'information moderne
class ModernInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<InfoEntry> entries;
  final IconData? icon;
  final Color? accentColor;
  final Widget? trailing;

  const ModernInfoCard({
    super.key,
    required this.title,
    required this.entries,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.trailing,
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
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                      color: accentColor.withValues(alpha: 0.1),
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
                        style: theme.textTheme.titleLarge?.copyWith(
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
                if (trailing != null) trailing!,
              ],
            ),
          ),

          // Contenu de la carte
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildInfoGrid(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, ThemeData theme) {
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final cols = isWide ? 2 : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: cols == 2 ? 3 : 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (_, index) {
        final entry = entries[index];
        return _InfoEntryWidget(entry: entry);
      },
    );
  }
}

/// Widget pour afficher une entrée d'information
class _InfoEntryWidget extends StatelessWidget {
  final InfoEntry entry;

  const _InfoEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            entry.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SelectableText(
              entry.value.isEmpty ? '' : entry.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe pour représenter une entrée d'information
class InfoEntry {
  final String label;
  final String value;

  const InfoEntry({required this.label, required this.value});
}

