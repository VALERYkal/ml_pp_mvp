import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/navigation/router_refresh.dart';

import 'package:ml_pp_mvp/features/auth/screens/login_screen.dart';
import 'package:ml_pp_mvp/features/splash/splash_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_form_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_detail_screen.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_list_screen.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_detail_screen.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_form_screen.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_list_screen.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_detail_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_admin_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_directeur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_gerant_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_operateur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_lecture_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_pca_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/dashboard_shell.dart';
import 'package:ml_pp_mvp/features/logs/screens/logs_list_screen.dart';
import 'package:ml_pp_mvp/features/citernes/screens/citerne_list_screen.dart';
import 'package:ml_pp_mvp/features/stocks/screens/stocks_screen.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/screens/stocks_adjustments_list_screen.dart';
import 'package:ml_pp_mvp/features/fournisseurs/presentation/screens/fournisseurs_list_screen.dart';
import 'package:ml_pp_mvp/features/fournisseurs/presentation/screens/fournisseur_detail_screen.dart';
import 'package:ml_pp_mvp/shared/navigation/nav_config.dart';

// Default home page for authenticated users
const String kDefaultHome = '/receptions';

// Compile-time flag to enable dev routes (disabled by default for CI/production)
const bool kEnableDevRoutes =
    bool.fromEnvironment('ENABLE_DEV_ROUTES', defaultValue: false);

// Internal placeholder widget for dev routes when disabled
class _DevPlaceholderScreen extends StatelessWidget {
  const _DevPlaceholderScreen({required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Route'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.developer_mode, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Dev route "$routeName" is disabled',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enable with --dart-define=ENABLE_DEV_ROUTES=true',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // ⚠️ CORRECTIF : Utiliser le refresh composite (auth + rôle)
  final refresh = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: refresh, // 👈 composite (auth + rôle)
    routes: [
      // Routes publiques (inchangées)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (ctx, st) => const LoginScreen(),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (ctx, st) => const SplashScreen(),
      ),

      // Route dev pour purge de cache (only enabled with ENABLE_DEV_ROUTES flag)
      if (kEnableDevRoutes)
        GoRoute(
          path: '/dev/cache-reset',
          name: 'dev-cache-reset',
          builder: (ctx, st) =>
              const _DevPlaceholderScreen(routeName: 'dev-cache-reset'),
        ),

      // === SHELL UNIFIÉ : Toutes les routes protégées ===
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          // Dashboards par rôle
          GoRoute(
            path: '/dashboard/admin',
            builder: (ctx, st) => const DashboardAdminScreen(),
          ),
          GoRoute(
            path: '/dashboard/directeur',
            builder: (ctx, st) => const DashboardDirecteurScreen(),
          ),
          GoRoute(
            path: '/dashboard/gerant',
            builder: (ctx, st) => const DashboardGerantScreen(),
          ),
          GoRoute(
            path: '/dashboard/operateur',
            builder: (ctx, st) => const DashboardOperateurScreen(),
          ),
          GoRoute(
            path: '/dashboard/pca',
            builder: (ctx, st) => const DashboardPcaScreen(),
          ),
          GoRoute(
            path: '/dashboard/lecture',
            builder: (ctx, st) => const DashboardLectureScreen(),
          ),

          // Route générique dashboard (redirigée par le redirect global)
          GoRoute(
            path: '/dashboard',
            builder: (ctx, st) => const SplashScreen(),
          ),

          // Modules fonctionnels
          GoRoute(
            path: '/cours',
            builder: (ctx, st) => const CoursRouteListScreen(),
          ),
          GoRoute(
            path: '/cours/new',
            builder: (ctx, st) => const CoursRouteFormScreen(),
          ),
          GoRoute(
            path: '/cours/:id',
            builder: (ctx, st) =>
                CoursRouteDetailScreen(coursId: st.pathParameters['id']!),
          ),
          GoRoute(
            path: '/cours/:id/edit',
            builder: (ctx, st) =>
                CoursRouteFormScreen(coursId: st.pathParameters['id']),
          ),

          GoRoute(
            path: '/receptions',
            name: 'receptionsList',
            builder: (ctx, st) => const ReceptionListScreen(),
          ),
          GoRoute(
            path: '/receptions/new',
            name: 'receptionsNew',
            builder: (ctx, st) {
              final coursId = st.uri.queryParameters['coursId'];
              return ReceptionFormScreen(coursDeRouteId: coursId);
            },
          ),
          GoRoute(
            path: '/receptions/:id',
            name: 'receptionDetail',
            builder: (ctx, st) {
              final id = st.pathParameters['id']!;
              return ReceptionDetailScreen(receptionId: id);
            },
          ),

          GoRoute(
            path: '/sorties',
            builder: (ctx, st) => const SortieListScreen(),
          ),
          GoRoute(
            path: '/sorties/new',
            builder: (ctx, st) => const SortieFormScreen(),
          ),
          GoRoute(
            path: '/sorties/:id',
            name: 'sortieDetail',
            builder: (ctx, st) {
              final id = st.pathParameters['id']!;
              return SortieDetailScreen(sortieId: id);
            },
          ),

          GoRoute(
            path: '/citernes',
            builder: (ctx, st) => const CiterneListScreen(),
          ),
          GoRoute(path: '/stocks', builder: (ctx, st) => const StocksScreen()),
          GoRoute(
            path: '/fournisseurs',
            builder: (ctx, st) => const FournisseursListScreen(),
          ),
          GoRoute(
            path: '/fournisseurs/:id',
            builder: (ctx, st) {
              final id = st.pathParameters['id']!;
              return FournisseurDetailScreen(fournisseurId: id);
            },
          ),
          GoRoute(path: '/logs', builder: (ctx, st) => const LogsListScreen()),
          GoRoute(
            path: '/stocks-adjustments',
            name: 'stocksAdjustments',
            builder: (ctx, st) => const StocksAdjustmentsListScreen(),
          ),
        ],
      ),
    ],

    // IMPORTANT : redirect en DEHORS du tableau routes
    redirect: (context, state) {
      final loc = state.fullPath ?? state.uri.path;

      // ✅ LIRE ICI, à la volée (pas capturé en amont)
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final role = ref.read(userRoleProvider); // UserRole? nullable

      // 🧪 Logs ciblés (temporaires)
      debugPrint(
        '🔁 RedirectEval: loc=$loc, auth=$isAuthenticated, role=$role',
      );

      // 1) Non connecté -> /login sauf si on y est déjà
      if (!isAuthenticated) {
        return (loc == '/login') ? null : '/login';
      }

      // 2) Connecté mais rôle pas encore prêt -> /splash (neutre si déjà dessus)
      if (role == null) {
        return (loc == '/splash') ? null : '/splash';
      }

      // 3) Connecté + rôle prêt : normalisation
      if (loc.isEmpty || loc == '/' || loc == '/login' || loc == '/dashboard') {
        return role.dashboardPath; // ton getter existant
      }

      // 4) Fournisseurs : accès réservé admin / directeur / gérant / pca
      if (loc.startsWith('/fournisseurs') && !kFournisseurRoles.contains(role)) {
        return role.dashboardPath;
      }

      return null; // rien à faire
    },
  );
});
