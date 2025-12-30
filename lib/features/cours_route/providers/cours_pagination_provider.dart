// 📌 Module : Cours de Route - Providers
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Provider pour la pagination des cours de route

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';

/// Configuration de pagination
class CoursPaginationConfig {
  final int pageSize;
  final int currentPage;
  final bool hasMore;

  const CoursPaginationConfig({
    this.pageSize = 20,
    this.currentPage = 1,
    this.hasMore = true,
  });

  CoursPaginationConfig copyWith({
    int? pageSize,
    int? currentPage,
    bool? hasMore,
  }) {
    return CoursPaginationConfig(
      pageSize: pageSize ?? this.pageSize,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoursPaginationConfig &&
        other.pageSize == pageSize &&
        other.currentPage == currentPage &&
        other.hasMore == hasMore;
  }

  @override
  int get hashCode =>
      pageSize.hashCode ^ currentPage.hashCode ^ hasMore.hashCode;

  @override
  String toString() =>
      'CoursPaginationConfig(pageSize: $pageSize, currentPage: $currentPage, hasMore: $hasMore)';
}

/// Provider pour la configuration de pagination
final coursPaginationProvider = StateProvider<CoursPaginationConfig>((ref) {
  return const CoursPaginationConfig(
    pageSize: 1000, // Afficher toutes les données sur une seule page
    currentPage: 1,
    hasMore: false,
  );
});

/// Fonction de pagination des cours
List<CoursDeRoute> paginateCours(
  List<CoursDeRoute> cours,
  CoursPaginationConfig config,
) {
  final startIndex = (config.currentPage - 1) * config.pageSize;
  final endIndex = startIndex + config.pageSize;

  if (startIndex >= cours.length) {
    return [];
  }

  return cours.sublist(
    startIndex,
    endIndex > cours.length ? cours.length : endIndex,
  );
}

/// Provider pour la liste paginée des cours de route
final paginatedCoursProvider = Provider<List<CoursDeRoute>>((ref) {
  final cours = ref.watch(filteredCoursProvider);
  final pagination = ref.watch(coursPaginationProvider);

  return paginateCours(cours, pagination);
});

/// Provider pour vérifier s'il y a plus de pages
final hasMorePagesProvider = Provider<bool>((ref) {
  final cours = ref.watch(filteredCoursProvider);
  final pagination = ref.watch(coursPaginationProvider);

  final totalPages = (cours.length / pagination.pageSize).ceil();
  return pagination.currentPage < totalPages;
});

/// Provider pour le nombre total de pages
final totalPagesProvider = Provider<int>((ref) {
  final cours = ref.watch(filteredCoursProvider);
  final pagination = ref.watch(coursPaginationProvider);

  return (cours.length / pagination.pageSize).ceil();
});

/// Provider pour le nombre total d'éléments
final totalItemsProvider = Provider<int>((ref) {
  final cours = ref.watch(filteredCoursProvider);
  return cours.length;
});

/// Provider pour les informations de pagination
final paginationInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final cours = ref.watch(filteredCoursProvider);
  final pagination = ref.watch(coursPaginationProvider);
  final totalPages = ref.watch(totalPagesProvider);
  final hasMore = ref.watch(hasMorePagesProvider);

  final startItem = (pagination.currentPage - 1) * pagination.pageSize + 1;
  final endItem = pagination.currentPage * pagination.pageSize;
  final actualEndItem = endItem > cours.length ? cours.length : endItem;

  return {
    'currentPage': pagination.currentPage,
    'totalPages': totalPages,
    'pageSize': pagination.pageSize,
    'totalItems': cours.length,
    'startItem': startItem,
    'endItem': actualEndItem,
    'hasMore': hasMore,
  };
});
