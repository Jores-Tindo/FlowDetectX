import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/utilisateurs_screen.dart';
import '../screens/admin/journaux_screen.dart';
import '../screens/validateur/validateur_shell.dart';
import '../screens/validateur/validateur_dashboard_screen.dart';
import '../screens/validateur/regles_screen.dart';
import '../screens/validateur/historique_screen.dart';
import '../screens/metier/metier_shell.dart';
import '../screens/metier/metier_dashboard_screen.dart';
import '../screens/metier/historique_demandes_screen.dart';
import '../screens/metier/metier_regles_screen.dart';
import '../screens/metier/metier_alertes_screen.dart';
import '../screens/commun/profil_screen.dart';
import '../screens/validateur/catalogue_regles_screen.dart';

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = context.read<AuthProvider>().isAuthentifie;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        return context.read<AuthProvider>().routeInitiale;
      }

      return null;
    },
    routes: [
      // ─── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ─── Admin ─────────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/admin/utilisateurs',
            builder: (context, state) => const UtilisateursScreen(),
          ),
          GoRoute(
            path: '/admin/journaux',
            builder: (context, state) => const JournauxScreen(),
          ),
          GoRoute(
            path: '/admin/profil',
            builder: (context, state) => const ProfilScreen(),
          ),
        ],
      ),

      // ─── Validateur ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ValidateurShell(child: child),
        routes: [
          GoRoute(
            path: '/validateur/dashboard',
            builder: (context, state) => const ValidateurDashboardScreen(),
          ),
          GoRoute(
            path: '/validateur/regles',
            builder: (context, state) => const ReglesScreen(),
          ),
          GoRoute(
            path: '/validateur/historique',
            builder: (context, state) => const HistoriqueScreen(),
          ),
          GoRoute(
            path: '/validateur/catalogue-regles',
            builder: (context, state) => const CatalogueReglesScreen(),
          ),
          GoRoute(
            path: '/validateur/profil',
            builder: (context, state) => const ProfilScreen(),
          ),
        ],
      ),

      // ─── Utilisateur Métier ────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MetierShell(child: child),
        routes: [
          GoRoute(
            path: '/metier/dashboard',
            builder: (context, state) => const MetierDashboardScreen(),
          ),
          GoRoute(
            path: '/metier/regles',
            builder: (context, state) => const MetierReglesScreen(),
          ),
          GoRoute(
            path: '/metier/alertes',
            builder: (context, state) => const MetierAlertesScreen(),
          ),
          GoRoute(
            path: '/metier/historique-demandes',
            builder: (context, state) => const HistoriqueDemandesScreen(),
          ),
          GoRoute(
            path: '/metier/profil',
            builder: (context, state) => const ProfilScreen(),
          ),
        ],
      ),
    ],
  );
}
