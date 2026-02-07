import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/fournisseur_providers.dart';

/// Format created_at lisible (dd/MM/yyyy HH:mm). Fallback si intl indisponible.
String? _formatCreatedAt(DateTime? d) {
  if (d == null) return null;
  try {
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  } catch (_) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

/// Écran détail fournisseur (Sprint 1 — lecture seule).
/// Sections: Informations, Adresse, Notes, Métadonnées + placeholders ERP.
class FournisseurDetailScreen extends ConsumerWidget {
  const FournisseurDetailScreen({super.key, required this.fournisseurId});

  final String fournisseurId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(fournisseurDetailProvider(fournisseurId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: asyncDetail.when(
          data: (f) => Text(f?.nom ?? 'Fournisseur'),
          loading: () => const Text('Fournisseur'),
          error: (_, __) => const Text('Fournisseur'),
        ),
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(context, ref, err),
        data: (f) {
          if (f == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fournisseur introuvable',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActifBadge(context),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Informations',
                  [
                    _row(context, 'Nom', f.nom),
                    _row(context, 'Pays', f.pays),
                    _row(context, 'Contact', f.contactPersonne),
                    _row(context, 'Email', f.email),
                    _row(context, 'Téléphone', f.telephone),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Adresse',
                  [_row(context, 'Adresse', f.adresse)],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Notes',
                  [_row(context, 'Note supplémentaire', f.noteSupplementaire)],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Métadonnées',
                  [
                    _row(context, 'ID', f.id),
                    _row(
                      context,
                      'Créé le',
                      _formatCreatedAt(f.createdAt),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPlaceholderCard(
                  context,
                  'SBLC — Sprint 2',
                  'Non implémenté (Sprint 2)',
                ),
                const SizedBox(height: 12),
                _buildPlaceholderCard(
                  context,
                  'Proformas — Sprint 2/3',
                  'Non implémenté (Sprint 2/3)',
                ),
                const SizedBox(height: 12),
                _buildPlaceholderCard(
                  context,
                  'Factures finales — Sprint 3/4',
                  'Non implémenté (Sprint 3/4)',
                ),
                const SizedBox(height: 12),
                _buildPlaceholderCard(
                  context,
                  'Relevé fournisseur — Sprint 4',
                  'Non implémenté (Sprint 4)',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActifBadge(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'ACTIF',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> rows,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label :',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(
    BuildContext context,
    String title,
    String body,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object err) {
    return Center(
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
              err.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(fournisseurDetailProvider(fournisseurId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
