// 📌 Module : Cours de Route - Providers
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🧭 Description : Providers Riverpod pour la gestion des cours de route

import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

// Provider: liste des CDR au statut ARRIVE (les seuls sélectionnables pour une réception)
final coursDeRouteArrivesProvider = Riverpod.FutureProvider.autoDispose<List<CoursDeRoute>>((ref) async {
  final supa = Supabase.instance.client;
  final rows = await supa
      .from('cours_de_route')
      .select('id, produit_id, date_chargement, depart_pays, fournisseur_id, plaque_camion, plaque_remorque, transporteur, chauffeur_nom, volume, statut, created_at')
      .eq('statut', 'ARRIVE')
      .order('created_at', ascending: false);
  return (rows as List)
      .map((e) => e as Map<String, dynamic>)
      .map<CoursDeRoute>(CoursDeRoute.fromMap)
      .toList();
});

/// Provider pour le service CoursDeRouteService
/// 
/// Fournit une instance du service injectée avec le client Supabase.
/// Utilisé par tous les autres providers pour accéder aux données.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final service = ref.read(coursDeRouteServiceProvider);
/// ```
final coursDeRouteServiceProvider = Riverpod.Provider<CoursDeRouteService>((ref) {
  return CoursDeRouteService.withClient(Supabase.instance.client);
});

/// Provider pour la liste de tous les cours de route
/// 
/// Récupère automatiquement tous les cours de route depuis Supabase.
/// Gère les états : loading, error, success.
/// 
/// Utilisé pour :
/// - Afficher la liste complète des cours
/// - Rafraîchir les données après modification
/// 
/// Exemple d'utilisation :
/// ```dart
/// final coursAsync = ref.watch(coursDeRouteListProvider);
/// ```
final coursDeRouteListProvider = Riverpod.FutureProvider<List<CoursDeRoute>>((ref) async {
  final service = ref.read(coursDeRouteServiceProvider);
  return await service.getAll();
});

/// Provider pour la liste des cours de route actifs (non déchargés)
/// 
/// Filtre automatiquement les cours qui ne sont pas au statut "decharge".
/// Utilisé pour afficher uniquement les cours en cours.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final coursActifsAsync = ref.watch(coursDeRouteActifsProvider);
/// ```
final coursDeRouteActifsProvider = Riverpod.FutureProvider<List<CoursDeRoute>>((ref) async {
  final service = ref.read(coursDeRouteServiceProvider);
  return await service.getActifs();
});

/// Provider pour créer un nouveau cours de route
/// 
/// Gère l'état de l'opération de création.
/// Utilisé dans les formulaires de création.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final createState = ref.watch(createCoursDeRouteProvider);
/// ```
final createCoursDeRouteProvider = Riverpod.FutureProvider.family<void, CoursDeRoute>((ref, cours) async {
  final service = ref.read(coursDeRouteServiceProvider);
  await service.create(cours);
  
  // Invalider les providers de liste pour rafraîchir les données
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(coursDeRouteActifsProvider);
});

/// Provider pour mettre à jour un cours de route
/// 
/// Gère l'état de l'opération de mise à jour.
/// Utilisé dans les formulaires de modification.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final updateState = ref.watch(updateCoursDeRouteProvider(cours));
/// ```
final updateCoursDeRouteProvider = Riverpod.FutureProvider.family<void, CoursDeRoute>((ref, cours) async {
  final service = ref.read(coursDeRouteServiceProvider);
  await service.update(cours);
  
  // Invalider les providers de liste pour rafraîchir les données
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(coursDeRouteActifsProvider);
});

/// Provider pour supprimer un cours de route
/// 
/// Gère l'état de l'opération de suppression.
/// Utilisé dans les écrans de détail.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final deleteState = ref.watch(deleteCoursDeRouteProvider('uuid-123'));
/// ```
final deleteCoursDeRouteProvider = Riverpod.FutureProvider.family<void, String>((ref, id) async {
  final service = ref.read(coursDeRouteServiceProvider);
  await service.delete(id);
  
  // Invalider les providers de liste pour rafraîchir les données
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(coursDeRouteActifsProvider);
});

/// Provider pour mettre à jour le statut d'un cours de route
/// 
/// Gère l'état de l'opération de changement de statut.
/// Utilisé pour faire progresser un cours vers le statut suivant.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final updateStatutState = ref.watch(updateStatutCoursDeRouteProvider(
///   id: 'uuid-123',
///   to: StatutCours.transit,
/// ));
/// ```
final updateStatutCoursDeRouteProvider = Riverpod.FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(coursDeRouteServiceProvider);
  final id = params['id'] as String;
  final to = params['to'] as StatutCours;
  final fromReception = params['fromReception'] as bool? ?? false;
  
  await service.updateStatut(id: id, to: to, fromReception: fromReception);
  
  // Invalider les providers de liste pour rafraîchir les données
  ref.invalidate(coursDeRouteListProvider);
  ref.invalidate(coursDeRouteActifsProvider);
});

/// Provider pour récupérer un cours de route par ID
/// 
/// Récupère un cours spécifique par son identifiant.
/// Utilisé dans les écrans de détail.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final coursAsync = ref.watch(coursDeRouteByIdProvider('uuid-123'));
/// ```
final coursDeRouteByIdProvider = Riverpod.FutureProvider.family<CoursDeRoute?, String>((ref, id) async {
  final service = ref.read(coursDeRouteServiceProvider);
  return await service.getById(id);
});

/// Provider pour récupérer les cours de route par statut
/// 
/// Filtre les cours selon un statut spécifique.
/// Utilisé pour afficher les cours par étape de progression.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final coursEnTransit = ref.watch(coursDeRouteByStatutProvider(StatutCours.transit));
/// ```
final coursDeRouteByStatutProvider = Riverpod.FutureProvider.family<List<CoursDeRoute>, StatutCours>((ref, statut) async {
  final service = ref.read(coursDeRouteServiceProvider);
  return await service.getByStatut(statut);
});

/// Notifier pour gérer l'état de filtrage des cours de route
/// 
/// Permet de filtrer dynamiquement les cours selon différents critères.
/// Utilisé dans les écrans de liste pour appliquer des filtres.
class CoursDeRouteFilterNotifier extends Riverpod.StateNotifier<Map<String, dynamic>> {
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
  
  /// Afficher uniquement les cours actifs (non déchargés)
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
final coursDeRouteFilterProvider = Riverpod.StateNotifierProvider<CoursDeRouteFilterNotifier, Map<String, dynamic>>((ref) {
  return CoursDeRouteFilterNotifier();
});
