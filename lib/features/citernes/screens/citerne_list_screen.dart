import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/citerne_providers.dart';

// Fonctions de formatage
String fmtNum(num? v) => v == null ? '0.0' : v.toDouble().toStringAsFixed(1);
String fmtDate(DateTime? d) =>
    d == null ? '' : '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

class CiterneListScreen extends ConsumerWidget {
  const CiterneListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citernesAsync = ref.watch(citernesWithStockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Citernes')),
      body: citernesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Erreur: $e'),
        data: (rows) {
          if (rows.isEmpty) return const Center(child: Text('Aucune citerne active'));
          
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rows[i];
              final amb = fmtNum(r.stockAmbiant);
              final s15 = fmtNum(r.stock15c);
              final d   = fmtDate(r.dateStock);
              final cap = fmtNum(r.capaciteTotale);
              final sec = fmtNum(r.capaciteSecurite);

              // Triangle rouge basé sur (stock < capacite_sécurité)
              final stockTotal = (r.stock15c ?? r.stockAmbiant ?? 0.0);
              final isBelowSec = r.capaciteSecurite != null && stockTotal < r.capaciteSecurite!;

              return ListTile(
                title: Text(r.nom),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.capaciteTotale != null && r.capaciteTotale! > 0)
                      LinearProgressIndicator(value: r.ratioFill),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: $amb L • $s15 L (15°C)'
                      '${d.isEmpty ? "" : "  •  au $d"}'
                      '  •  Capacité: $cap L  •  Sécurité: $sec L'
                    ),
                  ],
                ),
                trailing: isBelowSec
                    ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
                    : null,
                dense: true,
              );
            },
          );
        },
      ),
    );
  }
}