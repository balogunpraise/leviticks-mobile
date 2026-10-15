import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';

/// Shown while `AuthProvider.bootstrap()` reads the stored session — the
/// router's redirect then sends the user to `/dashboard` or `/login`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(height: 44),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
