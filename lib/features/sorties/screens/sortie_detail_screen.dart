import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sorties_table_provider.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_row_vm.dart';
import 'package:ml_pp_mvp/shared/utils/date_formatter.dart';
import 'package:ml_pp_mvp/shared/utils/volume_formatter.dart';

class SortieDetailScreen extends ConsumerWidget {
  final String sortieId;

  const SortieDetailScreen({super.key, required this.sortieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(sortiesTableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la sortie'),
      ),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (rows) {
          // Trouver la ligne correspondant à sortieId
          SortieRowVM? row;
          try {
            row = rows.firstWhere((r) => r.id == sortieId);
          } catch (_) {
            row = null;
          }

          // Si aucune ligne trouvée, afficher un message simple
          if (row == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sortie introuvable',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La sortie demandée n\'existe pas ou a été supprimée.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Affichage des détails dans une Card
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Résumé',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      label: 'Date',
                      value: DateFormatter.formatDate(row.dateSortie),
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      label: 'Propriété',
                      value: row.propriete,
                      icon: row.propriete == 'MONALUXE' ? Icons.person : Icons.business,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      label: 'Produit',
                      value: row.produitLabel,
                      icon: Icons.local_gas_station,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      label: 'Citerne',
                      value: row.citerneNom,
                      icon: Icons.storage,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Volumes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      label: 'Volume @15°C',
                      value: VolumeFormatter.formatVolume(row.vol15),
                      icon: Icons.water_drop,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      label: 'Volume ambiant',
                      value: VolumeFormatter.formatVolume(row.volAmb),
                      icon: Icons.water_drop_outlined,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      label: 'Bénéficiaire',
                      value: row.beneficiaireNom ?? 'Bénéficiaire inconnu',
                      icon: row.propriete == 'MONALUXE' ? Icons.person : Icons.business,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      label: 'Statut',
                      value: row.statut,
                      icon: row.statut == 'validee' ? Icons.check_circle : Icons.edit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

