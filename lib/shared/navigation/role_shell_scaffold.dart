import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/shared/providers/auth_provider.dart';
import 'package:ml_pp_mvp/shared/navigation/menu_providers.dart' as Menu;
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Responsive scaffold that renders a NavigationRail on wide screens
/// and a BottomNavigationBar on narrow screens.
///
/// The items are derived from the current user's role. For now we expose
/// a single entry that points to that role's dashboard to keep navigation
/// simple and predictable. You can extend this to add more tabs per role.
class RoleShellScaffold extends ConsumerWidget {
  const RoleShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final profil = ref.watch(profilProvider).maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );

    // Warmup des référentiels (fournisseurs, produits) après login
    // pour éviter les flashs "—" et les requêtes tardives
    ref.watch(refDataProvider);

    final menu = Menu.menuDestinationsForRoleProvider;
    final destinations = ref.watch(menu(role));
    
    // Sécuriser quand il n'y a aucune destination
    if (destinations.isEmpty) {
      // Rôle temporaire / pas encore chargé : éviter un crash et afficher un placeholder
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location, destinations);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;

        return Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.keyR, control: true): RefreshIntent(),
          },
          child: Actions(
            actions: {
              RefreshIntent: CallbackAction<RefreshIntent>(
                onInvoke: (_) {
                  ref.invalidate(refDataProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Données rafraîchies (Ctrl+R)')),
                  );
                  return null;
                },
              ),
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(_titleFor(location)),
                leading: isWide ? null : Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    tooltip: 'Menu',
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Rafraîchir (Ctrl+R)',
                    onPressed: () {
                      ref.invalidate(refDataProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Données rafraîchies')),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(role.value),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      if (profil?.depotId != null)
                        InputChip(
                          avatar: const Icon(Icons.home_work, size: 18),
                          label: Text(profil!.depotId!),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Se déconnecter',
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        context.go('/login');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Déconnecté')),
                        );
                      }
                    },
                  ),
                ],
              ),

              drawer: isWide ? null : Drawer(
                child: SafeArea(
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
                      for (int i = 0; i < destinations.length; i++)
                        ListTile(
                          leading: Icon(destinations[i].icon),
                          title: Text(destinations[i].label),
                          selected: i == selectedIndex,
                          onTap: () {
                            Navigator.pop(context);
                            context.go(destinations[i].route);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              body: Row(
                children: [
                  if (isWide) NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      final target = destinations[index].route;
                      if (target != location) {
                        context.go(target);
                      }
                    },
                    extended: true,
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  if (isWide) const VerticalDivider(width: 1),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: child,
                    ),
                  ),
                ],
              ),

              // Sur mobile, garde le BottomNav pour les entrées principales ;
              // si tu as plus de 5 onglets, le Drawer complète l'accès au reste.
              bottomNavigationBar: isWide ? null : NavigationBar(
                selectedIndex: selectedIndex.clamp(0, (destinations.length - 1).clamp(0, 4)),
                onDestinationSelected: (index) {
                  final target = destinations[index].route;
                  if (target != location) {
                    context.go(target);
                  }
                },
                destinations: [
                  for (final d in destinations.take(5))
                    NavigationDestination(icon: Icon(d.icon), label: d.label),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Titre dynamique basé sur la route courante
  String _titleFor(String loc) {
    if (loc.startsWith('/receptions')) return 'Réceptions';
    if (loc.startsWith('/sorties')) return 'Sorties';
    if (loc.startsWith('/stocks')) return 'Stocks journaliers';
    if (loc.startsWith('/citernes')) return 'Citernes';
    if (loc.startsWith('/cours')) return 'Cours de route';
    if (loc.startsWith('/logs')) return 'Journal des actions';
    if (loc.startsWith('/dashboard')) return 'Tableau de bord';
    return 'Tableau de bord';
  }

  /// Version robuste de _indexForLocation avec normalisation du chemin
  int _indexForLocation(String location, List<Menu.MenuDestination> destinations) {
    String _norm(String input) {
      final uri = Uri.parse(input);
      var p = uri.path;
      if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
      return p;
    }

    final path = _norm(location);
    final idx = destinations.indexWhere((d) {
      final base = _norm(d.route);
      return path == base || path.startsWith('$base/');
    });
    return idx >= 0 ? idx : 0;
  }
}

/// Intent pour le raccourci clavier Ctrl+R
class RefreshIntent extends Intent {
  const RefreshIntent();
}


