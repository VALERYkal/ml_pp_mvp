import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncView<T> extends ConsumerWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  const AsyncView({super.key, required this.state, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      data: builder,
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Erreur: $e',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

