import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/citerne_providers.dart';

class CiterneListScreen extends ConsumerWidget {
  const CiterneListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citernes = ref.watch(citernesWithStockProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Citernes')),
      body: citernes.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('Aucune citerne active'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = items[i];
              return ListTile(
                title: Text(c.nom),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: c.ratioFill),
                    const SizedBox(height: 4),
                    Text('Stock: ${c.stockAmbiant.toStringAsFixed(0)} L  •  Capacité: ${c.capaciteTotale.toStringAsFixed(0)} L  •  Sécurité: ${c.capaciteSecurite.toStringAsFixed(0)} L'),
                  ],
                ),
                trailing: c.belowSecurity ? const Icon(Icons.warning, color: Colors.red) : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

