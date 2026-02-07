import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/fournisseur.dart';
import '../../providers/fournisseur_providers.dart';
import '../utils/fournisseur_list_utils.dart';

/// Keys stables pour accessibilité et tests.
const keyFournisseursSearch = Key('fournisseurs_search');
const keyFournisseursSortToggle = Key('fournisseurs_sort_toggle');
const keyFournisseursList = Key('fournisseurs_list');

Key keyFournisseursRow(String id) => Key('fournisseurs_row_$id');

/// Écran liste fournisseurs (Sprint 1 — lecture seule).
/// Recherche client-side (nom, pays, contact_personne), tri nom A→Z / Z→A.
class FournisseursListScreen extends ConsumerStatefulWidget {
  const FournisseursListScreen({super.key});

  @override
  ConsumerState<FournisseursListScreen> createState() =>
      _FournisseursListScreenState();
}

class _FournisseursListScreenState extends ConsumerState<FournisseursListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAsc = true; // true = A→Z, false = Z→A

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchController.text;
    if (q != _searchQuery) setState(() => _searchQuery = q);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _contact(Fournisseur f) {
    if (f.email != null && f.email!.isNotEmpty) return f.email!;
    if (f.telephone != null && f.telephone!.isNotEmpty) return f.telephone!;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(fournisseursListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseurs'),
        actions: [
          Semantics(
            button: true,
            label: _sortAsc ? 'Tri A vers Z par nom' : 'Tri Z vers A par nom',
            child: IconButton(
              key: keyFournisseursSortToggle,
              tooltip: _sortAsc ? 'Tri A→Z' : 'Tri Z→A',
              icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () => setState(() => _sortAsc = !_sortAsc),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Semantics(
              textField: true,
              label: 'Rechercher par nom, pays ou contact',
              hint: 'Rechercher (nom, pays, contact)',
              child: TextField(
                key: keyFournisseursSearch,
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher (nom, pays, contact)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          Expanded(
            child: asyncList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildError(context),
              data: (list) {
                final filtered = filterFournisseurs(list, _searchQuery);
                final sorted = sortFournisseursByNom(filtered, _sortAsc);
                if (sorted.isEmpty) {
                  return _buildEmpty(context, list.isEmpty);
                }
                return _buildList(context, sorted, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
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
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(fournisseursListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool noDataAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              noDataAtAll ? 'Aucun fournisseur' : 'Aucun fournisseur',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifie la recherche ou le référentiel DB.',
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

  Widget _buildList(
    BuildContext context,
    List<Fournisseur> list,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '${list.length} fournisseur(s)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: keyFournisseursList,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final f = list[index];
              final contact = _contact(f);
              final subtitle = [
                if (f.pays != null && f.pays!.isNotEmpty) 'Pays: ${f.pays}',
                if (contact.isNotEmpty) 'Contact: $contact',
              ].join(' · ');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  key: keyFournisseursRow(f.id),
                  title: Text(f.nom),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  isThreeLine: subtitle.length > 40,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/fournisseurs/${f.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
