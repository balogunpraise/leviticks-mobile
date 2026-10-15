import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../state/auth_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/primary_button.dart';

const _benefits = [
  (icon: LucideIcons.calendarPlus, title: 'Create events', detail: 'Publish and manage your own events in minutes.'),
  (icon: LucideIcons.scanLine, title: 'Scan guests', detail: 'Check attendees in at the door with the built-in scanner.'),
  (icon: LucideIcons.wallet, title: 'Get paid', detail: 'Collect ticket sales straight to your payout account.'),
];

/// Mirrors `src/app/(attendee)/become-organizer/BecomeOrganizerClient.tsx`:
/// a single-field ("Organizer name") onboarding step that upgrades the
/// signed-in attendee account so it can also host events.
class BecomeOrganizerScreen extends StatefulWidget {
  const BecomeOrganizerScreen({super.key});

  @override
  State<BecomeOrganizerScreen> createState() => _BecomeOrganizerScreenState();
}

class _BecomeOrganizerScreenState extends State<BecomeOrganizerScreen> {
  late final _name = TextEditingController(text: _initialName());
  bool _submitting = false;
  String? _error;

  String _initialName() {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) return '';
    return '${profile.firstName} ${profile.lastName}'.trim();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _isOrganizer => context.watch<AuthProvider>().profile?.organizerId?.isNotEmpty ?? false;

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Organizer name is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final result = await auth.becomeOrganizer(_name.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result?.data?.jwtToken?.accessToken.isNotEmpty ?? false) {
      await auth.loadProfile();
      if (!mounted) return;
      AppToast.show(context, message: 'You can now host events on Leviticks.', success: true);
    } else {
      setState(() => _error = result?.message ?? 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.moveLeft), onPressed: () => context.pop()),
        title: const Text('Become an Organizer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Host your own events', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Switch your account into organizer mode — you can still attend events as yourself.',
                style: TextStyle(color: AppColors.gray500, fontSize: 13),
              ),
              const SizedBox(height: 20),
              for (final b in _benefits) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Icon(b.icon, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(b.detail, style: const TextStyle(color: AppColors.gray400, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (_isOrganizer) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: AppColors.success),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("You're already an organizer.", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text('Organizer name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _name, decoration: const InputDecoration(hintText: 'e.g. Leviticks Events')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.triangleAlert, color: AppColors.amber, size: 16),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "You'll need to verify identity (KYC) and add a payout account before your first payout.",
                          style: TextStyle(color: AppColors.amber, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 12)),
                ],
                const SizedBox(height: 18),
                PrimaryButton(label: 'Become an organizer', isLoading: _submitting, onPressed: _submit),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
