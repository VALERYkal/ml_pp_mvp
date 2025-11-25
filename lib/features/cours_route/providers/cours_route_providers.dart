// ð Module : Cours de Route - Providers
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-08-07
// ð§­ Description : Providers Riverpod pour la gestion des cours de route

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/kpi/providers/cours_kpi_provider.dart';

/// Provider: liste des CDR au statut ARRIVE (sÃ©lectionnables pour RÃ©ception)
final coursDeRouteArrivesProvider =
    FutureProvider.autoDispose<List<CoursDeRoute>>((ref) async {
      final service = ref.read(coursDeRouteServiceProvider);
      return await service.getByStatut(StatutCours.arrive);
    });

/// Provider pour le service CoursDeRouteService
///
/// Fournit une instance du service injectÃ©e avec le client Supabase.
/// UtilisÃ© par tous les autres providers pour accÃ©der aux donnÃ©es.
///
/// Exemple d'utilisation :
/// ```dart
/// final service = ref.read(coursDeRouteServiceProvider);
/// ```
final coursDeRouteServiceProvider = Provider<CoursDeRouteService>((ref) {
  return CoursDeRouteService.withClient(Supabase.instance.client);
});

/// Provider pour la liste de tous les cours de route
///
/// RÃ©cupÃ¨re automatiquement tous les cours de route depuis Supabase.
/// GÃ¨re les Ã©tats : loading, error, success.
///
/// UtilisÃ© pour :
/// - Afficher la liste complÃ¨te des cours
/// - RafraÃ®chir les donnÃ©es aprÃ¨s modification
///
/// Exemple d'utilisation :
/// ```dart
/// final coursAsync = ref.watch(coursDeRouteListProvider);
/// ```
final coursDeRouteListProvider = FutureProvider<List<CoursDeRoute>>((
  ref,
) async {
  final service = ref.read(coursDeRouteServiceProvider);
  return await service.getAll();
});

/// Provider pour la liste des cours de route actifs (non dÃ©chargÃ©s)
///
/// Filtre automatiquement les cours qui ne sont pas au statut "decharge".
/// UtilisÃ© pour afficher uniquement les cours en cours.
///
/// Exemple d'utilisation :
/// ```dart
/// final coursActifsAsync = ref.watch(coursDeRouteActifsProvider);
/// ```
final coursDeRouteActifsProvider = FutureProvider<List<CoursDeRoute>>((
  ref,
) async {
  final service = ref.read(coursDeRouteServiceProvider);
  return await service.getActifs();
});

/// Provider pour crÃ©er un nouveau cours de route
///
/// GÃ¨re l'Ã©tat de l'opÃ©ration de crÃ©ation.
/// UtilisÃ© dans les formulaires de crÃ©ation.
///
/// Exemple d'utilisation :
/// ```dart
/// final createState = ref.watch(createCoursDeRouteProvider);
/// ```
final createCoursDeRouteProvider = FutureProvider.family<void, CoursDeRoute>((
  ref,
  cours,
) async {
  final service = ref.read(coursDeRouteServiceProvider);
  await service.create(cours);

  // Invalider les providers de liste pour rafraÃ®chir les donnÃ©es
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(coursDeRouteActifsProvider);

  // Invalider les providers KPI du dashboard pour mise Ã  jour immÃ©diate
  ref.invalidate(coursKpiProvider);
});

/// Provider pour mettre Ã  jour un cours de route
///
/// GÃ¨re l'Ã©tat de l'opÃ©ration de mise Ã  jour.
/// UtilisÃ© dans les formulaires de modification.
///
/// Exemple d'utilisation :
/// ```dart
/// final updateState = ref.watch(updateCoursDeRouteProvider(cours));
/// ```
final updateCoursDeRouteProvider = FutureProvider.family<void, CoursDeRoute>((
  ref,
  cours,
) async {
  final service = ref.read(coursDeRouteServiceProvider);
  await service.update(cours);

  // Invalider les providers de liste pour rafraÃ®chir les donnÃ©es
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(coursDeRouteActifsProvider);

  // Invalider les providers KPI du dashboard pour mise Ã  jour immÃ©diate
  ref.invalidate(coursKpiProvider);
});

