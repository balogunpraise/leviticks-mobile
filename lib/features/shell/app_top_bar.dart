import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../state/theme_controller.dart';
import '../../widgets/app_logo.dart';

/// Mirrors the authenticated header in `src/components/layout/AttendeeLayout.tsx`:
/// brand mark, theme toggle, and a profile avatar with a logout menu.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title});

  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeController = context.watch<ThemeController>();
    final initial = (auth.profile?.firstName.isNotEmpty ?? false)
        ? auth.profile!.firstName[0].toUpperCase()
        : (auth.profile?.email.isNotEmpty ?? false)
            ? auth.profile!.email[0].toUpperCase()
            : 'U';

    return AppBar(
      titleSpacing: 16,
      title: title != null
          ? Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))
          : const AppLogo(height: 22),
      actions: [
        IconButton(
          onPressed: () => themeController.toggle(),
          icon: Icon(
            themeController.isDark ? LucideIcons.sun : LucideIcons.moon,
            size: 18,
            color: themeController.isDark ? AppColors.amber : AppColors.gray500,
          ),
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 44),
          onSelected: (value) async {
            if (value == 'logout') {
              await auth.logout();
              if (context.mounted) context.go('/login');
            } else if (value == 'security') {
              context.push('/security');
            } else if (value == 'organizer') {
              context.push('/become-organizer');
            }
          },
          itemBuilder: (context) => [
            if (auth.profile != null)
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  '${auth.profile!.firstName} ${auth.profile!.lastName}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            const PopupMenuItem<String>(
              value: 'security',
              child: Row(
                children: [
                  Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.gray500),
                  SizedBox(width: 8),
                  Text('Security'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'organizer',
              child: Row(
                children: [
                  const Icon(LucideIcons.calendarPlus, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 8),
                  Text((auth.profile?.organizerId?.isNotEmpty ?? false) ? 'Organizer workspace' : 'Become an organizer'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(LucideIcons.logOut, size: 14, color: AppColors.rose),
                  SizedBox(width: 8),
                  Text('Log out', style: TextStyle(color: AppColors.rose)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primary,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}
