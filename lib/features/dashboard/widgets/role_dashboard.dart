import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// KPI 1
import 'package:ml_pp_mvp/features/kpi/providers/cours_kpi_provider.dart';
// KPI 2
import 'package:ml_pp_mvp/features/kpi/providers/receptions_kpi_provider.dart';
// KPI 3
import 'package:ml_pp_mvp/features/kpi/providers/stocks_kpi_provider.dart';
// KPI 4
import 'package:ml_pp_mvp/features/kpi/providers/sorties_kpi_provider.dart';
// KPI 5
import 'package:ml_pp_mvp/features/kpi/providers/balance_kpi_provider.dart';

import 'package:ml_pp_mvp/features/kpi/widgets/kpi_split_card.dart';
import 'package:ml_pp_mvp/features/kpi/widgets/kpi_summary_card.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/shared/utils/formatters.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/kpi_tiles.dart';

class RoleDashboard extends ConsumerWidget {
  const RoleDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Realtime invalidators (no UI)
    ref.watch(coursRealtimeInvalidatorProvider);
    ref.watch(stocksRealtimeInvalidatorProvider);
    ref.watch(sortiesRealtimeInvalidatorProvider);

    // --- KPI 1: Camions (en route / attente + volumes)
    final coursParam  = ref.watch(coursDefaultParamProvider);
    final coursState  = ref.watch(coursKpiProvider(coursParam));

    final kpiCamions = coursState.when(
      data: (d) => KpiSplitCard(
        title: 'Camions à suivre',
        icon: Icons.local_shipping_outlined,
        leftLabel: 'En route',
        leftValue: '${d.enRoute}',
        leftSubLabel: 'Volume prévu',
        leftSubValue: fmtLiters(d.enRouteLitres),
        rightLabel: 'En attente de déchargement',
        rightValue: '${d.attente}',
        rightSubLabel: 'Volume prévu',
        rightSubValue: fmtLiters(d.attenteLitres),
        onTap: () => context.go('/cours'),
      ),
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 120, child: Center(child: Text('KPI Cours indisponible'))),
    );

    // --- KPI 2: Réceptions (jour)
    final recParam   = ref.watch(receptionsTodayParamProvider);
    final recState   = ref.watch(receptionsKpiProvider(recParam));

    final kpiReceptions = recState.when(
      data: (d) => KpiSummaryCard(
        title: 'Réceptions (jour)',
        totalValue: '${d.nbCamions}',
        details: [
          KpiLabelValue('Vol. ambiant', fmtLiters(d.volAmbiant)),
          KpiLabelValue('Vol. 15 °C',   fmtLiters(d.vol15c)),
        ],
        icon: Icons.move_to_inbox_outlined,
        onTap: () => context.go('/receptions'),
      ),
      loading: () => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
      error:  (_, __) => const SizedBox(height: 110, child: Center(child: Text('Réceptions indisponibles'))),
    );

    // --- KPI 4: Sorties (jour)
    final sorParam   = ref.watch(sortiesTodayParamProvider);
    final sorState   = ref.watch(sortiesKpiProvider(sorParam));

    final kpiSorties = sorState.when(
      data: (d) => KpiSummaryCard(
        title: 'Sorties (jour)',
        totalValue: '${d.nbCamions}',
        details: [
          KpiLabelValue('Vol. ambiant', fmtLiters(d.volAmbiant)),
          KpiLabelValue('Vol. 15 °C',   fmtLiters(d.vol15c)),
        ],
        icon: Icons.outbox_outlined,
        onTap: () => context.go('/sorties'),
      ),
      loading: () => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
      error:  (_, __) => const SizedBox(height: 110, child: Center(child: Text('Sorties indisponibles'))),
    );

    // --- KPI 5: Balance (jour) = Réceptions - Sorties (ambiant & 15°C)
    final balanceState = ref.watch(balanceTodayProvider);
    final kpiBalance = balanceState.when(
      data: (b) {
        Color tint(num v) => v > 0 ? Colors.teal : (v < 0 ? Colors.red : Colors.grey);
        return KpiSplitCard(
          title: 'Balance du jour',
          icon: Icons.compare_arrows_outlined,
          leftLabel: 'Δ Vol. ambiant',
          leftValue: fmtLitersSigned(b.deltaAmbiant),
          rightLabel: 'Δ Vol. 15 °C',
          rightValue: fmtLitersSigned(b.delta15c),
          leftAccent: tint(b.deltaAmbiant),
          rightAccent: tint(b.delta15c),
          onTap: () => context.go('/stocks'),
        );
      },
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error:  (_, __) => const SizedBox(height: 120, child: Center(child: Text('Balance indisponible'))),
    );

    // --- KPI 3: Stock total (actuel)
    final stkParam   = ref.watch(stocksDefaultParamProvider);
    final stkState   = ref.watch(stocksTotalsProvider(stkParam));

    final kpiStocks = stkState.when(
      data: (s) => KpiSplitCard(
        title: 'Stock total (actuel)',
        icon: Icons.inventory_2_outlined,
        leftLabel: 'Vol. ambiant',
        leftValue: fmtLiters(s.totalAmbiant),
        rightLabel: 'Vol. 15 °C',
        rightValue: fmtLiters(s.total15c),
        leftSubLabel: s.lastDay != null ? 'MAJ' : null,
        leftSubValue: s.lastDay != null ? fmtShortDate(s.lastDay!) : null,
        onTap: () => context.go('/stocks'),
      ),
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error:  (_, __) => const SizedBox(height: 120, child: Center(child: Text('Stocks indisponibles'))),
    );

    // --- Mise en page (sobre, scalable)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        kpiCamions,
        const SizedBox(height: 16),
        const CdrKpiTiles(),
        const SizedBox(height: 16),
        kpiReceptions,
        const SizedBox(height: 16),
        kpiSorties,
        const SizedBox(height: 16),
        kpiBalance,
        const SizedBox(height: 16),
        kpiStocks,
      ],
    );
  }
}
