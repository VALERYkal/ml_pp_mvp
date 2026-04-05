// 📌 Module : Cours de Route - Data Layer
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `public.cours_de_route`
// 🧭 Description : Service de gestion des cours de route avec Supabase

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Service de gestion des cours de route avec Supabase
///
/// Ce service encapsule toutes les opérations CRUD sur la table `cours_de_route`.
/// Il gère la communication avec Supabase, la conversion des données,
/// et la gestion des erreurs.
///
/// Utilisé pour :
/// - Récupérer la liste des cours de route
/// - Créer, modifier, supprimer des cours
/// - Filtrer par statut, fournisseur, etc.
/// - Gérer les erreurs de communication avec Supabase
class CoursDeRouteService {
  /// Client Supabase injecté via le constructeur
  final SupabaseClient _supabase;

  /// Constructeur avec injection du client Supabase
  ///
  /// [client] : Instance du client Supabase configuré
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final service = CoursDeRouteService.withClient(Supabase.instance.client);
  /// ```
  CoursDeRouteService.withClient(this._supabase);

  /// Récupère tous les cours de route
  ///
  /// Retourne :
  /// - `Future<List<CoursDeRoute>>` : Liste de tous les cours de route
  ///
  /// Gestion d'erreur :
  /// - `PostgrestException` : Erreur de communication avec Supabase
  /// - `Exception` : Erreur de conversion des données
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final cours = await service.getAll();
  /// ```
  Future<List<CoursDeRoute>> getAll() async {
    try {
      final List<Map<String, dynamic>> response = await _supabase
          .from('cours_de_route')
          .select<List<Map<String, dynamic>>>('*')
          .order('created_at', ascending: false);

      return response.map((data) {
        // Harmonisation des clés côté UI/modèle
        if (data.containsKey('chauffeur_nom') && data['chauffeur'] == null) {
          data['chauffeur'] = data['chauffeur_nom'];
        }
        if (data.containsKey('depart_pays') && data['pays'] == null) {
          data['pays'] = data['depart_pays'];
        }

        return CoursDeRoute.fromMap(data);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception(
        'Erreur lors de la récupération des cours de route: ${e.message}',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Récupère les cours de route actifs (non déchargés)
  ///
  /// Retourne :
  /// - `Future<List<CoursDeRoute>>` : Liste des cours actifs
  ///
  /// Utilisé pour :
  /// - Afficher les cours en cours dans l'interface
  /// - Filtrer les cours terminés
  // 🚫 PROD-FROZEN: DECHARGE MUST be excluded from active CDRs. Used by coursDeRouteActifsProvider and KPI providers.
  Future<List<CoursDeRoute>> getActifs() async {
    try {
      final List<Map<String, dynamic>> response = await _supabase
          .from('cours_de_route')
          .select<List<Map<String, dynamic>>>('*')
          .neq('statut', StatutCours.decharge.db)
          .order('created_at', ascending: false);

      return response.map((data) {
        // Harmonisation des clés côté UI/modèle
        if (data.containsKey('chauffeur_nom') && data['chauffeur'] == null) {
          data['chauffeur'] = data['chauffeur_nom'];
        }
        if (data.containsKey('depart_pays') && data['pays'] == null) {
          data['pays'] = data['depart_pays'];
        }

        return CoursDeRoute.fromMap(data);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception(
        'Erreur lors de la récupération des cours actifs: ${e.message}',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Récupère un cours de route par son ID
  ///
  /// [id] : Identifiant unique du cours de route
  ///
  /// Retourne :
  /// - `Future<CoursDeRoute?>` : Le cours de route ou null si non trouvé
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final cours = await service.getById('uuid-123');
  /// ```
  Future<CoursDeRoute?> getById(String id) async {
    try {
      final Map<String, dynamic>? response = await _supabase
          .from('cours_de_route')
          .select<Map<String, dynamic>>('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      // Harmonisation des clés côté UI/modèle
      if (response.containsKey('chauffeur_nom') &&
          response['chauffeur'] == null) {
        response['chauffeur'] = response['chauffeur_nom'];
      }
      if (response.containsKey('depart_pays') && response['pays'] == null) {
        response['pays'] = response['depart_pays'];
      }

      return CoursDeRoute.fromMap(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur lors de la récupération du cours: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Crée un nouveau cours de route
  ///
  /// [cours] : Le cours de route à créer
  ///
  /// Retourne :
  /// - `Future<void>` : Succès de l'opération
  ///
  /// Gestion d'erreur :
  /// - `PostgrestException` : Erreur de validation ou contrainte
  /// - `Exception` : Erreur de communication
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final nouveauCours = CoursDeRoute(...);
  /// await service.create(nouveauCours);
  /// ```
  Future<void> create(CoursDeRoute cours) async {
    // Validations de création
    if (cours.fournisseurId.isEmpty ||
        cours.depotDestinationId.isEmpty ||
        cours.produitId.isEmpty) {
      throw ArgumentError(
        'fournisseur, dépôt destination et produit sont requis.',
      );
    }
    if (cours.volume != null && cours.volume! <= 0) {
      throw ArgumentError('volume must be > 0');
    }

    try {
      final payload = {
        'fournisseur_id': cours.fournisseurId,
        'depot_destination_id': cours.depotDestinationId,
        'produit_id': cours.produitId,
        'plaque_camion': cours.plaqueCamion,
        'plaque_remorque': cours.plaqueRemorque,
        'chauffeur_nom': cours.chauffeur,
        'transporteur': cours.transporteur,
        'depart_pays': cours.pays,
        'date_chargement': cours.dateChargement?.toIso8601String().substring(
          0,
          10,
        ),
        'volume': cours.volume,
        'statut': cours.statut.db,
        'note': cours.note,
      };
      debugPrint('🧪 [CDR] about to INSERT cours_de_route');
      debugPrint('🧪 [CDR] payload = ${jsonEncode(payload)}');
      debugPrint('🧪 [CDR] produit_id.runtimeType = ${payload['produit_id']?.runtimeType}');
      debugPrint('🧪 [CDR] produit_id.value = ${payload['produit_id']}');
      await _supabase.from('cours_de_route').insert(payload);
    } on PostgrestException catch (e) {
      throw Exception('Erreur lors de la création du cours: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Met à jour un cours de route existant
  ///
  /// [cours] : Le cours de route avec les nouvelles données
  ///
  /// Retourne :
  /// - `Future<void>` : Succès de l'opération
  ///
  /// Gestion d'erreur :
  /// - `PostgrestException` : Erreur de validation ou contrainte
  /// - `Exception` : Erreur de communication
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final coursModifie = cours.copyWith(statut: StatutCours.transit);
  /// await service.update(coursModifie);
  /// ```
  Future<void> update(CoursDeRoute cours) async {
    // Validations de mise à jour
    if (cours.volume != null && cours.volume! <= 0) {
      throw ArgumentError('volume must be > 0');
    }

    try {
      final payload = {
        'fournisseur_id': cours.fournisseurId,
        'depot_destination_id': cours.depotDestinationId,
        'produit_id': cours.produitId,
        'plaque_camion': cours.plaqueCamion,
        'plaque_remorque': cours.plaqueRemorque,
        'chauffeur_nom': cours.chauffeur,
        'transporteur': cours.transporteur,
        'depart_pays': cours.pays,
        'date_chargement': cours.dateChargement?.toIso8601String().substring(
          0,
          10,
        ),
        'volume': cours.volume,
        'statut': cours.statut.db,
        'note': cours.note,
      };
      await _supabase.from('cours_de_route').update(payload).eq('id', cours.id);
    } on PostgrestException catch (e) {
      throw Exception('Erreur lors de la mise à jour du cours: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Supprime un cours de route
  ///
  /// [id] : Identifiant unique du cours de route à supprimer
  ///
  /// Retourne :
  /// - `Future<void>` : Succès de l'opération
  ///
  /// Gestion d'erreur :
  /// - `PostgrestException` : Erreur de contrainte ou permission
  /// - `Exception` : Erreur de communication
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// await service.delete('uuid-123');
  /// ```
  Future<void> delete(String id) async {
    try {
      await _supabase.from('cours_de_route').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Erreur lors de la suppression du cours: ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Met à jour le statut d'un cours de route avec validation des transitions
  ///
  /// [id] : Identifiant du cours de route
  /// [to] : Nouveau statut à appliquer
  /// [fromReception] : Si la transition vers déchargé provient d'une réception validée
  ///
  /// Retourne :
  /// - `Future<void>` : Succès de l'opération
  ///
  /// Gestion d'erreur :
  /// - `StateError` : Transition non autorisée
  /// - `PostgrestException` : Erreur de communication avec Supabase
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// await service.updateStatut(id: 'uuid-123', to: StatutCours.transit);
  /// await service.updateStatut(id: 'uuid-123', to: StatutCours.decharge, fromReception: true);
  /// ```
  // 🚫 PROD-FROZEN: ARRIVE → DECHARGE transition ONLY via fromReception=true. This is enforced at service level.
  Future<void> updateStatut({
    required String id,
    required StatutCours to,
    bool fromReception = false,
  }) async {
    // Verrou applicatif: DECHARGE uniquement via la validation de Réception
    if (to == StatutCours.decharge && !fromReception) {
      throw StateError(
        'Le passage à DECHARGE se fait via la validation de réception.',
      );
    }

    // Force un retour: lève une erreur si 0 ligne (RLS/ID/condition)
    await _supabase
        .from('cours_de_route')
        .update({'statut': to.db})
        .eq('id', id)
        .select<Map<String, dynamic>>('id')
        .single();
  }

  /// Récupère les cours de route par statut
  ///
  /// [statut] : Statut à filtrer
  ///
  /// Retourne :
  /// - `Future<List<CoursDeRoute>>` : Liste des cours avec le statut spécifié
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final coursEnTransit = await service.getByStatut(StatutCours.transit);
  /// ```
  Future<List<CoursDeRoute>> getByStatut(StatutCours statut) async {
    try {
      final List<Map<String, dynamic>> response = await _supabase
          .from('cours_de_route')
          .select<List<Map<String, dynamic>>>()
          .eq('statut', StatutCoursConverter.toDb(statut))
          .order('created_at', ascending: false);

      return response.map((data) => CoursDeRoute.fromMap(data)).toList();
    } on PostgrestException catch (e) {
      throw Exception(
        'Erreur lors de la récupération par statut: ${e.message}',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Compte les cours de route par statut (utilise les vrais statuts DB)
  ///
  /// Retourne :
  /// - `Future<Map<String, int>>` : Map avec le nombre de cours par statut
  Future<Map<String, int>> countByStatut() async {
    final statuts = [
      'CHARGEMENT',
      'TRANSIT',
      'FRONTIERE',
      'ARRIVE',
      'DECHARGE',
    ];
    final out = <String, int>{};

    for (final statut in statuts) {
      final rows = await _supabase
          .from('cours_de_route')
          .select<List<Map<String, dynamic>>>('id')
          .eq(
            'statut',
            statut,
          ); // ✅ Utilise 'statut' (nom correct de la colonne)
      out[statut] = rows.length;
    }
    return out;
  }

  /// Compte les cours de route par catégorie métier (groupement logique)
  ///
  /// Retourne :
  /// - `Future<Map<String, int>>` : Map avec les catégories métier
  // 🚫 PROD-FROZEN: Category classification is locked. en_route=CHARGEMENT+TRANSIT+FRONTIERE, en_attente=ARRIVE, termines=DECHARGE. Used by KPI providers.
  Future<Map<String, int>> countByCategorie() async {
    final out = <String, int>{};

    // En route (chargement + transit + frontière)
    final enRoute = await _supabase
        .from('cours_de_route')
        .select<List<Map<String, dynamic>>>('id')
        .in_('statut', ['CHARGEMENT', 'TRANSIT', 'FRONTIERE']);
    out['en_route'] = enRoute.length;

    // En attente de déchargement (arrivé)
    final enAttente = await _supabase
        .from('cours_de_route')
        .select<List<Map<String, dynamic>>>('id')
        .eq('statut', 'ARRIVE');
    out['en_attente'] = enAttente.length;

    // Terminés (déchargé)
    final termines = await _supabase
        .from('cours_de_route')
        .select<List<Map<String, dynamic>>>('id')
        .eq('statut', 'DECHARGE');
    out['termines'] = termines.length;

    return out;
  }
}
