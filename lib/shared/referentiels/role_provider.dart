/* ===========================================================
   ML_PP MVP  role_provider.dart
   Rôle: exposer le rôle courant ('admin' | 'directeur' | 'gerant' | 'lecture' | 'pca')
   pour adapter l'UI (ex: afficher bouton "Valider").
   ?? DEPRECATED: Utilisez userRoleProvider depuis profil_provider.dart
   =========================================================== */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// @deprecated Use userRoleProvider from profil_provider.dart instead
final legacyUserRoleProvider = FutureProvider<String?>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  final rows = await client
      .from('profils')
      .select('role')
      .eq('user_id', uid)
      .order('created_at', ascending: false)
      .limit(1);
  if (rows is List && rows.isNotEmpty) return rows.first['role'] as String?;
  return null;
});

bool canValidate(String? role) => role == 'admin' || role == 'directeur' || role == 'gerant';




