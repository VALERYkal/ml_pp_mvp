// 📌 Module : Cours de Route - Widgets
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Liste avec scroll infini pour les cours de route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_pagination_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';

/// Liste avec scroll infini pour la vue mobile
class InfiniteScrollCoursList extends ConsumerStatefulWidget {
  const InfiniteScrollCoursList({
    super.key,
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
    required this.depots,
    required this.onCoursTap,
    required this.onAdvanceStatus,
    required this.onCreateReception,
  });

  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;
  final Map<String, String> depots;
  final void Function(CoursDeRoute) onCoursTap;
  final void Function(CoursDeRoute) onAdvanceStatus;
  final void Function(CoursDeRoute) onCreateReception;

  @override
  ConsumerState<InfiniteScrollCoursList> createState() => _InfiniteScrollCoursListState();
}

class _InfiniteScrollCoursListState extends ConsumerState<InfiniteScrollCoursList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final hasMore = ref.read(hasMorePagesProvider);
    if (!hasMore) return;

    setState(() => _isLoadingMore = true);

    // Simuler un délai de chargement
    await Future.delayed(const Duration(milliseconds: 500));

    final currentPage = ref.read(coursPaginationProvider).currentPage;
    ref.read(coursPaginationProvider.notifier).state = ref
        .read(coursPaginationProvider)
        .copyWith(currentPage: currentPage + 1);

    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final cours = ref.watch(paginatedCoursProvider);
    final hasMore = ref.watch(hasMorePagesProvider);

    return ListView.separated(
      controller: _scrollController,
      itemCount: cours.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        if (index == cours.length) {
          // Indicateur de chargement en bas
          return _LoadingIndicator(isLoading: _isLoadingMore);
        }

        final c = cours[index];
        return _CoursCard(
          cours: c,
          fournisseurs: widget.fournisseurs,
          produits: widget.produits,
          produitCodes: widget.produitCodes,
          depots: widget.depots,
          onTap: () => widget.onCoursTap(c),
          onAdvanceStatus: () => widget.onAdvanceStatus(c),
          onCreateReception: () => widget.onCreateReception(c),
        );
      },
    );
  }
}

/// Card pour un cours de route
class _CoursCard extends StatelessWidget {
  const _CoursCard({
    required this.cours,
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
    required this.depots,
    required this.onTap,
    required this.onAdvanceStatus,
    required this.onCreateReception,
  });

  final CoursDeRoute cours;
  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;
  final Map<String, String> depots;
  final VoidCallback onTap;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onCreateReception;

  @override
  Widget build(BuildContext context) {
    // Helper pour afficher les plaques
    String plaquesLabel(String? plaqueCamion, String? plaqueRemorque) {
      final c = (plaqueCamion ?? '').trim();
      final r = (plaqueRemorque ?? '').trim();
      final left = c.isEmpty ? '—' : c;
      final right = r.isEmpty ? '—' : r;
      return '$left / $right';
    }

    // Helper pour le libellé du produit
    String produitLabel(
      CoursDeRoute c,
      Map<String, String> produits,
      Map<String, String> produitCodes,
    ) {
      final code = (c.produitCode ?? '').trim();
      final nom = (c.produitNom ?? '').trim();
      if (code.isNotEmpty) return code;
      if (nom.isNotEmpty) return nom;
      return '—';
    }

    return Card(
      child: ListTile(
        title: Text(
          '${nameOf(fournisseurs, cours.fournisseurId)} • ${produitLabel(cours, produits, produitCodes)}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plaquesLabel(cours.plaqueCamion, cours.plaqueRemorque)} • ${cours.chauffeur ?? '—'}',
            ),
            Text('${cours.transporteur ?? '—'} • ${fmtDate(cours.dateChargement)}'),
            Text('${fmtVolume(cours.volume)} • ${nameOf(depots, cours.depotDestinationId)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                _statutBadge(cours.statut),
                const Spacer(),
                _ActionButtons(
                  cours: cours,
                  onAdvanceStatus: onAdvanceStatus,
                  onCreateReception: onCreateReception,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}

/// Boutons d'action pour un cours
class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.cours,
    required this.onAdvanceStatus,
    required this.onCreateReception,
  });

  final CoursDeRoute cours;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onCreateReception;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextStatut = StatutCoursDb.next(cours.statut);

    if (nextStatut == null) {
      return const SizedBox.shrink();
    }

    if (nextStatut == StatutCours.decharge) {
      return FilledButton.tonalIcon(
        onPressed: onCreateReception,
        icon: const Icon(Icons.add_box, size: 16),
        label: const Text('Réception'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: onAdvanceStatus,
      icon: const Icon(Icons.trending_flat, size: 16),
      label: const Text('Suivant'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

/// Indicateur de chargement
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Chargement...'),
                ],
              )
            : const Text(
                'Tous les cours ont été chargés',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
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
