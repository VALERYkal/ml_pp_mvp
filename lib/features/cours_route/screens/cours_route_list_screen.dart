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

/// Fonction utilitaire pour afficher le libellé du produit
/// 
/// Priorité : produitCode > produitNom > référentiels > fallback
String produitLabel(CoursDeRoute c, Map<String, String> produits, Map<String, String> produitCodes) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération des données asynchrones
    final coursAsync = ref.watch(coursDeRouteListProvider);
    final refDataAsync = ref.watch(refDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours de Route'),
        actions: [
          IconButton(
            tooltip: 'Nouveau cours',
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
            return _EmptyState(onCreate: () => context.go('/cours/new'));
          }
          
          return refDataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState('Erreur référentiels: $e'),
            data: (refData) => _ListContent(
              fournisseurs: refData.fournisseurs,
              produits: refData.produits,
              produitCodes: refData.produitCodes,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/cours/new'),
        child: const Icon(Icons.add),
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
  });

  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération de la liste filtrée
    final list = ref.watch(filteredCoursProvider);

    // Détection de la largeur pour le responsive
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        // Actions rapides (Nouveau / Rafraîchir)
        _ActionsBar(),
        _FiltersBar(
          fournisseurs: fournisseurs,
          produits: produits,
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(coursDeRouteListProvider);
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            child: isWide
                ? _DataTableView(
                    list: list,
                    fournisseurs: fournisseurs,
                    produits: produits,
                    produitCodes: produitCodes,
                  )
                : _CardsView(
                    list: list,
                    fournisseurs: fournisseurs,
                    produits: produits,
                    produitCodes: produitCodes,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Barre de filtres
class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({
    required this.fournisseurs,
    required this.produits,
  });

  final Map<String, String> fournisseurs;
  final Map<String, String> produits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(coursFiltersProvider);
    
    void setFilters(CoursFilters f) {
      ref.read(coursFiltersProvider.notifier).state = f;
    }

    const statuts = [
      'Tous',
      'chargement',
      'transit',
      'frontiere',
      'arrive',
      'decharge'
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // Filtre par statut
          DropdownButton<String>(
            value: filters.statut,
            items: statuts
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                .toList(),
            onChanged: (s) => setFilters(filters.copyWith(statut: s)),
          ),
          
          // Filtre par produit
          DropdownButton<String?>(
            hint: const Text('Produit'),
            value: filters.produitId,
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tous'),
              ),
            ] +
                produits.entries
                    .map((e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
            onChanged: (id) => setFilters(filters.copyWith(produitId: id)),
          ),
          
          // Recherche textuelle
          SizedBox(
            width: 260,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Plaque ou chauffeur…',
              ),
              onChanged: (q) => setFilters(filters.copyWith(query: q)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vue desktop avec DataTable
class _DataTableView extends ConsumerWidget {
  const _DataTableView({
    required this.list,
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
  });

  final List<CoursDeRoute> list;
  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Helper pour afficher les plaques
    String plaquesLabel(String? plaqueCamion, String? plaqueRemorque) {
      final c = (plaqueCamion ?? '').trim();
      final r = (plaqueRemorque ?? '').trim();
      final left = c.isEmpty ? '—' : c;
      final right = r.isEmpty ? '—' : r;
      return '$left / $right';
    }
    
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Theme(
        data: Theme.of(context).copyWith(
          dataTableTheme: DataTableThemeData(
            headingTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: .5,
                  fontWeight: FontWeight.w600,
                ),
            dataRowMinHeight: 44,
            dataRowMaxHeight: 56,
            columnSpacing: width >= 1000 ? 24 : 12,
          ),
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Fournisseur')),
            DataColumn(label: Text('Produit')),
            DataColumn(label: Text('Plaques')),
            DataColumn(label: Text('Chauffeur')),
            DataColumn(numeric: true, label: Text('Volume')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: list.asMap().entries.map((entry) {
            final index = entry.key;
            final c = entry.value;
            final pLabel = produitLabel(c, produits, produitCodes);
            return DataRow(
              color: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.18);
                }
                final isOdd = index.isOdd;
                return isOdd
                    ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.06)
                    : null;
              }),
              cells: [
                DataCell(Text(nameOf(fournisseurs, c.fournisseurId))),
                DataCell(
                  (pLabel == '—')
                      ? const Text('—')
                      : Chip(label: Text(pLabel), visualDensity: VisualDensity.compact),
                ),
                DataCell(Text(plaquesLabel(c.plaqueCamion, c.plaqueRemorque))),
                DataCell(Text(c.chauffeur ?? '—')),
                DataCell(Text(fmtVolume(c.volume))),
                DataCell(Text(fmtDate(c.dateChargement))),
                DataCell(_statutBadge(c.statut)),
                DataCell(
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Voir',
                        onPressed: () => context.go('/cours/${c.id}'),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _AdvanceButton(c: c),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Vue mobile avec Cards
class _CardsView extends ConsumerWidget {
  const _CardsView({
    required this.list,
    required this.fournisseurs,
    required this.produits,
    required this.produitCodes,
  });

  final List<CoursDeRoute> list;
  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> produitCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Helper pour afficher les plaques
    String plaquesLabel(String? plaqueCamion, String? plaqueRemorque) {
      final c = (plaqueCamion ?? '').trim();
      final r = (plaqueRemorque ?? '').trim();
      final left = c.isEmpty ? '—' : c;
      final right = r.isEmpty ? '—' : r;
      return '$left / $right';
    }
    
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, i) {
        final c = list[i];
        return Card(
          child: ListTile(
            title: Text(
              '${nameOf(fournisseurs, c.fournisseurId)} • ${produitLabel(c, produits, produitCodes)}',
            ),
            subtitle: Text(
              '${plaquesLabel(c.plaqueCamion, c.plaqueRemorque)} • ${c.chauffeur ?? '—'}\n${fmtDate(c.dateChargement)} • ${fmtVolume(c.volume)}\nProduit: ${produitLabel(c, produits, produitCodes)}',
            ),
            trailing: _statutBadge(c.statut),
            onTap: () => context.go('/cours/${c.id}'),
          ),
        );
      },
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
    final canAdvance = ['operateur', 'gerant', 'directeur', 'admin']
        .contains((role ?? UserRole.lecture).value);
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
                if (mounted) {
                  showAppToast(context, 'Statut mis à jour → ${nextEnum.label}', type: ToastType.success);
                  // Rafraîchir les listes
                  ref.invalidate(coursDeRouteListProvider);
                  ref.invalidate(coursDeRouteActifsProvider);
                }
              } catch (e) {
                if (mounted) {
                  showAppToast(context, humanizePostgrest(e), type: ToastType.error);
                }
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
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
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
