// 📌 Module : Stocks Adjustments - Écran de liste
// 🧭 Description : Affichage lecture seule de la liste des ajustements de stock

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/screens/stocks_adjustment_create_sheet.dart';
import '../models/stock_adjustment.dart';
import '../providers/stocks_adjustments_providers.dart';

/// Item interne pour représenter un mouvement dans la liste
class _MovementItem {
  final String id;
  final String title;
  final String subtitle;
  const _MovementItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class StocksAdjustmentsListScreen extends ConsumerWidget {
  const StocksAdjustmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Guard: attendre que la session Supabase ET le profil soient prêts
    final currentUser = Supabase.instance.client.auth.currentUser;
    final profilAsync = ref.watch(currentProfilProvider);
    
    // Si pas de session, afficher loader
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajustements de stock')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return profilAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Ajustements de stock')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Ajustements de stock')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement du profil',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (profil) {
        if (profil == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ajustements de stock')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        // ✅ seulement ici on watch la liste (session + profil prêts)
        final listState = ref.watch(stocksAdjustmentsListPaginatedProvider);
        final notifier = ref.read(stocksAdjustmentsListPaginatedProvider.notifier);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ajustements de stock'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Rafraîchir',
                onPressed: () => notifier.reload(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Barre de filtres
              _FiltersBar(theme: theme),
              // Liste
              Expanded(
                child: _buildListBody(context, ref, theme, listState, notifier),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(context, ref, theme),
        );
      },
    );
  }

