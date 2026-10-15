import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/lock/app_lock_screen.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'state/app_lock_controller.dart';
import 'state/auth_provider.dart';
import 'state/theme_controller.dart';

void main() {
  runApp(const PamAttendeeApp());
}

/// Root widget — mirrors `src/app/layout.tsx`'s provider stack
/// (`AuthProvider` > `ThemeProvider`) plus the API client wiring from
/// `src/lib/http.ts` / `src/lib/services/*`.
class PamAttendeeApp extends StatelessWidget {
  const PamAttendeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        Provider<TokenStorage>(create: (_) => TokenStorage()),
        Provider<AuthService>(create: (context) => AuthService(context.read<ApiClient>())),
        Provider<EventService>(create: (context) => EventService(context.read<ApiClient>())),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>(), context.read<TokenStorage>())..bootstrap(),
        ),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()..bootstrap()),
        ChangeNotifierProvider<AppLockController>(create: (_) => AppLockController()..bootstrap()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  late final GoRouter _router = buildRouter(context.read<AuthProvider>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only `paused` (truly backgrounded) — `inactive` also fires for the
    // biometric prompt's own system dialog, which would otherwise re-lock
    // the app the instant it's unlocked.
    if (state == AppLifecycleState.paused) {
      context.read<AppLockController>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final lock = context.watch<AppLockController>();
    return MaterialApp.router(
      title: 'Leviticks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.mode,
      routerConfig: _router,
      builder: (context, child) {
        // Stacked over `child` (not swapped in for it) so the routed app
        // underneath keeps its navigation/scroll state while locked.
        return Stack(
          children: [
            ?child,
            if (lock.enabled && !lock.isUnlocked) const AppLockScreen(),
          ],
        );
      },
    );
  }
}
