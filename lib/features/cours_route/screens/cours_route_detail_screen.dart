// 📌 Module : Cours de Route - Screens
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🧭 Description : Écran de détail d'un cours de route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart' show refDataProvider, resolveName;
import 'package:ml_pp_mvp/shared/ui/format.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/ui/dialogs.dart';
import 'package:ml_pp_mvp/shared/ui/errors.dart';

/// Écran de détail d'un cours de route
/// 
/// Affiche toutes les informations d'un cours de route sélectionné.
/// Met l'accent sur la lisibilité et l'action (opérateur d'abord).
class CoursRouteDetailScreen extends ConsumerWidget {
  final String coursId;
  
  const CoursRouteDetailScreen({
    super.key,
    required this.coursId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursAsync = ref.watch(coursDeRouteByIdProvider(coursId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du cours'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Modifier')]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))]),
              ),
            ],
          ),
        ],
      ),
      body: coursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref, error),
        data: (cours) => cours == null
            ? _buildNotFound(context)
            : _buildDetail(context, cours, ref),
      ),
    );
  }
  
  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur lors du chargement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error.toString(), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(coursDeRouteByIdProvider(coursId)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Cours non trouvé', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Le cours de route demandé n\'existe pas ou a été supprimé.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.pop(), child: const Text('Retour à la liste')),
        ],
      ),
    );
  }
  
  /// Contenu principal
  Widget _buildDetail(BuildContext context, CoursDeRoute c, WidgetRef ref) {
    final refDataAsync = ref.watch(refDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header résumé + statut
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cours #${c.id.substring(0, 8)}', style: Theme.of(context).textTheme.headlineSmall),
                      _StatutChip(statut: c.statut),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(icon: Icons.local_gas_station, label: fmtVolume(c.volume)),
                      _InfoPill(icon: Icons.event, label: fmtDate(c.dateChargement)),
                      _InfoPill(icon: Icons.badge, label: c.plaqueCamion ?? '—'),
                      if ((c.plaqueRemorque ?? '').isNotEmpty)
                        _InfoPill(icon: Icons.badge_outlined, label: c.plaqueRemorque!),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Timeline statut
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StatutTimeline(current: c.statut),
          ),

          // Cartes infos (2 cartes)
          refDataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Erreur référentiels: $e'),
            ),
            data: (refData) {
              final four = resolveName(refData, c.fournisseurId, 'fournisseur');
              final prod = resolveName(refData, c.produitId, 'produit');
              final dep = refData.depots[c.depotDestinationId] ?? '—';
              return Column(
                children: [
                  // Logistique
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _InfoGrid(entries: [
                        ('Fournisseur', four),
                        ('Produit', prod),
                        ('Dépôt destination', dep),
                      ]),
                    ),
                  ),
                  // Transport
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _InfoGrid(entries: [
                        ('Transporteur', c.transporteur ?? '—'),
                        ('Chauffeur', c.chauffeur ?? '—'),
                        ('Plaque camion', c.plaqueCamion ?? '—'),
                        ('Plaque remorque', (c.plaqueRemorque ?? '—')),
                        ('Pays', c.pays ?? '—'),
                        ('Date de chargement', fmtDate(c.dateChargement)),
                        ('Volume', fmtVolume(c.volume)),
                      ]),
                    ),
                  ),

                  // Actions secondaires (Modifier / Supprimer)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/cours/${c.id}/edit'),
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifier'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context, ref, c.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Supprimer'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Note si présente
          if ((c.note ?? '').trim().isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: const Text('Note'),
                subtitle: Text(c.note!.trim()),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        context.push('/cours/$coursId/edit');
        break;
      case 'delete':
        _confirmDelete(context, ref, coursId);
        break;
    }
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ]),
    );
  }
}

class _StatutChip extends StatelessWidget {
  final StatutCours statut;
  const _StatutChip({required this.statut});
  @override
  Widget build(BuildContext context) {
    final Color color = switch (statut) {
      StatutCours.chargement => Colors.blue,
      StatutCours.transit => Colors.indigo,
      StatutCours.frontiere => Colors.amber,
      StatutCours.arrive => Colors.teal,
      StatutCours.decharge => Colors.grey,
    };
    return Chip(
      avatar: const Icon(Icons.local_shipping, size: 16, color: Colors.white),
      label: Text(statut.label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}

class _StatutTimeline extends StatelessWidget {
  final StatutCours current;
  const _StatutTimeline({required this.current});
  @override
  Widget build(BuildContext context) {
    final steps = const [
      StatutCours.chargement,
      StatutCours.transit,
      StatutCours.frontiere,
      StatutCours.arrive,
      StatutCours.decharge,
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: steps.map((s) {
        final done = steps.indexOf(s) <= steps.indexOf(current);
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: done ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: 6),
          Text(s.label),
          if (s != steps.last)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, size: 18),
            ),
        ]);
      }).toList(),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String)> entries;
  const _InfoGrid({required this.entries});
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final cols = isWide ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisExtent: 52,
        crossAxisSpacing: 16,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final (label, value) = entries[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(value.isEmpty ? '—' : value),
          ],
        );
      },
    );
  }
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
  final ok = await confirmAction(
    context,
    title: 'Supprimer le cours ?',
    message: 'Cette action est irréversible.',
    confirmLabel: 'Supprimer',
    danger: true,
  );
  if (!ok) return;
  try {
    await ref.read(coursDeRouteServiceProvider).delete(id);
    if (context.mounted) {
      showAppToast(context, 'Cours supprimé', type: ToastType.success);
      context.go('/cours');
    }
  } catch (e) {
    if (context.mounted) {
      showAppToast(context, humanizePostgrest(e), type: ToastType.error);
    }
  }
}
