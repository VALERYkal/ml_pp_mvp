import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profil/providers/profil_provider.dart';
import '../../core/models/user_role.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<UserRole?>(userRoleProvider, (prev, next) {
      if (next != null && context.mounted) {
        context.go(next.dashboardPath);
      }
    });

    return const Scaffold(
      body: Center(child: SizedBox(height: 72, width: 72, child: CircularProgressIndicator())),
    );
  }
}
