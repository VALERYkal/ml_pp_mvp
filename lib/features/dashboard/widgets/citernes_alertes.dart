import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/dashboard/providers/citernes_sous_seuil_provider.dart';

/// Widget pour afficher une citerne sous seuil
class CiterneAlerteTile extends StatelessWidget {
  final CiterneSousSeuil citerne;
  final VoidCallback? onTap;

  const CiterneAlerteTile({
    super.key,
    required this.citerne,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = citerne.seuil > 0 
        ? (citerne.stock / citerne.seuil).clamp(0.0, 1.0)
        : 0.0;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
        child: Icon(
          Icons.local_gas_station,
          color: theme.colorScheme.error,
          size: 20,
        ),
      ),
      title: Text(
        citerne.nom,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            citerne.nom,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ratio < 0.2 
                        ? theme.colorScheme.error 
                        : theme.colorScheme.tertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: ratio < 0.2 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stock: ${citerne.stock.toStringAsFixed(1)} L / ${citerne.seuil.toStringAsFixed(1)} L',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Widget pour afficher la liste des citernes sous seuil
class CiternesAlertesList extends StatelessWidget {
  final List<CiterneSousSeuil> citernes;
  final void Function(CiterneSousSeuil)? onCiterneTap;
  final VoidCallback? onVoirPlus;

  const CiternesAlertesList({
    super.key,
    required this.citernes,
    this.onCiterneTap,
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
                Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Citernes sous seuil',
                  style: theme.textTheme.titleMedium?.copyWith(
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
          if (citernes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune citerne sous le seuil de sécurité',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Toutes les citernes sont dans les normes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: citernes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final citerne = citernes[index];
                return CiterneAlerteTile(
                  citerne: citerne,
                  onTap: onCiterneTap != null ? () => onCiterneTap!(citerne) : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
