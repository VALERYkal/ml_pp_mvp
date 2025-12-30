import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HotReloadInvalidator extends ConsumerStatefulWidget {
  final Widget child;
  final List<ProviderOrFamily> providersToInvalidate;
  final bool showDebugRefreshButton;
  const HotReloadInvalidator({
    super.key,
    required this.child,
    required this.providersToInvalidate,
    this.showDebugRefreshButton = true,
  });
  @override
  ConsumerState<HotReloadInvalidator> createState() =>
      _HotReloadInvalidatorState();
}

class _HotReloadInvalidatorState extends ConsumerState<HotReloadInvalidator> {
  @override
  void reassemble() {
    if (kDebugMode) {
      for (final p in widget.providersToInvalidate) {
        ref.invalidate(p);
      }
      debugPrint(
        '🔄 [HotReloadInvalidator] Providers invalidated after hot reload.',
      );
    }
    super.reassemble();
  }

  void _manualRefresh() {
    for (final p in widget.providersToInvalidate) {
      ref.invalidate(p);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Providers invalidated (debug refresh)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !widget.showDebugRefreshButton) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.surface,
            child: IconButton(
              tooltip: 'Debug refresh',
              onPressed: _manualRefresh,
              icon: const Text('↻', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}
