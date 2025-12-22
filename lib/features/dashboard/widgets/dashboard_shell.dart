import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/shared/providers/auth_service_provider.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/shared/navigation/nav_config.dart';
import 'package:ml_pp_mvp/features/depots/providers/depots_provider.dart';
import 'package:ml_pp_mvp/shared/dev/hot_reload_hooks.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_providers.dart';

/// Titre dynamique basé sur la route courante
class _DashboardTitle extends ConsumerWidget {
  const _DashboardTitle();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final location = GoRouterState.of(context).uri.toString();
    final title = NavConfig.getPageTitle(location, role);
    return Text(title);
  }
}

/// Chips pour afficher le rôle et le dépôt
class _RoleDepotChips extends StatelessWidget {
  final UserRole role;
  final String depotName;
  
  const _RoleDepotChips({required this.role, required this.depotName});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Chip(
          label: Text(role.value),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        const SizedBox(width: 8),
        InputChip(
          label: Text(depotName),
          avatar: const Icon(Icons.home_work, size: 18),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Shell responsive pour le dashboard
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final profil = ref.watch(profilProvider).maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );
    
    // Warmup des référentiels
    ref.watch(refDataProvider);
    
    // Safe role pour l'UI (fallback vers lecture si null)
    final safeRole = role ?? UserRole.lecture;
    
    final depotNameAsync = ref.watch(currentDepotNameProvider);
    final depotLabel = depotNameAsync.when(
      data: (name) => name ?? '—',
      loading: () => '…',
      error: (_, __) => '—',
    );
    final items = NavConfig.getItemsForRole(role);
    
    // Sélection active depuis la route
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndexFor(location, items, role);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;

        // NavigationRail pour desktop
        final rail = NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.go(effectivePath(items[i], role)),
          extended: isWide,
          destinations: [
            for (final item in items)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon),
                label: Text(item.title),
              ),
          ],
        );

        // BottomNavigationBar pour mobile
        final bottom = NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.go(effectivePath(items[i], role)),
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                label: item.title,
              ),
          ],
        );

        // Drawer pour mobile
        final drawer = Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ML_PP MVP',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rôle: ${safeRole.value}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              for (int i = 0; i < items.length; i++)
                ListTile(
                  leading: Icon(items[i].icon),
                  title: Text(items[i].title),
                  selected: i == selectedIndex,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(effectivePath(items[i], role));
                  },
                ),
            ],
          ),
        );

        final shell = Scaffold(
          appBar: AppBar(
            title: const _DashboardTitle(),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Rafraîchir',
                onPressed: () {
                  ref.invalidate(refDataProvider);
                  ref.invalidate(kpiProviderProvider);
                  debugPrint('🔄 Dashboard: manual refresh -> invalidate kpiProviderProvider');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Données rafraîchies')),
                  );
                },
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              _RoleDepotChips(role: safeRole, depotName: depotLabel),
              IconButton(
                tooltip: 'Déconnexion',
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Déconnecté')),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Row(
            children: [
              if (isWide) rail,
              if (isWide) const VerticalDivider(width: 1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide ? null : bottom,
          drawer: isWide ? null : drawer,
        );

        if (kDebugMode) {
          return HotReloadInvalidator(
            child: shell,
            providersToInvalidate: [
              currentProfilProvider,
              userRoleProvider,
              kpiProviderProvider,
              stocksTotalsProvider,
              receptionsKpiProvider,
              sortiesKpiProvider,
              camionsASuivreProvider,
            ],
          );
        }
        return shell;
      },
    );
  }
}

/// Helper pour calculer l'index sélectionné basé sur la location et les items
int _selectedIndexFor(String location, List<NavItem> items, UserRole? role) {
  for (var i = 0; i < items.length; i++) {
    final p = effectivePath(items[i], role);
    if (location == p || location.startsWith('$p/')) return i;
  }
  return 0;
}
