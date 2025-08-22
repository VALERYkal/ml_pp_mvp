import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/shared/providers/auth_provider.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Destination de navigation avec visibilité conditionnelle par rôle
class _Dest {
  final String route;
  final String label;
  final IconData icon;
  final bool Function(UserRole) visible;
  
  const _Dest(this.route, this.label, this.icon, this.visible);
}

/// Toutes les destinations disponibles
final _allDests = <_Dest>[
  _Dest('/receptions', 'Réceptions', Icons.call_received, (_) => true),
  _Dest('/sorties', 'Sorties', Icons.call_made, (_) => true),
  _Dest('/stocks', 'Stocks', Icons.inventory_2, (_) => true),
  _Dest('/citernes', 'Citernes', Icons.local_gas_station, (r) => r != UserRole.lecture),
  _Dest('/cours', 'Cours route', Icons.local_shipping, (r) => r != UserRole.lecture),
  _Dest('/logs', 'Logs', Icons.history, (r) => r == UserRole.admin || r == UserRole.directeur),
];

/// Titre dynamique basé sur la route courante
class _DashboardTitle extends ConsumerWidget {
  const _DashboardTitle();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.toString();
    String title = switch (true) {
      _ when loc.startsWith('/receptions') => 'Réceptions',
      _ when loc.startsWith('/sorties') => 'Sorties',
      _ when loc.startsWith('/stocks') => 'Stocks journaliers',
      _ when loc.startsWith('/citernes') => 'Citernes',
      _ when loc.startsWith('/cours') => 'Cours de route',
      _ when loc.startsWith('/logs') => 'Journal des actions',
      _ => 'Tableau de bord',
    };
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
    
    final depotName = profil?.depotId ?? '—';
    final dests = _allDests.where((d) => d.visible(role)).toList();
    
    // Sélection active depuis la route
    final loc = GoRouterState.of(context).uri.toString();
    int selected = dests.indexWhere((d) => loc.startsWith(d.route));
    if (selected < 0) selected = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;

        // NavigationRail pour desktop
        final rail = NavigationRail(
          selectedIndex: selected,
          onDestinationSelected: (i) => context.go(dests[i].route),
          extended: isWide,
          destinations: [
            for (final d in dests)
              NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.icon),
                label: Text(d.label),
              ),
          ],
        );

        // BottomNavigationBar pour mobile
        final bottom = NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => context.go(dests[i].route),
          destinations: [
            for (final d in dests)
              NavigationDestination(
                icon: Icon(d.icon),
                label: d.label,
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
                      'Rôle: ${role.value}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              for (int i = 0; i < dests.length; i++)
                ListTile(
                  leading: Icon(dests[i].icon),
                  title: Text(dests[i].label),
                  selected: i == selected,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(dests[i].route);
                  },
                ),
            ],
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: const _DashboardTitle(),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Rafraîchir',
                onPressed: () {
                  ref.invalidate(refDataProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Données rafraîchies')),
                  );
                },
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              _RoleDepotChips(role: role, depotName: depotName),
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
      },
    );
  }
}


