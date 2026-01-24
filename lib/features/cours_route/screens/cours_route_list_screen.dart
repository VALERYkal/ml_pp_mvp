// 📌 Module : Cours de Route - Screens
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Écran de liste des cours de route (v2.2)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/ui/errors.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/features/cours_route/utils/keyboard_shortcuts.dart';
import 'package:ml_pp_mvp/features/cours_route/utils/contextual_actions.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_sort_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_pagination_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_cache_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/widgets/pagination_controls.dart';
import 'package:ml_pp_mvp/features/cours_route/widgets/infinite_scroll_list.dart';
import 'package:ml_pp_mvp/features/cours_route/widgets/performance_indicator.dart';
import 'package:ml_pp_mvp/features/cours_route/services/export_service.dart';
import 'package:ml_pp_mvp/features/cours_route/widgets/statistics_widgets.dart';
import 'package:ml_pp_mvp/features/cours_route/widgets/notifications_panel.dart';

/// Fonction utilitaire pour afficher le libellé du produit
///
/// Priorité : produitCode > produitNom > référentiels > fallback
String produitLabel(
  CoursDeRoute c,
  Map<String, String> produits,
  Map<String, String> produitCodes,
) {
  final code = (c.produitCode ?? '').trim();
  final nom = (c.produitNom ?? '').trim();
  if (code.isNotEmpty) return code;
  if (nom.isNotEmpty) return nom;

  // fallback référentiels si disponibles
  final byName = nameOf(produits, c.produitId);
  if (byName != '—') return byName;
  final byCode = nameOf(produitCodes, c.produitId);
  if (byCode != '—') return byCode;

  return '—';
}

/// Écran de liste des cours de route (v2.2)
///
/// Affiche la liste de tous les cours de route avec :
/// - Gestion des états asynchrones (loading, error, empty)
/// - Filtrage réactif par statut, produit et recherche
/// - Affichage responsive (DataTable desktop / Cards mobile)
/// - Actions selon les rôles (voir, avancer statut)
/// - Navigation vers création et détail
///
/// Architecture :
/// - Utilise AsyncValue.when() pour gérer les états
/// - Providers dérivés pour le filtrage réactif
/// - Structure modulaire avec widgets séparés
class CoursRouteListScreen extends ConsumerWidget {
  const CoursRouteListScreen({super.key});

  /// Affiche les statistiques des cours de route dans un dialog
  void _showStatistics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des Cours de Route'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: const CoursStatisticsWidget(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération des données asynchrones
    final coursAsync = ref.watch(coursDeRouteListProvider);
    final refDataAsync = ref.watch(refDataProvider);

    // Activer la mise à jour du cache
    ref.watch(coursCacheUpdaterProvider);

    // Détection du rôle PCA/Gérant pour mode read-only
    final role = ref.watch(userRoleProvider);
    final isPca = (role ?? UserRole.lecture) == UserRole.pca;
    final isGerant = (role ?? UserRole.lecture) == UserRole.gerant;
    final canWrite = !isPca && !isGerant;

