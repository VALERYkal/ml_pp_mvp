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
import 'role_depot_chips.dart';

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

/// Shell responsive pour le dashboard
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final profil = ref
        .watch(profilProvider)
        .maybeWhen(data: (p) => p, orElse: () => null);

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
        // Breakpoints MVP responsive
        final isMobile = constraints.maxWidth < 600;  // Mobile: < 600px
        final isWide = constraints.maxWidth >= 1000;  // Desktop large: >= 1000px

        // NavigationRail pour desktop
        final rail = NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) =>
              context.go(effectivePath(items[i], role)),
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
          onDestinationSelected: (i) =>
              context.go(effectivePath(items[i], role)),
          destinations: [
            for (final item in items)
              NavigationDestination(icon: Icon(item.icon), label: item.title),
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

        // Handlers pour refresh et logout (réutilisables)
        void onRefresh() {
          ref.invalidate(refDataProvider);
          ref.invalidate(kpiProviderProvider);
          debugPrint(
            '🔄 Dashboard: manual refresh -> invalidate kpiProviderProvider',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Données rafraîchies')),
          );
        }

        Future<void> onLogout() async {
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) {
            context.go('/login');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Déconnecté')),
            );
          }
        }

        final shell = Scaffold(
          appBar: AppBar(
            title: const _DashboardTitle(),
            centerTitle: false,
            
            // Actions selon breakpoint :
            // - Mobile (< 600px) : refresh + logout (icônes compactes)
            // - Tablet/Desktop (>= 600px) : refresh + chips + logout
            actions: isMobile
                ? [
                    // Mobile : actions compactes (icônes uniquement)
                    IconButton(
                      tooltip: 'Rafraîchir',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: 'Déconnexion',
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout),
                    ),
                  ]
                : [
                    // Tablet/Desktop : tout dans actions
                    IconButton(
                      tooltip: 'Rafraîchir',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 4),
                    RoleDepotChips(role: safeRole, depotName: depotLabel),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Déconnexion',
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
            
            // Bottom bar uniquement sur mobile : chips avec scroll horizontal
            bottom: isMobile
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RoleDepotChips(
                              role: safeRole,
                              depotName: depotLabel,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : null, // Tablet/Desktop : pas de bottom bar
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
