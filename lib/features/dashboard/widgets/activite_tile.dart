import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/dashboard/models/activite_recente.dart';

/// Widget pour afficher une activité récente
class ActiviteTile extends StatelessWidget {
  final ActiviteRecente activite;
  final VoidCallback? onTap;

  const ActiviteTile({super.key, required this.activite, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Déterminer l'icône et la couleur selon le niveau
    IconData icon;
    Color color;

    switch (activite.niveau.toUpperCase()) {
      case 'CRITICAL':
        icon = Icons.error;
        color = theme.colorScheme.error;
        break;
      case 'WARNING':
        icon = Icons.warning_amber;
        color = theme.colorScheme.tertiary;
        break;
      default:
        icon = Icons.info;
        color = theme.colorScheme.primary;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        '${activite.module}  ${activite.action}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activite.createdAtFmt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (activite.userName != null)
            Text(
              'Par ${activite.userName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Widget pour afficher une liste d'activités récentes
class ActivitesList extends StatelessWidget {
  final List<ActiviteRecente> activites;
  final void Function(ActiviteRecente)? onActiviteTap;
  final VoidCallback? onVoirPlus;

  const ActivitesList({
    super.key,
    required this.activites,
    this.onActiviteTap,
    this.onVoirPlus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Activités récentes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onVoirPlus != null)
                  TextButton(
                    onPressed: onVoirPlus,
                    child: const Text('Voir plus'),
                  ),
              ],
            ),
          ),
          if (activites.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucune activité récente',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activites.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activite = activites[index];
                return ActiviteTile(
                  activite: activite,
                  onTap: onActiviteTap != null
                      ? () => onActiviteTap!(activite)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

