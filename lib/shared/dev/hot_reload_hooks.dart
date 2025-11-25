import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invalidation ciblée de providers après hot reload (Riverpod 3).
class HotReloadHooks {
  final List<ProviderOrFamily> providersToInvalidate;

  const HotReloadHooks({this.providersToInvalidate = const []});

  void onHotReload(WidgetRef ref) {
    for (final provider in providersToInvalidate) {
      ref.invalidate(provider);
    }
  }
}