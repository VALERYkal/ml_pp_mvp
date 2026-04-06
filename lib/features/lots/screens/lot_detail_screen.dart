// 📌 Module : Lots — Détail lot fournisseur (lecture + liaison FK CDR)
// 🧭 Agrégations UI autorisées ; attach/detach = update `fournisseur_lot_id` uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots/models/lot_detail_view.dart';
import 'package:ml_pp_mvp/features/lots/lot_user_message_from_error.dart';
import 'package:ml_pp_mvp/features/lots/providers/fournisseur_lot_providers.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_detail_header.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_info_card.dart';

/// Détail d’un lot fournisseur + liste des CDR liés (navigation `/lots/:id`).
class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  /// Seuls admin et directeur peuvent lier / délier des CDR (UI ; RLS côté DB).
  bool _canWrite(UserRole? role) {
    if (role == null) return false;
    return role == UserRole.admin || role == UserRole.directeur;
  }

  String _chauffeurDisplay(CoursDeRoute c) {
    final n = (c.chauffeurNom ?? c.chauffeur ?? '').trim();
    return n.isEmpty ? '—' : n;
  }

  Future<void> _onCloseLotPressed(
    BuildContext context,
    WidgetRef ref,
    FournisseurLot lot,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer ce lot ?'),
        content: Text(
          'Après clôture, plus aucune liaison ou déliaison de cours ne sera '
          'possible depuis cet écran. Le lot reste consultable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await ref.read(fournisseurLotServiceProvider).closeLot(lot.id);
      invalidateAfterLotClose(ref, lot);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lot clôturé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapLotUserMessage(e))),
        );
      }
    }
  }

  Future<void> _onDetachPressed(
    BuildContext context,
    WidgetRef ref,
    CoursDeRoute c,
    FournisseurLot lot,
  ) async {
    if (c.statut == StatutCours.decharge) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Détachement non disponible'),
          content: const Text(
            'Ce cours est au statut Déchargé. La base peut encore imposer '
            'd’autres règles : ce message est une aide à l’usage uniquement.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Détacher ce cours du lot ?'),
        content: Text(
          'Le camion ${(c.plaqueCamion ?? '—')} sera retiré du lot '
          '${lot.reference}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Détacher'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await ref.read(fournisseurLotServiceProvider).detachCdrFromLot(c.id);
      invalidateAfterLotCdrLinkChange(ref, lot);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours détaché du lot')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapLotUserMessage(e))),
        );
      }
    }
  }

  Future<void> _showAddCdrSheet(
    BuildContext context,
    WidgetRef ref,
    FournisseurLot lot,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(cdrAvailableForLotProvider(lot));
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              builder: (_, scrollCtrl) {
                return async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(mapLotUserMessage(e))),
                  data: (list) {
                    if (list.isEmpty) {
                      return ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(24),
                        children: const [
                          Text(
                            'Aucun cours disponible',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Les cours du même fournisseur et du même produit, '
                            'sans lot, apparaissent ici.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: list.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Text(
                              'Ajouter au lot ${lot.reference}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          );
                        }
                        final c = list[i - 1];
                        return ListTile(
                          leading: const Icon(Icons.local_shipping_outlined),
                          title: Text(c.plaqueCamion ?? '—'),
                          subtitle: Text(
                            '${fmtVolume(c.volume)} · ${c.statut.label}',
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              await ref
                                  .read(fournisseurLotServiceProvider)
                                  .attachCdrToLot(c.id, lot.id);
                              invalidateAfterLotCdrLinkChange(ref, lot);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Cours ${c.plaqueCamion ?? c.id} lié au lot',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(mapLotUserMessage(e)),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCdrTable(
    BuildContext context,
    WidgetRef ref,
    LotDetailView view,
    bool lotEditable,
  ) {
    final lot = view.lot;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = view.cdrs
            .map(
              (c) => DataRow(
                cells: [
                  DataCell(Text(c.plaqueCamion ?? '—')),
                  DataCell(Text(_chauffeurDisplay(c))),
                  DataCell(Text(fmtVolume(c.volume))),
                  DataCell(Text(c.statut.label)),
                  DataCell(Text(fmtDate(c.dateChargement))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/cours/${c.id}'),
                          child: const Text('Voir'),
                        ),
                        if (lotEditable) ...[
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () =>
                                _onDetachPressed(context, ref, c, lot),
                            child: Text(
                              'Détacher',
                              style: TextStyle(
                                color: c.statut == StatutCours.decharge
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Plaque')),
                DataColumn(label: Text('Chauffeur')),
                DataColumn(label: Text('Volume')),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Chargement')),
                DataColumn(label: Text('Actions')),
              ],
              rows: rows,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final canWrite = _canWrite(role);
    final detailAsync = ref.watch(lotDetailProvider(lotId));
    final refDataAsync = ref.watch(refDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lot fournisseur'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(lotDetailProvider(lotId));
            },
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(lotDetailProvider(lotId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (view) {
          if (view == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Lot introuvable'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          return refDataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (refData) {
              final lot = view.lot;
              final lotEditable =
                  canWrite && lot.statut == StatutFournisseurLot.ouvert;
              final fournisseurLabel =
                  resolveName(refData, lot.fournisseurId, 'fournisseur');
              final produitLabel =
                  resolveName(refData, lot.produitId, 'produit');

              final metrics = view.metrics;
              String volDisp(double litres) =>
                  metrics.totalCdr == 0 ? '—' : fmtVolume(litres);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  ModernDetailHeader(
                    title: lot.reference,
                    subtitle: '$fournisseurLabel · $produitLabel',
                    accentColor: Theme.of(context).colorScheme.tertiary,
                    infoPills: [
                      InfoPill(
                        icon: Icons.store_outlined,
                        label: 'Fournisseur',
                        value: fournisseurLabel,
                      ),
                      InfoPill(
                        icon: Icons.local_gas_station_outlined,
                        label: 'Produit',
                        value: produitLabel,
                      ),
                      InfoPill(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date lot',
                        value: fmtDate(lot.dateLot),
                      ),
                      InfoPill(
                        icon: Icons.flag_outlined,
                        label: 'Statut',
                        value: lot.statut.label,
                      ),
                      InfoPill(
                        icon: Icons.note_outlined,
                        label: 'Note',
                        value: (lot.note ?? '').trim().isEmpty
                            ? '—'
                            : lot.note!.trim(),
                      ),
                    ],
                  ),
                  if (canWrite &&
                      lot.statut != StatutFournisseurLot.ouvert) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Lot clôturé : aucune modification n’est disponible.',
                        key: const Key('lot_detail_closed_notice'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                  ModernInfoCard(
                    key: const Key('lot_detail_summary_volume_card'),
                    title: 'Volumes',
                    subtitle: 'Sommes des volumes déclarés sur les CDR liés',
                    icon: Icons.local_gas_station_outlined,
                    accentColor: Theme.of(context).colorScheme.secondary,
                    entries: [
                      InfoEntry(
                        label: 'Total déclaré (lot)',
                        value: volDisp(metrics.volumeTotalDeclared),
                      ),
                      InfoEntry(
                        label: 'Arrivé (ARRIVE + DECHARGE)',
                        value: volDisp(metrics.volumeArrived),
                      ),
                      InfoEntry(
                        label: 'Déchargé',
                        value: volDisp(metrics.volumeDischarged),
                      ),
                      InfoEntry(
                        label: 'Restant non déchargé',
                        value: volDisp(metrics.volumeRemainingNonDischarged),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ModernInfoCard(
                    key: const Key('lot_detail_summary_cdr_card'),
                    title: 'Progression / statuts',
                    subtitle: 'Effectifs par statut CDR (agrégat affichage)',
                    icon: Icons.local_shipping_outlined,
                    entries: [
                      InfoEntry(
                        label: 'CDR liés',
                        value: '${metrics.totalCdr}',
                      ),
                      InfoEntry(
                        label: 'CHARGEMENT',
                        value: '${metrics.countChargement}',
                      ),
                      InfoEntry(
                        label: 'TRANSIT',
                        value: '${metrics.countTransit}',
                      ),
                      InfoEntry(
                        label: 'FRONTIERE',
                        value: '${metrics.countFrontiere}',
                      ),
                      InfoEntry(
                        label: 'ARRIVE',
                        value: '${metrics.countArrive}',
                      ),
                      InfoEntry(
                        label: 'DECHARGE',
                        value: '${metrics.countDecharge}',
                      ),
                    ],
                  ),
                  if (metrics.totalCdr > 0 &&
                      metrics.volumeTotalDeclared > 0) ...[
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Progression déchargement (volume déchargé / total déclaré)',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                key: const Key(
                                  'lot_detail_discharge_progress',
                                ),
                                minHeight: 10,
                                value: metrics.dischargedFraction,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(100 * metrics.dischargedFraction).toStringAsFixed(0)} %',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Text(
                    'Cours de route liés',
                    key: const Key('lot_detail_cdr_section_title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (view.cdrs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucun cours lié pour l’instant.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  else
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child:
                            _buildCdrTable(context, ref, view, lotEditable),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (lotEditable) ...[
                    OutlinedButton.icon(
                      key: const Key('lot_detail_close_lot_button'),
                      onPressed: () =>
                          _onCloseLotPressed(context, ref, lot),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Clôturer le lot'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _showAddCdrSheet(context, ref, lot),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter CDR au lot'),
                    ),
                  ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
