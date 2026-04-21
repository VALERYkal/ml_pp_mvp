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
    final location = GoRouterState.of(context).uri.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        final isMobile = constraints.maxWidth < 600;

        // Filtrer les items pour mobile BottomNav (exclure Logs, Ajustements, Integrity)
        final mobileItems = items.where((item) {
          return item.id != 'logs' &&
              item.id != 'stocks-adjustments' &&
              item.id != 'integrity';
        }).toList();

        // Items pour desktop (tous les items)
        final desktopItems = items;

        // Sélectionner les items selon le breakpoint
        final effectiveItems = isMobile ? mobileItems : desktopItems;

        // Recalculer l'index sélectionné avec les items filtrés
        final effectiveSelectedIndex = _selectedIndexFor(
          location,
          effectiveItems,
          role,
        );

        // Menu custom avec sections (desktop/tablet) — remplace NavigationRail
        final navEntries = _buildNavEntries(role, desktopItems);
        final navMenuWidth = isWide ? 260.0 : 220.0;
        final navMenu = SizedBox(
          width: navMenuWidth,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final entry in navEntries)
                if (entry.header != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      entry.header!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  )
                else if (entry.item != null)
                  ListTile(
                    leading: Icon(entry.item!.icon),
                    title: Text(entry.item!.title),
                    selected: _isSelected(location, entry.item!, role),
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    onTap: () =>
                        context.go(effectivePath(entry.item!, role)),
                  ),
            ],
          ),
        );

        // BottomNavigationBar pour mobile (4-5 items max)
        final bottom = NavigationBar(
          selectedIndex: effectiveSelectedIndex,
          onDestinationSelected: (i) =>
              context.go(effectivePath(effectiveItems[i], role)),
          destinations: [
            for (final item in effectiveItems)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon),
                label: item.title,
              ),
          ],
        );

        // Drawer pour mobile — même structure sections que le menu desktop
        final drawerEntries = _buildNavEntries(role, items);
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
              for (final entry in drawerEntries)
                if (entry.header != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      entry.header!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  )
                else if (entry.item != null)
                  ListTile(
                    leading: Icon(entry.item!.icon),
                    title: Text(entry.item!.title),
                    selected: _isSelected(location, entry.item!, role),
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(effectivePath(entry.item!, role));
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
                  debugPrint(
                    '🔄 Dashboard: manual refresh -> invalidate kpiProviderProvider',
                  );
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Déconnecté')));
                  }
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Row(
            children: [
              if (!isMobile) navMenu,
              if (!isMobile) const VerticalDivider(width: 1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile ? bottom : null,
          drawer: isMobile ? drawer : null,
        );

        if (kDebugMode) {
          return HotReloadInvalidator(
            providersToInvalidate: [
              currentProfilProvider,
              userRoleProvider,
              kpiProviderProvider,
              stocksTotalsProvider,
              receptionsKpiProvider,
              sortiesKpiProvider,
              camionsASuivreProvider,
            ],
            child: shell,
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

/// Entrée du menu : header de section ou item de navigation
class _NavEntry {
  final String? header;
  final NavItem? item;

  const _NavEntry.header(this.header) : item = null;
  const _NavEntry.item(this.item) : header = null;
}

/// Ordre canonique des ids (sans dashboard en début car géré à part)
const _opsIds = ['receptions', 'sorties', 'cours'];
const _financeIds = ['finance-factures-lot'];
const _stockIds = ['stocks', 'citernes', 'stocks-adjustments'];
const _govIds = ['logs', 'integrity'];

bool _isGovernanceRole(UserRole? role) =>
    role != null &&
    (role == UserRole.admin || role == UserRole.directeur || role == UserRole.pca);

/// Construit la liste ordonnée des entrées menu (headers + items) à afficher.
List<_NavEntry> _buildNavEntries(UserRole? role, List<NavItem> items) {
  final byId = {for (final it in items) it.id: it};
  final entries = <_NavEntry>[];

  // Accueil
  final dashboard = byId['dashboard'];
  if (dashboard != null) {
    entries.add(_NavEntry.item(dashboard));
  }

  // OPÉRATIONS
  entries.add(const _NavEntry.header('OPÉRATIONS'));
  for (final id in _opsIds) {
    final it = byId[id];
    if (it != null) entries.add(_NavEntry.item(it));
  }

  // FINANCE
  entries.add(const _NavEntry.header('FINANCE'));
  for (final id in _financeIds) {
    final it = byId[id];
    if (it != null) entries.add(_NavEntry.item(it));
  }

  // Gestion de stock
  entries.add(const _NavEntry.header('Gestion de stock'));
  for (final id in _stockIds) {
    final it = byId[id];
    if (it != null) entries.add(_NavEntry.item(it));
  }

  // GOUVERNANCE (admin, directeur, pca only)
  if (_isGovernanceRole(role)) {
    entries.add(const _NavEntry.header('GOUVERNANCE'));
    for (final id in _govIds) {
      final it = byId[id];
      if (it != null) entries.add(_NavEntry.item(it));
    }
  }

  return entries;
}

/// Retourne true si la location correspond à l'item
bool _isSelected(String location, NavItem item, UserRole? role) {
  final p = effectivePath(item, role);
  return location == p || location.startsWith('$p/');
}
