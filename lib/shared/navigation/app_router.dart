import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ml_pp_mvp/shared/navigation/go_router_refresh_stream.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

import 'package:ml_pp_mvp/features/auth/screens/login_screen.dart';
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
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_pca_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/dashboard_shell.dart';
import 'package:ml_pp_mvp/features/logs/screens/logs_list_screen.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/screens/stocks_list_screen.dart';
import 'package:ml_pp_mvp/features/citernes/screens/citerne_list_screen.dart';

// Default home page for authenticated users
const String kDefaultHome = '/receptions';

final routerProvider = Provider<GoRouter>((ref) {
  // État d'auth AppAuthState (notre provider)
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    // 🔁 Forcer le rafraîchissement du routeur quand l'auth change
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.stream)),
    // ⬇️ Logique de redirection basée sur l'état d'auth
    redirect: (context, state) {
      // Statut d'auth courant (synchrone, fiable)
      final signedIn = ref.read(isAuthenticatedProvider);

      // Chemin actuel (compatible go_router versions récentes)
      final path = state.uri.path;

      // Endroits « publics » (à adapter selon ton app)
      const publicPaths = <String>{
        '/',           // 👈 racine publique
        '/login',
        '/forgot-password',
      };

      final isOnPublicPage = publicPaths.contains(path);

      // 1) Non connecté → forcer vers /login (sauf si déjà sur une publique)
      if (!signedIn) {
        return isOnPublicPage ? null : '/login';
      }

      // 2) Connecté → éviter /login et / (rediriger vers la home app)
      if (signedIn && (path == '/login' || path == '/')) {
        // Utilise le rôle utilisateur pour la redirection
        final role = ref.read(userRoleProvider);
        return UserRoleX.roleToHome(role);
      }

      // 3) Sinon, pas de redirection
      return null;
    },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    /// Shell that wraps all dashboard routes
    ShellRoute(
      builder: (context, state, child) => DashboardShell(child: child),
      routes: [
        // Dashboards par rôle (chemins absolus)
        GoRoute(path: '/dashboard/admin', builder: (context, state) => const DashboardAdminScreen()),
        GoRoute(path: '/dashboard/directeur', builder: (context, state) => const DashboardDirecteurScreen()),
        GoRoute(path: '/dashboard/gerant', builder: (context, state) => const DashboardGerantScreen()),
        GoRoute(path: '/dashboard/operateur', builder: (context, state) => const DashboardOperateurScreen()),
        GoRoute(path: '/dashboard/lecture', builder: (context, state) => const DashboardLectureScreen()),
        GoRoute(path: '/dashboard/pca', builder: (context, state) => const DashboardPcaScreen()),

        // Cours de route
        GoRoute(path: '/cours', builder: (context, state) => const CoursRouteListScreen()),
        GoRoute(path: '/cours/new', builder: (context, state) => const CoursRouteFormScreen()),
        GoRoute(
          path: '/cours/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CoursRouteDetailScreen(coursId: id);
          },
        ),
        GoRoute(
          path: '/cours/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CoursRouteFormScreen(coursId: id);
          },
        ),

        // Réceptions
        GoRoute(path: '/receptions', builder: (context, state) => const ReceptionListScreen()),
        GoRoute(
          path: '/receptions/new',
          builder: (context, state) {
            final coursId = state.uri.queryParameters['coursId'];
            return ReceptionFormScreen(coursDeRouteId: coursId);
          },
        ),

        // Sorties produit
        GoRoute(path: '/sorties', builder: (context, state) => const SortieListScreen()),
        GoRoute(path: '/sorties/new', builder: (context, state) => const SortieFormScreen()),

        // Stocks & Citernes
        GoRoute(path: '/stocks', builder: (context, state) => const StocksListScreen()),
        GoRoute(path: '/citernes', builder: (context, state) => const CiterneListScreen()),

        // Logs audit
        GoRoute(path: '/logs', builder: (context, state) => const LogsListScreen()),
      ],
    ),
  ],
);
});

// Provider pour accéder au router depuis l'extérieur
final appRouterProvider = Provider<GoRouter>((ref) => ref.watch(routerProvider));
