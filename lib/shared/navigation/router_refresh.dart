// lib/shared/navigation/router_refresh.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../providers/session_provider.dart';
import '../../features/profil/providers/profil_provider.dart';
import '../../core/models/user_role.dart';

/// Composite: réveille GoRouter à la fois sur événements d'auth
/// ET quand le rôle utilisateur change (null -> UserRole).
class GoRouterCompositeRefresh extends ChangeNotifier {
  GoRouterCompositeRefresh({required Ref ref, required Stream<dynamic> authStream}) {
    _sub = authStream.asBroadcastStream().listen((event) {
      debugPrint('🔄 GoRouterCompositeRefresh: auth event received -> notifyListeners()');
      notifyListeners();
    });

    // Réveille aussi le router quand le rôle devient disponible
    // (évite de dépendre d'un nouvel event d'auth qui n'arrive jamais).
    _roleSub = ref.listen<UserRole?>(userRoleProvider, (prev, next) {
      debugPrint('🔄 GoRouterCompositeRefresh: role changed $prev -> $next -> notifyListeners()');
      if (prev != next) notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _sub;
  late final ProviderSubscription<UserRole?> _roleSub;

  @override
  void dispose() {
    _sub.cancel();
    _roleSub.close();
    super.dispose();
  }
}

final goRouterRefreshProvider = Provider<GoRouterCompositeRefresh>((ref) {
  final authAsync = ref.watch(appAuthStateProvider); // AsyncValue<AppAuthState>

  final authStream = authAsync.when(
    data: (a) => a.authStream,
    loading: () => Supabase.instance.client.auth.onAuthStateChange,
    error: (_, __) => Supabase.instance.client.auth.onAuthStateChange,
  );

  final refresh = GoRouterCompositeRefresh(ref: ref, authStream: authStream);
  ref.onDispose(refresh.dispose);
  return refresh;
});
