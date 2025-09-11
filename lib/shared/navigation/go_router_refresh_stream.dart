// lib/shared/navigation/go_router_refresh_stream.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Notifie GoRouter à chaque événement d'un Stream (auth, etc.).
/// Idempotent et safe à utiliser comme refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