/// Provider pour supprimer un cours de route
///
/// GÃ¨re l'Ã©tat de l'opÃ©ration de suppression.
/// UtilisÃ© dans les Ã©crans de dÃ©tail.
///
/// Exemple d'utilisation :
/// ```dart
/// final deleteState = ref.watch(deleteCoursDeRouteProvider('uuid-123'));
/// ```
final deleteCoursDeRouteProvider = FutureProvider.family<void, String>((
  ref,
  id,
) async {
  final service = ref.read(coursDeRouteServiceProvider);
  await service.delete(id);

  // Invalider les providers de liste pour rafraÃ®chir les donnÃ©es
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(coursDeRouteActifsProvider);

  // Invalider les providers KPI du dashboard pour mise Ã  jour immÃ©diate
  ref.invalidate(coursKpiProvider);
});

/// Provider pour mettre Ã  jour le statut d'un cours de route
///
/// GÃ¨re l'Ã©tat de l'opÃ©ration de changement de statut.
/// UtilisÃ© pour faire progresser un cours vers le statut suivant.
///
/// Exemple d'utilisation :
/// ```dart
/// final updateStatutState = ref.watch(updateStatutCoursDeRouteProvider(
///   id: 'uuid-123',
///   to: StatutCours.transit,
/// ));
/// ```
final updateStatutCoursDeRouteProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
      final service = ref.read(coursDeRouteServiceProvider);
      final id = params['id'] as String;
      final to = params['to'] as StatutCours;
      final fromReception = params['fromReception'] as bool? ?? false;

      await service.updateStatut(id: id, to: to, fromReception: fromReception);

      // Invalider les providers de liste pour rafraÃ®chir les donnÃ©es
      ref.invalidate(coursDeRouteListProvider);
      ref.invalidate(coursDeRouteActifsProvider);

      // Invalider les providers KPI du dashboard pour mise Ã  jour immÃ©diate
      ref.invalidate(coursKpiProvider);
    });

/// Provider pour rÃ©cupÃ©rer un cours de route par ID
///
/// RÃ©cupÃ¨re un cours spÃ©cifique par son identifiant.
/// UtilisÃ© dans les Ã©crans de dÃ©tail.
///
/// Exemple d'utilisation :
/// ```dart
/// final coursAsync = ref.watch(coursDeRouteByIdProvider('uuid-123'));
/// ```
final coursDeRouteByIdProvider = FutureProvider.family<CoursDeRoute?, String>((
  ref,
  id,
) async {
  final service = ref.read(coursDeRouteServiceProvider);
  return await service.getById(id);
});

/// Provider pour rÃ©cupÃ©rer les cours de route par statut
///
/// Filtre les cours selon un statut spÃ©cifique.
/// UtilisÃ© pour afficher les cours par Ã©tape de progression.
///
/// Exemple d'utilisation :
/// ```dart
/// final coursEnTransit = ref.watch(coursDeRouteByStatutProvider(StatutCours.transit));
/// ```
final coursDeRouteByStatutProvider =
    FutureProvider.family<List<CoursDeRoute>, StatutCours>((ref, statut) async {
      final service = ref.read(coursDeRouteServiceProvider);
      return await service.getByStatut(statut);
    });

/// Notifier pour gÃ©rer l'Ã©tat de filtrage des cours de route
///
/// Permet de filtrer dynamiquement les cours selon diffÃ©rents critÃ¨res.
/// UtilisÃ© dans les Ã©crans de liste pour appliquer des filtres.
class CoursDeRouteFilterNotifier extends StateNotifier<Map<String, dynamic>> {
  CoursDeRouteFilterNotifier() : super({});

  /// Applique un filtre par statut
  void filterByStatut(StatutCours? statut) {
    if (statut == null) {
      state = {...state}..remove('statut');
    } else {
      state = {...state, 'statut': statut};
    }
  }

  /// Applique un filtre par fournisseur
  void filterByFournisseur(String? fournisseurId) {
    if (fournisseurId == null) {
      state = {...state}..remove('fournisseur_id');
    } else {
      state = {...state, 'fournisseur_id': fournisseurId};
    }
  }

  /// Applique un filtre par produit
  void filterByProduit(String? produitId) {
    if (produitId == null) {
      state = {...state}..remove('produit_id');
    } else {
      state = {...state, 'produit_id': produitId};
    }
  }

  /// Afficher uniquement les cours actifs (non dÃ©chargÃ©s)
  void filterActifs(bool? actifs) {
    if (actifs == null) {
      state = {...state}..remove('actifs');
    } else {
      state = {...state, 'actifs': actifs};
    }
  }

  /// Efface tous les filtres
  void clearFilters() {
    state = {};
  }
}

/// Provider pour le notifier de filtrage
final coursDeRouteFilterProvider =
    StateNotifierProvider<CoursDeRouteFilterNotifier, Map<String, dynamic>>((
      ref,
    ) {
      return CoursDeRouteFilterNotifier();
    });
