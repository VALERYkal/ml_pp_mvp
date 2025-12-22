import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signal global: incrémenter ce compteur force un refresh KPI dashboard.
/// But: garantir que le dashboard se refresh même sous ShellRoute/navigation.
final kpiRefreshSignalProvider = StateProvider<int>((ref) => 0);

void triggerKpiRefresh(WidgetRef ref) {
  ref.read(kpiRefreshSignalProvider.notifier).state++;
}

