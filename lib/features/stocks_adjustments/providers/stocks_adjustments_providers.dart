import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/repositories.dart'
    show supabaseClientProvider;
import 'package:ml_pp_mvp/features/stocks_adjustments/data/stocks_adjustments_service.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/models/stock_adjustment.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/models/stocks_adjustments_filters.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';

final stocksAdjustmentsServiceProvider =
    Provider<StocksAdjustmentsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StocksAdjustmentsService(client);
});

/// Provider pour les filtres (StateProvider simple)
final stocksAdjustmentsFiltersProvider =
    StateProvider.autoDispose<StocksAdjustmentsFilters>((ref) {
  return const StocksAdjustmentsFilters();
});

/// État de la liste paginée
class StocksAdjustmentsListState {
  final List<StockAdjustment> items;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? error;

  const StocksAdjustmentsListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
  });

  StocksAdjustmentsListState copyWith({
    List<StockAdjustment>? items,
    bool? isLoading,
    bool? hasMore,
    bool? isLoadingMore,
    Object? error,
  }) {
    return StocksAdjustmentsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// NotifierProvider pour la liste paginée avec filtres
class StocksAdjustmentsListNotifier
    extends AutoDisposeNotifier<StocksAdjustmentsListState> {
  static const int _pageSize = 50;
  bool _bootstrapped = false;
  bool _disposed = false;

  bool get _alive => !_disposed;

  @override
  StocksAdjustmentsListState build() {
    _disposed = false;

    ref.onDispose(() {
      _disposed = true;
    });

    // 1) Toujours initialiser state IMMEDIATEMENT
    state = const StocksAdjustmentsListState(isLoading: true);

    // Écouter les changements de filtres pour recharger automatiquement
    ref.listen<StocksAdjustmentsFilters>(
      stocksAdjustmentsFiltersProvider,
      (previous, next) {
        // Recharger quand les filtres changent
        if (previous != next) {
          reload();
        }
      },
    );

    // 2) Puis lancer le chargement dans une microtask (après init)
    // Garde un flag pour éviter les double fetch si build() se relance
    if (!_bootstrapped) {
      _bootstrapped = true;
      Future.microtask(() async {
        await _loadPage(0);
      });
    }

    return state;
  }

  Future<void> _loadPage(int offset) async {
    // Guard: vérifier que le notifier est toujours monté
    if (!_alive) return;

    final prev = state;
    final filters = ref.read(stocksAdjustmentsFiltersProvider);
    final service = ref.read(stocksAdjustmentsServiceProvider);

    // Calculer la date "since" si rangeDays est défini
    DateTime? since;
    if (filters.rangeDays != null) {
      since = DateTime.now().subtract(Duration(days: filters.rangeDays!));
    }

    try {
      if (offset == 0) {
        state = prev.copyWith(isLoading: true, error: null);
      } else {
        state = prev.copyWith(isLoadingMore: true);
      }

      final items = await service.list(
        limit: _pageSize,
        movementType: filters.movementType,
        since: since,
        reasonQuery: filters.reasonQuery.isEmpty ? null : filters.reasonQuery,
        offset: offset,
      );

      // Guard: vérifier à nouveau après l'await
      if (!_alive) return;

      final newItems = offset == 0 ? items : [...state.items, ...items];
      final hasMore = items.length == _pageSize;

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        isLoadingMore: false,
        hasMore: hasMore,
        error: null,
      );
    } catch (error) {
      // Guard: vérifier à nouveau après l'erreur
      if (!_alive) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  /// Recharge la liste depuis le début (quand les filtres changent)
  Future<void> reload() async {
    await _loadPage(0);
  }

  /// Charge la page suivante
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _loadPage(state.items.length);
  }
}

/// Provider pour la liste paginée avec filtres
final stocksAdjustmentsListPaginatedProvider =
    AutoDisposeNotifierProvider<StocksAdjustmentsListNotifier,
        StocksAdjustmentsListState>(
  StocksAdjustmentsListNotifier.new,
);

/// Provider pour la liste des ajustements de stock (compatibilité B2.4).
/// Retourne les ajustements triés par date de création (plus récents en premier).
/// @deprecated Utiliser stocksAdjustmentsListPaginatedProvider pour les filtres et pagination
final stocksAdjustmentsListProvider =
    FutureProvider.autoDispose<List<StockAdjustment>>((ref) {
  final service = ref.watch(stocksAdjustmentsServiceProvider);
  return service.list(limit: 50);
});

/// Provider de lookup des profils par user_id (pour afficher les noms des auteurs)
/// B3.1 : Permet d'afficher le nom du profil au lieu de l'ID tronqué
final adjustmentProfilsLookupProvider =
    FutureProvider.autoDispose<Map<String, Profil>>((ref) async {
  // Charger la liste des ajustements pour obtenir les user_ids uniques
  final listState = ref.watch(stocksAdjustmentsListPaginatedProvider);
  
  if (listState.items.isEmpty) {
    return {};
  }

  // Extraire les user_ids uniques des ajustements
  final userIds = listState.items
      .map((adj) => adj.createdBy)
      .toSet()
      .where((id) => id.isNotEmpty)
      .toList();

  if (userIds.isEmpty) {
    return {};
  }

  // Charger tous les profils en une seule requête
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('profils')
        .select()
        .in_('user_id', userIds);

    if (response is! List) {
      return {};
    }

    // Construire un Map user_id -> Profil
    final Map<String, Profil> lookup = {};
    for (final row in response) {
      final profil = Profil.fromJson(row as Map<String, dynamic>);
      if (profil.userId != null) {
        lookup[profil.userId!] = profil;
      }
    }

    return lookup;
  } catch (e) {
    // En cas d'erreur, retourner un map vide (affichage de l'ID en fallback)
    return {};
  }
});
