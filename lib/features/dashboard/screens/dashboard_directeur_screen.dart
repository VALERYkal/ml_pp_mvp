// 📌 Module : Dashboard Feature - Directeur Screen
// 🧑 Auteur : Valery Kalonga
// 🗓️ Maj : 2025-08-16
// 🧭 Description : Écran directeur avec KPIs, citernes sous seuil et activités récentes (filtres + export)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widgets utilitaires (assure-toi que ces fichiers existent)
import 'package:ml_pp_mvp/features/dashboard/widgets/kpi_card.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/placeholders.dart';

// Providers réels (adapte les chemins si besoin)
import 'package:ml_pp_mvp/features/dashboard/providers/directeur_kpi_provider.dart' as kpi;
import 'package:ml_pp_mvp/features/citernes/providers/citernes_sous_seuil_provider.dart' as cit;
import 'package:ml_pp_mvp/features/logs/providers/logs_provider.dart' as logs;
import 'package:ml_pp_mvp/features/logs/services/logs_service.dart' as logs_service;

class DashboardDirecteurScreen extends ConsumerWidget {
  const DashboardDirecteurScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ===== KPIs =====
    final kpis = ref.watch(kpi.directeurKpiProvider);
    final kpiHeader = kpis.when(
      loading: () => const ShimmerRow(),
      error: (e, _) => ErrorTile(
        'Impossible de charger les KPIs',
        onRetry: () => ref.invalidate(kpi.directeurKpiProvider),
      ),
      data: (d) => Wrap(
        spacing: 16, runSpacing: 16,
        children: [
          KpiCard(title: 'Réceptions (jour)', value: d.receptionsJour),
          KpiCard(title: 'Sorties (jour)', value: d.sortiesJour),
          KpiCard(title: 'Citernes sous seuil', value: d.citernesSousSeuil, warning: true),
        ],
      ),
    );

    // ===== Citernes sous seuil =====
    final citSousSeuil = ref.watch(cit.citernesSousSeuilProvider);
    final citSection = citSousSeuil.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorTile(
          'Erreur citernes sous seuil',
          onRetry: () => ref.invalidate(cit.citernesSousSeuilProvider),
        ),
      ),
      data: (rows) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Citernes sous seuil', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  const Text('Aucune citerne sous le seuil de sécurité')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = rows[i];
                      return ListTile(
                        leading: const Icon(Icons.local_gas_station),
                        title: Text(c.nom),
                        subtitle: Text(
                          'Capacité: ${c.capaciteTotale} L • Stock: ${c.stockActuel} L • Seuil: ${c.capaciteSecurite} L',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: context.go('/citernes?id=${c.id}');
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // ===== Logs récents (filtres collants + export) =====
    final filter = ref.watch(logs.logsFilterProvider);
    final logsAsync = ref.watch(logs.logsProvider(filter));

    final logsFilters = SliverPersistentHeader(
      pinned: true,
      delegate: _StickyFilters(
        child: Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: filter.period, // '7d' | '30d' | '90d' (ex.)
                    decoration: const InputDecoration(labelText: 'Période', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '7d', child: Text('7 jours')),
                      DropdownMenuItem(value: '30d', child: Text('30 jours')),
                      DropdownMenuItem(value: '90d', child: Text('90 jours')),
                    ],
                    onChanged: (v) => ref.read(logs.logsFilterProvider.notifier).state = filter.copyWith(period: v ?? '30d'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    value: filter.module,
                    decoration: const InputDecoration(labelText: 'Module', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'receptions', child: Text('Réceptions')),
                      DropdownMenuItem(value: 'sorties', child: Text('Sorties')),
                      DropdownMenuItem(value: 'citernes', child: Text('Citernes')),
                      DropdownMenuItem(value: 'cours_de_route', child: Text('Cours de route')),
                      DropdownMenuItem(value: 'logs', child: Text('Logs')),
                    ],
                    onChanged: (v) => ref.read(logs.logsFilterProvider.notifier).state = filter.copyWith(module: v),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(logs_service.logsServiceProvider).exportCsv(filter);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export CSV lancé')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter CSV'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final logsSliver = logsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              6,
              (_) => Container(
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.black12,
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorTile(
            'Erreur chargement des activités',
            onRetry: () => ref.invalidate(logs.logsProvider(filter)),
          ),
        ),
      ),
      data: (items) => items.isEmpty
          ? const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune activité récente'),
              ),
            )
          : SliverList.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                return ListTile(
                  leading: Icon(
                    it.niveau == 'CRITICAL'
                        ? Icons.error
                        : it.niveau == 'WARNING'
                            ? Icons.warning_amber
                            : Icons.info,
                  ),
                  title: Text('${it.module} • ${it.action}'),
                  subtitle: Text(it.createdAtFmt), // formate dans le provider/modèle
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: showDialog avec détails JSON
                  },
                );
              },
            ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(kpi.directeurKpiProvider);
        ref.invalidate(cit.citernesSousSeuilProvider);
        ref.invalidate(logs.logsProvider(filter));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: kpiHeader)),
          SliverToBoxAdapter(child: citSection),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          logsFilters,
          logsSliver,
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// Sticky header minimal
class _StickyFilters extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyFilters({required this.child});

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
