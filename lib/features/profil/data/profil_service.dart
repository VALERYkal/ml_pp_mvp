// 📌 Module : Profil Feature - Data Layer
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `public.profils`
// 🧭 Description : Service de gestion des profils utilisateur via Supabase

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/profil.dart';

/// Service de gestion des profils utilisateur
///
/// Responsable de toutes les opérations CRUD sur la table `profils`
/// via l'API Supabase. Utilise l'injection de dépendance pour
/// le client Supabase.
///
/// Ce service est utilisé par :
/// - Les providers Riverpod pour la gestion d'état
/// - Les écrans d'authentification et de profil
/// - Les services de validation des permissions
class ProfilService {
  /// Client Supabase injecté via constructeur
  final SupabaseClient _client;

  /// Constructeur avec injection de dépendance
  ///
  /// [client] : Instance du client Supabase
  /// Utilisé pour permettre les tests unitaires
  const ProfilService.withClient(this._client);

  /// Constructeur par défaut utilisant l'instance Supabase globale
  ProfilService() : _client = Supabase.instance.client;

  /// Récupère le profil utilisateur courant
  ///
  /// [userId] : Identifiant de l'utilisateur Supabase Auth
  ///
  /// Retourne :
  /// - `Profil?` : Le profil utilisateur si trouvé
  /// - `null` : Si aucun profil n'existe pour cet utilisateur
  ///
  /// Exceptions possibles :
  /// - `PostgrestException` : Erreur de connexion ou requête
  /// - `AuthException` : Erreur d'authentification
  Future<Profil?> getCurrentProfil(String userId) async {
    try {
      debugPrint('🔍 ProfilService: Recherche du profil pour userId: $userId');

      // Requête Supabase pour récupérer le profil
      final response = await _client.from('profils').select().eq('user_id', userId).maybeSingle();

      if (response == null) {
        debugPrint('⚠️ ProfilService: Aucun profil trouvé pour userId: $userId');
        return null;
      }

      // Conversion des données Supabase vers le modèle Profil
      final profil = Profil.fromJson(response);
      debugPrint('✅ ProfilService: Profil récupéré avec succès - Role: ${profil.role}');

      return profil;
    } on PostgrestException catch (e) {
      debugPrint('❌ ProfilService: Erreur Supabase - ${e.message}');
      rethrow;
    } on AuthException catch (e) {
      debugPrint('❌ ProfilService: Erreur d\'authentification - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ ProfilService: Erreur inattendue - $e');
      rethrow;
    }
  }

  /// Crée un nouveau profil utilisateur
  ///
  /// [profil] : Le profil à créer (sans id)
  ///
  /// Retourne :
  /// - `Profil` : Le profil créé avec l'id généré
  ///
  /// Utilisé lors de l'inscription d'un nouvel utilisateur
  Future<void> createProfil(Profil profil) async {
    try {
      debugPrint('➕ ProfilService: Création d\'un nouveau profil');

      // Préparation des données pour Supabase
      final data = profil.toJson();
      data.remove('id'); // L'id sera généré automatiquement
      data.remove('created_at'); // Le timestamp sera généré automatiquement

      // Insertion dans Supabase
      await _client.from('profils').insert(data).select().single();

      debugPrint('✅ ProfilService: Profil créé avec succès');
    } on PostgrestException catch (e) {
      debugPrint('❌ ProfilService: Erreur lors de la création - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ ProfilService: Erreur inattendue lors de la création - $e');
      rethrow;
    }
  }

  /// Met à jour un profil existant
  ///
  /// [profil] : Le profil avec les nouvelles données
  ///
  /// Utilisé pour modifier les informations du profil
  Future<void> updateProfil(Profil profil) async {
    try {
      debugPrint('🔄 ProfilService: Mise à jour du profil - ID: ${profil.id}');

      // Préparation des données pour Supabase
      final data = profil.toJson();
      data.remove('id'); // L'id ne doit pas être modifié
      data.remove('created_at'); // Le timestamp de création ne doit pas être modifié

      // Mise à jour dans Supabase
      await _client.from('profils').update(data).eq('id', profil.id).select().single();

      debugPrint('✅ ProfilService: Profil mis à jour avec succès');
    } on PostgrestException catch (e) {
      debugPrint('❌ ProfilService: Erreur lors de la mise à jour - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ ProfilService: Erreur inattendue lors de la mise à jour - $e');
      rethrow;
    }
  }

  /// Récupère le profil de l'utilisateur actuellement connecté
  ///
  /// Retourne :
  /// - `Profil?` : Le profil utilisateur si trouvé
  /// - `null` : Si aucun profil n'existe ou si l'utilisateur n'est pas connecté
  Future<Profil?> getByCurrentUser() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final res = await _client
        .from('profils')
        .select<Map<String, dynamic>>()
        .eq('user_id', uid)
        .maybeSingle();

    if (res == null) return null;
    return Profil.fromJson(res);
  }

  /// Crée un profil pour l'utilisateur actuellement connecté
  ///
  /// [role] : Rôle par défaut (ex: 'directeur' ou 'lecture')
  /// [nomComplet] : Nom complet optionnel
  /// [email] : Email optionnel
  /// [depotId] : ID du dépôt optionnel
  ///
  /// Retourne :
  /// - `Profil` : Le profil créé
  ///
  /// Exceptions :
  /// - `StateError` : Si l'utilisateur n'est pas connecté
  Future<Profil> createForCurrentUser({
    required String role, // ex: 'directeur' ou 'lecture'
    String? nomComplet,
    String? email,
    String? depotId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('createForCurrentUser: user_id null');
    }

    // RLS : la policy INSERT autorise INSERT si user_id = auth.uid()
    final payload = {
      'user_id': uid,
      'role': role,
      if (nomComplet != null) 'nom_complet': nomComplet,
      if (email != null) 'email': email,
      if (depotId != null) 'depot_id': depotId,
    };

    final inserted = await _client
        .from('profils')
        .insert(payload)
        .select<Map<String, dynamic>>()
        .single();

    return Profil.fromJson(inserted);
  }

  /// Récupère ou crée un profil pour l'utilisateur actuellement connecté
  ///
  /// [defaultRole] : Rôle par défaut si création nécessaire
  /// [nomComplet] : Nom complet optionnel
  /// [email] : Email optionnel
  /// [depotId] : ID du dépôt optionnel
  ///
  /// Retourne :
  /// - `Profil` : Le profil existant ou nouvellement créé
  ///
  /// Cette méthode est idempotente et RLS-safe
  Future<Profil> getOrCreateByCurrentUser({
    String defaultRole = 'lecture',
    String? nomComplet,
    String? email,
    String? depotId,
  }) async {
    final existing = await getByCurrentUser();
    if (existing != null) return existing;

    return createForCurrentUser(
      role: defaultRole,
      nomComplet: nomComplet,
      email: email,
      depotId: depotId,
    );
  }
}
