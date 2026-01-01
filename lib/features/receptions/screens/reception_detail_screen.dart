import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/receptions/providers/receptions_table_provider.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception_row_vm.dart';
import 'package:ml_pp_mvp/shared/utils/date_formatter.dart';
import 'package:ml_pp_mvp/shared/utils/volume_formatter.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/screens/stocks_adjustment_create_sheet.dart';
import 'package:ml_pp_mvp/shared/refresh/refresh_helpers.dart';

class ReceptionDetailScreen extends ConsumerWidget {
  final String receptionId;

  const ReceptionDetailScreen({super.key, required this.receptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(receptionsTableProvider);
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la réception'),
        actions: [
          // Bouton "Corriger (Ajustement)" visible uniquement pour admin
          if (userRole == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Corriger (Ajustement)',
              onPressed: () => _showAdjustmentSheet(context, ref),
            ),
        ],
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(receptionsTableProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (rows) {
          // Trouver la ligne correspondant à receptionId
          ReceptionRowVM? row;
          try {
            row = rows.firstWhere((r) => r.id == receptionId);
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
                      'Réception introuvable',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La réception demandée n\'existe pas ou a été supprimée.',
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
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête avec badge propriétaire
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Détail de la réception',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildProprietaireBadge(context, row.propriete),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormatter.formatDate(row.dateReception),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Informations principales
                    _buildSectionTitle(context, 'Informations principales'),
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
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      label: 'Source',
                      value: row.sourceLabel,
                      icon: Icons.source,
                    ),
                    if (row.cdrShort != null || row.cdrPlaques != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        label: 'Cours de route',
                        value: row.cdrShort ?? '—',
                        icon: Icons.local_shipping,
                        valueWidget: row.cdrPlaques != null
                            ? _buildCdrChip(
                                context,
                                row.cdrShort ?? '',
                                row.cdrPlaques!,
                              )
                            : null,
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Section Volumes
                    _buildSectionTitle(context, 'Volumes'),
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
    Widget? valueWidget,
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
              valueWidget ??
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildProprietaireBadge(BuildContext context, String propriete) {
    final isMonaluxe = propriete == 'MONALUXE';
    final color = isMonaluxe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMonaluxe ? Icons.person : Icons.business,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            propriete,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCdrChip(BuildContext context, String cdrShort, String plaques) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$cdrShort - $plaques',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le BottomSheet pour créer un ajustement
  void _showAdjustmentSheet(BuildContext context, WidgetRef ref) {
    StocksAdjustmentCreateSheet.show(
      context,
      mouvementType: 'RECEPTION',
      mouvementId: receptionId,
      onSuccess: () {
        // Invalider les providers de stock après création de l'ajustement
        invalidateDashboardKpisAfterStockMovement(ref);
      },
    );
  }
}
