import 'package:flutter/material.dart';

class ShimmerRow extends StatelessWidget {
  final int count;

  const ShimmerRow({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 16,
    children: List.generate(
      count,
      (_) => Container(
        width: 260,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

class ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorTile(this.message, {super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.error_outline),
    title: Text(message),
    trailing: TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Réessayer'),
    ),
  );
}
