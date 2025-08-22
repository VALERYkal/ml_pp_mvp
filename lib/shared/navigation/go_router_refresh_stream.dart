// lib/shared/navigation/go_router_refresh_stream.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Notifier léger pour rafraîchir GoRouter sur événements d'un Stream.
/// Exemple d'usage (à l'étape suivante dans app_router.dart) :
///   final refreshListenable = GoRouterRefreshStream(authStream);
///   GoRouter(refreshListenable: refreshListenable, ...);
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Sécuriser avec un broadcast pour multiples listeners (router + autres).
    _subscription = stream.asBroadcastStream().listen((_) {
      // Chaque événement (login/logout/refresh) déclenche un refresh de GoRouter.
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
