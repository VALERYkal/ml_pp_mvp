// 📌 Module : Stocks Adjustments - Widgets
// 🧭 Description : Badge "STOCK CORRIGÉ" standardisé pour indiquer la présence d'ajustements
// B4.4 - Source unique de vérité, signal métier cohérent

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/has_adjustments_provider.dart';

/// Badge standardisé "Corrigé" à afficher sur les écrans de stock
///
/// B4.4 - Composant unique standardisé pour signaler qu'un stock inclut des ajustements manuels.
/// Utilisé partout où le stock est affiché (citerne, stock total, stock par propriétaire, KPI dashboard).
///
/// Usage :
/// ```dart
/// StockCorrectedBadge(
///   depotId: depotId,
///   // ou citerneId: citerneId,
/// )
/// ```
class StockCorrectedBadge extends ConsumerWidget {
  final String? depotId;
  final String? citerneId;

  // ⚠️ Ne pas utiliser const : dépend de valeurs runtime (depotId, citerneId)
  StockCorrectedBadge({
    super.key,
    this.depotId,
    this.citerneId,
  }) : assert(
          (depotId != null && depotId.isNotEmpty) ||
              (citerneId != null && citerneId.isNotEmpty),
          'Either depotId or citerneId must be provided',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // B4.4-A : Source unique de vérité - Utiliser le provider approprié selon ce qui est fourni
    final hasAdjustmentsAsync = depotId != null && depotId!.isNotEmpty
        ? ref.watch(hasDepotAdjustmentsProvider(depotId!))
        : ref.watch(hasCiterneAdjustmentsProvider(citerneId!));

    return hasAdjustmentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hasAdjustments) {
        if (!hasAdjustments) return const SizedBox.shrink();

        // B4.4-C : Badge standardisé avec tooltip EXACT
        return Tooltip(
          message: 'Ce stock inclut un ou plusieurs ajustements manuels.',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 4),
                Text(
                  'Corrigé',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Alias pour compatibilité avec le code existant (B4.2)
/// @deprecated Utiliser StockCorrectedBadge à la place
@Deprecated('Use StockCorrectedBadge instead')
typedef StockCorrigeBadge = StockCorrectedBadge;
