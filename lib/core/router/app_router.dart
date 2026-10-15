import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/become_organizer/become_organizer_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/event_detail/event_detail_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/my_tickets/my_tickets_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/security/security_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/attendee_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/ticket_detail/ticket_detail_screen.dart';
import '../../state/auth_provider.dart';

/// Mirrors the `(auth)`/`(attendee)` route groups + `AttendeeLayout`'s
/// authenticated/guest redirect behavior from the web app.
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (auth.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }
      final loggedIn = auth.isAuthenticated;
      final onAuthPage =
          loc == '/login' || loc == '/register' || loc == '/forgot-password' || loc == '/reset-password';

      if (loc == '/splash') return loggedIn ? '/dashboard' : '/login';
      if (!loggedIn && !onAuthPage) return '/login';
      if (loggedIn && onAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'],
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(path: '/security', builder: (context, state) => const SecurityScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/become-organizer', builder: (context, state) => const BecomeOrganizerScreen()),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (context, state) => TicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AttendeeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/my-tickets', builder: (context, state) => const MyTicketsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/saved', builder: (context, state) => const SavedScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen())]),
        ],
      ),
    ],
  );
}
