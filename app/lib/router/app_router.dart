import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/layout_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/inventory_page.dart';
import '../pages/records_page.dart';
import '../pages/system_page.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final loggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        
        if (!loggedIn && !isLoggingIn) return '/login';
        if (loggedIn && isLoggingIn) return '/';
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return LayoutPage(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/inventory',
              builder: (context, state) => const InventoryPage(),
            ),
            GoRoute(
              path: '/records',
              builder: (context, state) => const RecordsPage(),
            ),
            GoRoute(
              path: '/system',
              builder: (context, state) => const SystemPage(),
            ),
          ],
        ),
      ],
    );
  }
}
