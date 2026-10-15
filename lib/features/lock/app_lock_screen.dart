import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/app_lock_controller.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';

/// Full-screen biometric gate shown over the whole app while
/// `AppLockController.enabled && !isUnlocked` — mobile-only, no web page to mirror.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _prompting = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    setState(() {
      _prompting = true;
      _failed = false;
    });
    final ok = await context.read<AppLockController>().tryUnlock();
    if (!mounted) return;
    setState(() {
      _prompting = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(height: 36),
                const SizedBox(height: 48),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.fingerprint, size: 34, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Leviticks is locked',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _failed
                      ? "Couldn't verify it's you. Try again."
                      : 'Use your fingerprint or face to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _failed ? AppColors.rose : AppColors.gray400),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _prompting ? 'Waiting…' : 'Unlock',
                  icon: LucideIcons.fingerprint,
                  isLoading: _prompting,
                  expand: false,
                  onPressed: _prompting ? null : _unlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
