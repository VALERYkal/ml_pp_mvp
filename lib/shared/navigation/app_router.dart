import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/navigation/go_router_refresh_stream.dart';
import 'package:ml_pp_mvp/shared/navigation/router_refresh.dart';

import 'package:ml_pp_mvp/features/auth/screens/login_screen.dart';
import 'package:ml_pp_mvp/features/splash/splash_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_form_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_detail_screen.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_list_screen.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_form_screen.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_list_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_admin_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_directeur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_gerant_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_operateur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_lecture_screen.dart';
import 'package:ml_pp_mvp/dev/clear_cache_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_pca_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/dashboard_shell.dart';
import 'package:ml_pp_mvp/features/logs/screens/logs_list_screen.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/screens/stocks_list_screen.dart';
import 'package:ml_pp_mvp/features/citernes/screens/citerne_list_screen.dart';

// Default home page for authenticated users
const String kDefaultHome = '/receptions';

final appRouterProvider = Provider<GoRouter>((ref) {
  // ?? CORRECTIF : Utiliser le refresh composite (auth + rôle)
  final refresh = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: refresh, // ?? composite (auth + rôle)
    routes: [
      // Routes publiques (inchangées)
      GoRoute(path: '/login', name: 'login', builder: (ctx, st) => const LoginScreen()),
      GoRoute(path: '/splash', name: 'splash', builder: (ctx, st) => const SplashScreen()),

      // Route dev pour purge de cache
      GoRoute(
        path: '/dev/cache-reset',
        name: 'dev-cache-reset',
        builder: (ctx, st) => const ClearCacheScreen(),
      ),

      // === SHELL UNIFIÉ : Toutes les routes protégées ===
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          // Dashboards par rôle
          GoRoute(path: '/dashboard/admin', builder: (ctx, st) => const DashboardAdminScreen()),
          GoRoute(
            path: '/dashboard/directeur',
            builder: (ctx, st) => const DashboardDirecteurScreen(),
          ),
          GoRoute(path: '/dashboard/gerant', builder: (ctx, st) => const DashboardGerantScreen()),
          GoRoute(
            path: '/dashboard/operateur',
            builder: (ctx, st) => const DashboardOperateurScreen(),
          ),
          GoRoute(path: '/dashboard/pca', builder: (ctx, st) => const DashboardPcaScreen()),
          GoRoute(path: '/dashboard/lecture', builder: (ctx, st) => const DashboardLectureScreen()),

          // Route générique dashboard (redirigée par le redirect global)
          GoRoute(path: '/dashboard', builder: (ctx, st) => const SplashScreen()),

          // Modules fonctionnels
          GoRoute(path: '/cours', builder: (ctx, st) => const CoursRouteListScreen()),
          GoRoute(path: '/cours/new', builder: (ctx, st) => const CoursRouteFormScreen()),
          GoRoute(
            path: '/cours/:id',
            builder: (ctx, st) => CoursRouteDetailScreen(coursId: st.pathParameters['id']!),
          ),
          GoRoute(
            path: '/cours/:id/edit',
            builder: (ctx, st) => CoursRouteFormScreen(coursId: st.pathParameters['id']),
          ),

          GoRoute(path: '/receptions', builder: (ctx, st) => const ReceptionListScreen()),
          GoRoute(
            path: '/receptions/new',
            builder: (ctx, st) {
              final coursId = st.uri.queryParameters['coursId'];
              return ReceptionFormScreen(coursDeRouteId: coursId);
            },
          ),

          GoRoute(path: '/sorties', builder: (ctx, st) => const SortieListScreen()),
          GoRoute(path: '/sorties/new', builder: (ctx, st) => const SortieFormScreen()),

          GoRoute(path: '/stocks', builder: (ctx, st) => const StocksListScreen()),
          GoRoute(path: '/citernes', builder: (ctx, st) => const CiterneListScreen()),
          GoRoute(path: '/logs', builder: (ctx, st) => const LogsListScreen()),
        ],
      ),
    ],

    // IMPORTANT : redirect en DEHORS du tableau routes
    redirect: (context, state) {
      final loc = state.fullPath ?? state.uri.path;

      // ? LIRE ICI, à la volée (pas capturé en amont)
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final role = ref.read(userRoleProvider); // UserRole? nullable

      // ?? Logs ciblés (temporaires)
      debugPrint('?? RedirectEval: loc=$loc, auth=$isAuthenticated, role=$role');

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

      return null; // rien à faire
    },
  );
});