    return CoursRouteKeyboardShortcuts(
      onNew: canWrite ? () => context.go('/cours/new') : null,
      onRefresh: () {
        ref.invalidate(coursDeRouteListProvider);
        ref.invalidate(refDataProvider);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cours de Route'),
          centerTitle: false,
          actions: [
            const NotificationButton(),
            Consumer(
              builder: (context, ref, child) {
                final cours = ref.watch(cachedFilteredCoursProvider);
                final refData = ref.watch(refDataProvider);
                return refData.when(
                  data: (data) => CoursExportWidget(
                    cours: cours,
                    fournisseurs: data.fournisseurs,
                    produits: data.produits,
                    produitCodes: data.produitCodes,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            IconButton(
              onPressed: () => _showStatistics(context),
              icon: const Icon(Icons.analytics),
              tooltip: 'Statistiques',
            ),
            const KeyboardShortcutsHelpButton(),
            if (canWrite)
              IconButton(
                tooltip: 'Nouveau cours (Ctrl+N)',
                onPressed: () => context.go('/cours/new'),
                icon: const Icon(Icons.add),
              ),
          ],
        ),
        body: coursAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState('Erreur chargement: $e'),
          data: (cours) {
            if (cours.isEmpty) {
              return canWrite
                  ? _EmptyState(onCreate: () => context.go('/cours/new'))
                  : const _EmptyStateReadOnly();
            }

            return refDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState('Erreur référentiels: $e'),
              data: (refData) => _ListContent(
                fournisseurs: refData.fournisseurs,
                produits: refData.produits,
                produitCodes: refData.produitCodes,
                depots: refData.depots,
              ),
            );
          },
        ),
        floatingActionButton: canWrite
            ? FloatingActionButton(
                onPressed: () => context.go('/cours/new'),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

/// Contenu principal de la liste
class _ListContent extends ConsumerWidget {
  const _ListContent({
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
    required this.depots,
  });

  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;
  final Map<String, String> depots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération de la liste filtrée avec cache
    final list = ref.watch(cachedFilteredCoursProvider);

    // Détection de la largeur pour le responsive avec breakpoints améliorés
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;
    final isVeryWide = screenWidth >= 1200;

    return Column(
      children: [
        // Actions rapides (Nouveau / Rafraîchir)
        _ActionsBar(),
        _FiltersBar(fournisseurs: fournisseurs),
        // Indicateur de tri mobile
        if (!isWide) _SortIndicator(),

        // Indicateur de performance adaptatif
        if (isWide) const PerformanceIndicator(),

        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(coursDeRouteListProvider);
              ref.invalidate(coursCacheProvider);
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            child: isWide
                ? _DataTableView(
                    list: list,
                    fournisseurs: fournisseurs,
                    produits: produits,
                    produitCodes: produitCodes,
                    depots: depots,
                  )
                : _InfiniteScrollView(
                    fournisseurs: fournisseurs,
                    produits: produits,
                    produitCodes: produitCodes,
                    depots: depots,
                  ),
          ),
        ),

        // Contrôles de pagination adaptatifs
        if (isVeryWide) const PaginationControls(),
        if (isWide && !isVeryWide) const CompactPaginationControls(),
        if (!isWide)
          const SizedBox.shrink(), // Pas de pagination sur mobile avec scroll infini
      ],
    );
  }
}

/// Barre de filtres simplifiée
class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({required this.fournisseurs});

  final Map<String, String> fournisseurs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(coursFiltersProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    void setFilters(CoursFilters f) {
      ref.read(coursFiltersProvider.notifier).state = f;
    }

    return Padding(
      padding: EdgeInsets.all(screenWidth >= 800 ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne de filtres simplifiée
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: screenWidth >= 800 ? 16 : 12,
            runSpacing: screenWidth >= 800 ? 12 : 8,
            children: [
              // Filtre par fournisseur
              DropdownButton<String?>(
                hint: const Text('Fournisseur'),
                value: filters.fournisseurId,
                items:
                    <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tous les fournisseurs'),
                      ),
                    ] +
                    fournisseurs.entries
                        .map(
                          (e) => DropdownMenuItem<String?>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged: (id) =>
                    setFilters(filters.copyWith(fournisseurId: id)),
              ),

              // Affichage du filtre volume actuel
              Chip(
                label: Text(
                  'Volume: ${filters.volumeMin.toInt()}L - ${filters.volumeMax.toInt()}L',
                ),
                onDeleted: () => setFilters(const CoursFilters()),
              ),

              // Bouton pour ouvrir le range slider volume
              OutlinedButton.icon(
                onPressed: () =>
                    _showVolumeRangeDialog(context, filters, setFilters),
                icon: const Icon(Icons.tune),
                label: const Text('Modifier volume'),
              ),

              // Bouton reset filtres
              if (_hasActiveFilters(filters))
                OutlinedButton.icon(
                  onPressed: () => setFilters(const CoursFilters()),
                  icon: const Icon(Icons.clear),
                  label: const Text('Effacer'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Vérifie si des filtres sont actifs (différents des valeurs par défaut)
  bool _hasActiveFilters(CoursFilters filters) {
    const defaultFilters = CoursFilters();
    return filters.fournisseurId != defaultFilters.fournisseurId ||
        filters.volumeMin != defaultFilters.volumeMin ||
        filters.volumeMax != defaultFilters.volumeMax;
  }

  /// Affiche le dialog pour sélectionner la plage de volume
  Future<void> _showVolumeRangeDialog(
    BuildContext context,
    CoursFilters filters,
    void Function(CoursFilters) setFilters,
  ) async {
    double volumeMin = filters.volumeMin;
    double volumeMax = filters.volumeMax;

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtrer par volume'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Volume: ${volumeMin.toInt()}L - ${volumeMax.toInt()}L'),
                const SizedBox(height: 16),
                RangeSlider(
                  values: RangeValues(volumeMin, volumeMax),
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  labels: RangeLabels(
                    '${volumeMin.toInt()}L',
                    '${volumeMax.toInt()}L',
                  ),
                  onChanged: (values) {
                    setState(() {
                      volumeMin = values.start;
                      volumeMax = values.end;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop({'min': 0.0, 'max': 100000.0}),
              child: const Text('Effacer'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop({'min': volumeMin, 'max': volumeMax}),
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final min = result['min'] == 0 ? null : result['min'];
      final max = result['max'] == 50000 ? null : result['max'];
      setFilters(filters.copyWith(volumeMin: min, volumeMax: max));
    }
  }
}

/// Vue mobile avec scroll infini
class _InfiniteScrollView extends ConsumerWidget {
  const _InfiniteScrollView({
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
    required this.depots,
  });

  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;
  final Map<String, String> depots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Détection du rôle PCA/Gérant pour mode read-only
    final role = ref.watch(userRoleProvider);
    final isPca = (role ?? UserRole.lecture) == UserRole.pca;
    final isGerant = (role ?? UserRole.lecture) == UserRole.gerant;
    final canWrite = !isPca && !isGerant;

    return InfiniteScrollCoursList(
      fournisseurs: fournisseurs,
      produits: produits,
      produitCodes: produitCodes,
      depots: depots,
      onCoursTap: (cours) => context.go('/cours/${cours.id}'),
      onAdvanceStatus: canWrite ? (cours) => _advanceStatus(context, ref, cours) : null,
      onCreateReception: canWrite ? (cours) => context.push('/receptions/new?coursId=${cours.id}') : null,
    );
  }

  /// Fonction helper pour avancer le statut d'un cours
  Future<void> _advanceStatus(
    BuildContext context,
    WidgetRef ref,
    CoursDeRoute cours,
  ) async {
    final nextEnum = StatutCoursDb.next(cours.statut);
    if (nextEnum == null) return;

    // Passage à DECHARGE : ouvrir la création de Réception
    if (nextEnum == StatutCours.decharge) {
      context.push('/receptions/new?coursId=${cours.id}');
      return;
    }

    try {
      await ref
          .read(coursDeRouteServiceProvider)
          .updateStatut(id: cours.id, to: nextEnum);
      if (context.mounted) {
        showAppToast(
          context,
          'Statut mis à jour → ${nextEnum.label}',
          type: ToastType.success,
        );
        // Rafraîchir les listes
        ref.invalidate(coursDeRouteListProvider);
        ref.invalidate(coursDeRouteActifsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        showAppToast(context, humanizePostgrest(e), type: ToastType.error);
      }
    }
  }
}

/// Vue desktop avec DataTable
class _DataTableView extends ConsumerWidget {
  const _DataTableView({
    required this.list,
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
    required this.depots,
  });

  final List<CoursDeRoute> list;
  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;
  final Map<String, String> depots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Détection du rôle PCA/Gérant pour mode read-only
    final role = ref.watch(userRoleProvider);
    final isPca = (role ?? UserRole.lecture) == UserRole.pca;
    final isGerant = (role ?? UserRole.lecture) == UserRole.gerant;
    final canWrite = !isPca && !isGerant;

    // Utiliser la liste paginée au lieu de la liste complète
    final paginatedList = ref.watch(paginatedCoursProvider);

    // Helper pour afficher les plaques
    String plaquesLabel(String? plaqueCamion, String? plaqueRemorque) {
      final c = (plaqueCamion ?? '').trim();
      final r = (plaqueRemorque ?? '').trim();
      final left = c.isEmpty ? '—' : c;
      final right = r.isEmpty ? '—' : r;
      return '$left / $right';
    }

    final width = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isWideScreen = availableWidth >= 1200;
        final isMediumScreen = availableWidth >= 800;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: availableWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dataTableTheme: DataTableThemeData(
                          headingTextStyle: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                letterSpacing: .5,
                                fontWeight: FontWeight.w600,
                              ),
                          dataRowMinHeight: 44,
                          dataRowMaxHeight: 56,
                          columnSpacing: _getColumnSpacing(availableWidth),
                        ),
                      ),
                      child: DataTable(
                        columnSpacing: _getColumnSpacing(availableWidth),
                        horizontalMargin: 12,
                        columns: _buildSortableColumns(ref, context),
                        rows: paginatedList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final c = entry.value;
                          final pLabel = produitLabel(
                            c,
                            produits,
                            produitCodes,
                          );
                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant.withValues(alpha: 0.18);
                              }
                              final isOdd = index.isOdd;
                              return isOdd
                                  ? Theme.of(context).colorScheme.surfaceVariant
                                        .withValues(alpha: 0.06)
                                  : null;
                            }),
                            cells: [
                              DataCell(
                                Text(nameOf(fournisseurs, c.fournisseurId)),
                              ),
                              DataCell(
                                (pLabel == '—')
                                    ? const Text('—')
                                    : Chip(
                                        label: Text(pLabel),
                                        visualDensity: VisualDensity.compact,
                                      ),
                              ),
                              DataCell(
                                Text(
                                  plaquesLabel(
                                    c.plaqueCamion,
                                    c.plaqueRemorque,
                                  ),
                                ),
                              ),
                              DataCell(Text(c.chauffeur ?? '—')),
                              DataCell(Text(c.transporteur ?? '—')),
                              DataCell(Text(fmtVolume(c.volume))),
                              DataCell(
                                Text(nameOf(depots, c.depotDestinationId)),
                              ),
                              DataCell(Text(fmtDate(c.dateChargement))),
                              DataCell(_statutBadge(c.statut)),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton.filledTonal(
                                      tooltip: 'Voir',
                                      onPressed: () =>
                                          context.go('/cours/${c.id}'),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      style: IconButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                    if (canWrite) ...[
                                      const SizedBox(width: 6),
                                      _AdvanceButton(c: c),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Détermine l'espacement des colonnes selon la largeur de l'écran
  double _getColumnSpacing(double width) {
    if (width >= 1400) return 32;
    if (width >= 1200) return 28;
    if (width >= 1000) return 24;
    if (width >= 800) return 20;
    if (width >= 600) return 16;
    return 12;
  }

  /// Construit les colonnes triables pour la DataTable
  List<DataColumn> _buildSortableColumns(WidgetRef ref, BuildContext context) {
    final sortConfig = ref.watch(coursSortProvider);

    return [
      _buildSortableColumn(
        label: 'Fournisseur',
        column: CoursSortColumn.fournisseur,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      _buildSortableColumn(
        label: 'Produit',
        column: CoursSortColumn.produit,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      _buildSortableColumn(
        label: 'Plaques',
        column: CoursSortColumn.plaques,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      _buildSortableColumn(
        label: 'Chauffeur',
        column: CoursSortColumn.chauffeur,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      _buildSortableColumn(
        label: 'Transporteur',
        column: CoursSortColumn.transporteur,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      _buildSortableColumn(
        label: 'Volume',
        column: CoursSortColumn.volume,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
        numeric: true,
      ),
      _buildSortableColumn(
        label: 'Dépôt',
        column: CoursSortColumn.depot,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      _buildSortableColumn(
        label: 'Date',
        column: CoursSortColumn.date,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      _buildSortableColumn(
        label: 'Statut',
        column: CoursSortColumn.statut,
        sortConfig: sortConfig,
        ref: ref,
        context: context,
      ),
      const DataColumn(label: Text('Actions')),
    ];
  }

  /// Construit une colonne triable
  DataColumn _buildSortableColumn({
    required String label,
    required CoursSortColumn column,
    required CoursSortConfig sortConfig,
    required WidgetRef ref,
    required BuildContext context,
    bool numeric = false,
  }) {
    final isActive = sortConfig.column == column;
    final isAscending = sortConfig.direction == SortDirection.ascending;

    return DataColumn(
      numeric: numeric,
      label: InkWell(
        onTap: () {
          final newDirection = isActive && isAscending
              ? SortDirection.descending
              : SortDirection.ascending;
          ref.read(coursSortProvider.notifier).state = CoursSortConfig(
            column: column,
            direction: newDirection,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bouton d'avancement de statut
class _AdvanceButton extends ConsumerStatefulWidget {
  const _AdvanceButton({required this.c});

  final CoursDeRoute c;

  @override
  ConsumerState<_AdvanceButton> createState() => _AdvanceButtonState();
}

class _AdvanceButtonState extends ConsumerState<_AdvanceButton> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final canAdvance = [
      'operateur',
      'gerant',
      'directeur',
      'admin',
    ].contains((role ?? UserRole.lecture).value);
    final nextEnum = StatutCoursDb.next(widget.c.statut);

    return IconButton.filledTonal(
      tooltip: 'Avancer le statut',
      onPressed: (!canAdvance || nextEnum == null || busy)
          ? null
          : () async {
              // Passage à DECHARGE : ouvrir la création de Réception
              if (nextEnum == StatutCours.decharge) {
                context.push('/receptions/new?coursId=${widget.c.id}');
                return;
              }

              setState(() => busy = true);
              try {
                await ref
                    .read(coursDeRouteServiceProvider)
                    .updateStatut(id: widget.c.id, to: nextEnum);
                if (!context.mounted) return;
                showAppToast(
                  context,
                  'Statut mis à jour → ${nextEnum.label}',
                  type: ToastType.success,
                );
                // Rafraîchir les listes
                ref.invalidate(coursDeRouteListProvider);
                ref.invalidate(coursDeRouteActifsProvider);
              } catch (e) {
                if (!context.mounted) return;
                showAppToast(
                  context,
                  humanizePostgrest(e),
                  type: ToastType.error,
                );
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.trending_flat, size: 18),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

/// État vide
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Aucun cours pour le moment'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Créer un cours'),
          ),
        ],
      ),
    );
  }
}

/// État vide en mode read-only (PCA)
class _EmptyStateReadOnly extends StatelessWidget {
  const _EmptyStateReadOnly();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Aucun cours pour le moment'),
          SizedBox(height: 8),
          Text('Accès PCA : lecture seule'),
        ],
      ),
    );
  }
}

/// État d'erreur
class _ErrorState extends ConsumerWidget {
  const _ErrorState(this.message);

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(coursDeRouteListProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Badge de statut avec couleur
Widget _statutBadge(StatutCours statut) {
  late final Color bg;
  late final IconData icon;
  switch (statut) {
    case StatutCours.chargement:
      bg = Colors.blue.shade100;
      icon = Icons.inventory_2;
      break;
    case StatutCours.transit:
      bg = Colors.orange.shade100;
      icon = Icons.local_shipping;
      break;
    case StatutCours.frontiere:
      bg = Colors.amber.shade100;
      icon = Icons.flag;
      break;
    case StatutCours.arrive:
      bg = Colors.green.shade100;
      icon = Icons.place;
      break;
    case StatutCours.decharge:
      bg = Colors.grey.shade300;
      icon = Icons.task_alt;
      break;
  }
  return Chip(
    avatar: Icon(icon, size: 16),
    label: Text(statut.label),
    backgroundColor: bg,
    visualDensity: VisualDensity.compact,
  );
}

/// Barre d'actions rapide au-dessus des filtres (non-intrusive)
class _ActionsBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Détection du rôle PCA/Gérant pour mode read-only
    final role = ref.watch(userRoleProvider);
    final isPca = (role ?? UserRole.lecture) == UserRole.pca;
    final isGerant = (role ?? UserRole.lecture) == UserRole.gerant;
    final canWrite = !isPca && !isGerant;

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth >= 800 ? 16 : 12,
        screenWidth >= 800 ? 16 : 12,
        screenWidth >= 800 ? 16 : 12,
        0,
      ),
      child: Wrap(
        spacing: screenWidth >= 800 ? 12 : 8,
        runSpacing: screenWidth >= 800 ? 12 : 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (canWrite)
            FilledButton.icon(
              onPressed: () => context.go('/cours/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau'),
            ),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(coursDeRouteListProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }
}

// _nextStatut supprimé: on utilise StatutCoursDb.next(enum)

/// Indicateur de tri pour la vue mobile
class _SortIndicator extends ConsumerWidget {
  const _SortIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortConfig = ref.watch(coursSortProvider);

    String getColumnLabel(CoursSortColumn column) {
      switch (column) {
        case CoursSortColumn.fournisseur:
          return 'Fournisseur';
        case CoursSortColumn.produit:
          return 'Produit';
        case CoursSortColumn.plaques:
          return 'Plaques';
        case CoursSortColumn.chauffeur:
          return 'Chauffeur';
        case CoursSortColumn.transporteur:
          return 'Transporteur';
        case CoursSortColumn.volume:
          return 'Volume';
        case CoursSortColumn.depot:
          return 'Dépôt';
        case CoursSortColumn.date:
          return 'Date';
        case CoursSortColumn.statut:
          return 'Statut';
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth >= 800 ? 16 : 12,
        vertical: screenWidth >= 800 ? 12 : 8,
      ),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Trié par: ${getColumnLabel(sortConfig.column)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            sortConfig.direction == SortDirection.ascending
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              showDialog(context: context, builder: (context) => _SortDialog());
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }
}

/// Dialog de sélection de tri pour mobile
class _SortDialog extends ConsumerWidget {
  const _SortDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortConfig = ref.watch(coursSortProvider);

    final columns = [
      (CoursSortColumn.date, 'Date'),
      (CoursSortColumn.fournisseur, 'Fournisseur'),
      (CoursSortColumn.produit, 'Produit'),
      (CoursSortColumn.volume, 'Volume'),
      (CoursSortColumn.statut, 'Statut'),
      (CoursSortColumn.transporteur, 'Transporteur'),
      (CoursSortColumn.chauffeur, 'Chauffeur'),
      (CoursSortColumn.plaques, 'Plaques'),
      (CoursSortColumn.depot, 'Dépôt'),
    ];

    return AlertDialog(
      title: const Text('Trier par'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: columns.map((column) {
          final (col, label) = column;
          final isSelected = sortConfig.column == col;

          return RadioListTile<CoursSortColumn>(
            title: Text(label),
            value: col,
            groupValue: sortConfig.column,
            onChanged: (value) {
              if (value != null) {
                ref.read(coursSortProvider.notifier).state = CoursSortConfig(
                  column: value,
                  direction: sortConfig.direction,
                );
              }
            },
            secondary: isSelected
                ? Icon(
                    sortConfig.direction == SortDirection.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        TextButton(
          onPressed: () {
            ref.read(coursSortProvider.notifier).state = CoursSortConfig(
              column: sortConfig.column,
              direction: sortConfig.direction == SortDirection.ascending
                  ? SortDirection.descending
                  : SortDirection.ascending,
            );
          },
          child: Text(
            sortConfig.direction == SortDirection.ascending
                ? 'Décroissant'
                : 'Croissant',
          ),
        ),
      ],
    );
  }
}
