import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../state/theme_controller.dart';

/// Mobile-only — pamweb-next keeps its theme toggle inline in the navbar
/// with no dedicated settings page to mirror, so this groups it the way the
/// app's own Security screen groups its toggles.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.moveLeft), onPressed: () => context.pop()),
        title: const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.xl2),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    themeController.isDark ? LucideIcons.moon : LucideIcons.sun,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Switch between light and dark appearance.', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: themeController.isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) => themeController.toggle(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
