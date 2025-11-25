import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/dashboard_shell.dart';

@Deprecated('Use DashboardShell instead')
class RoleShellScaffold extends ConsumerWidget {
  final Widget child;
  const RoleShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardShell(child: child);
  }
}




