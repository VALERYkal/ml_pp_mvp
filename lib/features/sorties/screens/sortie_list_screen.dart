import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sortie_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SortieListScreen extends ConsumerWidget {
  const SortieListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorties = ref.watch(sortiesListProvider);
    // Persist pagination selections
    Future<void> _persist(int page, int size) async {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('sorties_page', page);
      await sp.setInt('sorties_size', size);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sorties produit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Taille page:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: ref.watch(sortiesPageSizeProvider),
                  items: const [
                    DropdownMenuItem(value: 25, child: Text('25')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                  ],
                  onChanged: (v) async {
                    final val = v ?? 25;
                    ref.read(sortiesPageSizeProvider.notifier).state = val;
                    await _persist(ref.read(sortiesPageProvider), val);
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Précédent',
                  onPressed: ref.watch(sortiesPageProvider) > 0
                      ? () async {
                          final newPage = ref.read(sortiesPageProvider) - 1;
                          ref.read(sortiesPageProvider.notifier).state = newPage;
                          await _persist(newPage, ref.read(sortiesPageSizeProvider));
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${ref.watch(sortiesPageProvider) + 1}'),
                IconButton(
                  tooltip: 'Suivant',
                  onPressed: () async {
                    final newPage = ref.read(sortiesPageProvider) + 1;
                    ref.read(sortiesPageProvider.notifier).state = newPage;
                    await _persist(newPage, ref.read(sortiesPageSizeProvider));
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: sorties.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucune sortie'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = items[index];
              final date = s.dateSortie ?? s.createdAt;
              final idShort = s.produitId.substring(0, s.produitId.length > 6 ? 6 : s.produitId.length);
              final title = 'Sortie $idShort';
              final subtitle = 'Vol. ${s.volumeAmbiant?.toStringAsFixed(0) ?? '-'} L • ${s.statut}';
              return ListTile(
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: Text(date != null ? _fmt(date) : ''),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/sorties/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