  Widget _buildListBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    dynamic listState,
    dynamic notifier,
  ) {
    if (listState.isLoading && listState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (listState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                listState.error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => notifier.reload(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (listState.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun ajustement.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await notifier.reload();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: listState.items.length + (listState.hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          if (index < listState.items.length - 1) {
            return const Divider(height: 1);
          }
          return const SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          if (index < listState.items.length) {
            final adjustment = listState.items[index];
            return _AdjustmentListItem(
              key: ValueKey(adjustment.id),
              adjustment: adjustment,
              theme: theme,
            );
          }
          // Bouton "Charger plus"
          return _LoadMoreButton(
            isLoading: listState.isLoadingMore,
            hasMore: listState.hasMore,
            onLoadMore: () => notifier.loadMore(),
          );
        },
      ),
    );
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final role = ref.watch(userRoleProvider);
    
    // Afficher le bouton uniquement pour les admins
    if (role != UserRole.admin) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () => _showMovementTypeDialog(context, ref),
      tooltip: 'Créer un ajustement',
      child: const Icon(Icons.add),
    );
  }

  /// Affiche un dialog pour choisir le type de mouvement (RECEPTION ou SORTIE)
  Future<void> _showMovementTypeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Type d\'ajustement'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('RECEPTION'),
            child: const Row(
              children: [
                Icon(Icons.move_to_inbox, color: Colors.green),
                SizedBox(width: 16),
                Text('Ajustement sur Réception'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('SORTIE'),
            child: const Row(
              children: [
                Icon(Icons.outbox, color: Colors.orange),
                SizedBox(width: 16),
                Text('Ajustement sur Sortie'),
              ],
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    
    if (result != null && result.isNotEmpty) {
      await _showMovementPickerDialog(context, ref, type: result);
    }
  }

  /// Charge les 20 mouvements récents (réceptions ou sorties)
  Future<List<_MovementItem>> _fetchRecentMovements(
    WidgetRef ref, {
    required String type,
  }) async {
    try {
      final client = Supabase.instance.client;
      final List<_MovementItem> items = [];

      if (type == 'RECEPTION') {
        final res = await client
            .from('receptions')
            .select('id, date_reception, volume_corrige_15c, produits:produit_id(nom)')
            .order('date_reception', ascending: false)
            .limit(20);

        if (res is List) {
          for (final row in res) {
            final map = row as Map<String, dynamic>;
            final id = map['id'] as String? ?? '';
            final date = map['date_reception'] as String? ?? '';
            final volume = (map['volume_corrige_15c'] as num?)?.toDouble() ?? 0.0;
            final produit = map['produits'] as Map<String, dynamic>?;
            final produitNom = produit?['nom'] as String? ?? 'Produit inconnu';

            items.add(_MovementItem(
              id: id,
              title: 'Réception - $produitNom',
              subtitle: '${date.isNotEmpty ? date.substring(0, 10) : "Date inconnue"} - ${volume.toStringAsFixed(1)} L',
            ));
          }
        }
      } else if (type == 'SORTIE') {
        final res = await client
            .from('sorties_produit')
            .select('id, date_sortie, volume_corrige_15c, produits:produit_id(nom)')
            .order('date_sortie', ascending: false)
            .limit(20);

        if (res is List) {
          for (final row in res) {
            final map = row as Map<String, dynamic>;
            final id = map['id'] as String? ?? '';
            final dateStr = map['date_sortie'] as String? ?? '';
            // date_sortie est un timestamptz, extraire la date
            final date = dateStr.isNotEmpty && dateStr.length >= 10
                ? dateStr.substring(0, 10)
                : 'Date inconnue';
            final volume = (map['volume_corrige_15c'] as num?)?.toDouble() ?? 0.0;
            final produit = map['produits'] as Map<String, dynamic>?;
            final produitNom = produit?['nom'] as String? ?? 'Produit inconnu';

            items.add(_MovementItem(
              id: id,
              title: 'Sortie - $produitNom',
              subtitle: '$date - ${volume.toStringAsFixed(1)} L',
            ));
          }
        }
      }

      return items;
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des mouvements: $e');
      return [];
    }
  }

  /// Affiche un dialog pour sélectionner un mouvement récent
  Future<void> _showMovementPickerDialog(
    BuildContext context,
    WidgetRef ref, {
    required String type,
  }) async {
    final movementsFuture = _fetchRecentMovements(ref, type: type);

    await showDialog<void>(
      context: context,
      builder: (context) => FutureBuilder<List<_MovementItem>>(
        future: movementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              title: Text('Chargement des ${type == 'RECEPTION' ? 'réceptions' : 'sorties'}...'),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Erreur'),
              content: Text('Erreur lors du chargement: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          }

          final movements = snapshot.data ?? [];

          if (movements.isEmpty) {
            return AlertDialog(
              title: Text('Aucun ${type == 'RECEPTION' ? 'réception' : 'sortie'} récent'),
              content: const Text('Aucun mouvement récent disponible.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: Text('Sélectionner une ${type == 'RECEPTION' ? 'réception' : 'sortie'}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: movements.length,
                itemBuilder: (context, index) {
                  final item = movements[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      if (!context.mounted) return;
                      StocksAdjustmentCreateSheet.show(
                        context,
                        mouvementType: type,
                        mouvementId: item.id,
                        onSuccess: () {
                          ref.invalidate(stocksAdjustmentsListProvider);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdjustmentListItem extends ConsumerWidget {
  const _AdjustmentListItem({
    super.key,
    required this.adjustment,
    required this.theme,
  });

  final StockAdjustment adjustment;
  final ThemeData theme;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    // Format court : DD/MM/YYYY HH:mm
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatMouvementId(String id) {
    // Tronquer l'ID pour affichage (8 premiers caractères)
    if (id.length >= 8) {
      return id.substring(0, 8);
    }
    return id;
  }

  String _formatDelta(double delta) {
    if (delta > 0) {
      return '+${delta.toStringAsFixed(2)}';
    }
    return delta.toStringAsFixed(2);
  }

  Color _getMouvementTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'RECEPTION':
        return Colors.green;
      case 'SORTIE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mouvementTypeColor = _getMouvementTypeColor(adjustment.mouvementType);
    
    // B3.1 : Récupérer le profil pour afficher le nom au lieu de l'ID
    final profilsLookup = ref.watch(adjustmentProfilsLookupProvider);
    final profil = profilsLookup.valueOrNull?[adjustment.createdBy];
    final authorName = profil?.nomComplet ?? 
                      profil?.email ?? 
                      _formatMouvementId(adjustment.createdBy);
    
    // B3.2 : Référence réception/sortie avec shortId
    final mouvementShortId = _formatMouvementId(adjustment.mouvementId);
    final mouvementReference = adjustment.mouvementType == 'RECEPTION'
        ? 'Réception #$mouvementShortId'
        : 'Sortie #$mouvementShortId';
    
    // B3.2 : Badge impact +/- (basé sur delta_ambiant)
    final hasPositiveImpact = adjustment.deltaAmbiant > 0;
    final impactColor = hasPositiveImpact ? Colors.green : Colors.red;
    
    // B3.4 : Signal audit visuel (icône ⚠️ si ajustement manuel ou delta > 5%)
    // On considère qu'un ajustement avec abs(delta) > seuil (ex: 5%) ou raison contenant "manuel" est suspect
    final hasLargeDelta = adjustment.deltaAmbiant.abs() > 50; // Seuil simple : > 50L
    final isManualAdjustment = adjustment.reason.toLowerCase().contains('manuel') ||
                               adjustment.reason.toLowerCase().contains('manual');
    final needsAuditSignal = hasLargeDelta || isManualAdjustment;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1 : Badge type + Date + Signal audit (B3.4)
          Row(
            children: [
              // B3.4 : Icône ⚠️ si nécessaire
              if (needsAuditSignal) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
              ],
              // Badge type
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: mouvementTypeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: mouvementTypeColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  adjustment.mouvementType,
                  style: TextStyle(
                    color: mouvementTypeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date formatée (B3.1 : améliorée)
              Text(
                _formatDate(adjustment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // B3.2 : Référence mouvement avec shortId
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mouvementReference,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Ligne 2 : Raison (1-2 lignes max)
          Text(
            adjustment.reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Ligne 3 : Deltas (volumes ajustés) + Badge impact (B3.2) + Auteur (B3.1)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              // B3.2 : Badge impact +/-
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: impactColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: impactColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPositiveImpact ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: impactColor.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasPositiveImpact ? 'Impact +' : 'Impact −',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: impactColor.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _DeltaChip(
                label: 'Ambiant',
                value: _formatDelta(adjustment.deltaAmbiant),
                isPositive: adjustment.deltaAmbiant > 0,
                theme: theme,
              ),
              _DeltaChip(
                label: '15°C',
                value: _formatDelta(adjustment.delta15c),
                isPositive: adjustment.delta15c > 0,
                theme: theme,
              ),
              // B3.1 : Auteur (nom du profil au lieu de l'ID)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: needsAuditSignal ? 'Ajustement manuel – à vérifier' : authorName,
                    child: Text(
                      authorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.label,
    required this.value,
    required this.isPositive,
    required this.theme,
  });

  final String label;
  final String value;
  final bool isPositive;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isPositive ? Colors.green : Colors.red)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// Barre de filtres (type, période, recherche)
class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(stocksAdjustmentsFiltersProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtres Type et Période (ligne 1)
          Row(
            children: [
              // Filtre Type
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: filters.movementType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tous')),
                    DropdownMenuItem(value: 'RECEPTION', child: Text('Réception')),
                    DropdownMenuItem(value: 'SORTIE', child: Text('Sortie')),
                  ],
                  onChanged: (value) {
                    ref.read(stocksAdjustmentsFiltersProvider.notifier).state =
                        filters.copyWith(movementType: value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Filtre Période
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: filters.rangeDays,
                  decoration: const InputDecoration(
                    labelText: 'Période',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tout')),
                    DropdownMenuItem(value: 7, child: Text('7 jours')),
                    DropdownMenuItem(value: 30, child: Text('30 jours')),
                    DropdownMenuItem(value: 90, child: Text('90 jours')),
                  ],
                  onChanged: (value) {
                    ref.read(stocksAdjustmentsFiltersProvider.notifier).state =
                        filters.copyWith(rangeDays: value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Recherche
          TextField(
            key: ValueKey('search_${filters.reasonQuery}'), // Force rebuild si query change
            decoration: InputDecoration(
              labelText: 'Rechercher dans la raison',
              hintText: 'Saisir un mot-clé...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filters.reasonQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(stocksAdjustmentsFiltersProvider.notifier).state =
                            filters.copyWith(reasonQuery: '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            onChanged: (value) {
              ref.read(stocksAdjustmentsFiltersProvider.notifier).state =
                  filters.copyWith(reasonQuery: value);
            },
            onSubmitted: (value) {
              ref.read(stocksAdjustmentsFiltersProvider.notifier).state =
                  filters.copyWith(reasonQuery: value);
            },
          ),
        ],
      ),
    );
  }
}

/// Bouton "Charger plus" pour la pagination
class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
  });

  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Fin de la liste',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Charger plus'),
              ),
      ),
    );
  }
}
