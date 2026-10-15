import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/auth_models.dart';
import '../../models/common.dart';
import '../../services/auth_service.dart';
import '../../state/app_lock_controller.dart';
import '../../state/auth_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton.dart';

/// Mirrors `src/app/(attendee)/security/SecurityClient.tsx`: the web page is
/// just a `TwoFactorCard` — email-based 2FA on/off, nothing else (no password
/// change or session list UI exists there either).
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

enum _TwoFactorStep { idle, codeEntry, disableConfirm }

class _SecurityScreenState extends State<SecurityScreen> {
  bool _loading = true;
  TwoFactorStatus? _status;
  _TwoFactorStep _step = _TwoFactorStep.idle;
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  bool? _biometricSupported;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<AppLockController>().isSupported().then((supported) {
      if (mounted) setState(() => _biometricSupported = supported);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final authService = context.read<AuthService>();
    final token = await auth.getValidAccessToken();
    final response = await authService.getTwoFactorStatus(token);
    if (!mounted) return;
    setState(() {
      _status = response?.data;
      _loading = false;
    });
  }

  Future<void> _startEnable() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final authService = context.read<AuthService>();
    final token = await auth.getValidAccessToken();
    final response = await authService.startTwoFactorSetup(token);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (response?.isSuccess ?? false) {
        _step = _TwoFactorStep.codeEntry;
      } else {
        _error = response?.message ?? 'Could not start setup. Please try again.';
      }
    });
  }

  Future<void> _confirmEnable() async {
    if (_code.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final authService = context.read<AuthService>();
    final token = await auth.getValidAccessToken();
    final response = await authService.enableTwoFactor(token, _code.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (response?.statusCode == ApiResponse.successCode && response?.data != null) {
      setState(() {
        _status = response!.data;
        _step = _TwoFactorStep.idle;
        _code.clear();
      });
      AppToast.show(context, message: 'Two-factor authentication is now on.', success: true);
    } else {
      setState(() => _error = response?.message ?? 'Invalid code. Please try again.');
    }
  }

  Future<void> _confirmDisable() async {
    if (_password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final authService = context.read<AuthService>();
    final token = await auth.getValidAccessToken();
    final response = await authService.disableTwoFactor(token, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (response?.statusCode == ApiResponse.successCode && response?.data != null) {
      setState(() {
        _status = response!.data;
        _step = _TwoFactorStep.idle;
        _password.clear();
      });
      AppToast.show(context, message: 'Two-factor authentication is now off.', success: true);
    } else {
      setState(() => _error = response?.message ?? 'Incorrect password. Please try again.');
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _biometricBusy = true);
    final lock = context.read<AppLockController>();
    if (value) {
      final ok = await lock.enable();
      if (!ok && mounted) {
        AppToast.show(context, message: "Couldn't verify your fingerprint or face. Try again.", success: false);
      } else if (mounted) {
        AppToast.show(context, message: 'App lock is now on.', success: true);
      }
    } else {
      await lock.disable();
      if (mounted) AppToast.show(context, message: 'App lock is now off.', success: true);
    }
    if (mounted) setState(() => _biometricBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.moveLeft), onPressed: () => context.pop()),
        title: const Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('Protect your account with an emailed code at login.', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _loading ? const InlineBarSkeleton() : _buildBody(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildBiometricCard(borderColor),
        ],
      ),
    );
  }

  Widget _buildBiometricCard(Color borderColor) {
    final lock = context.watch<AppLockController>();
    final supported = _biometricSupported;
    return Container(
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
            child: const Icon(LucideIcons.fingerprint, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Biometric Unlock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  supported == false
                      ? 'Not available on this device.'
                      : 'Require your fingerprint or face to open the app.',
                  style: const TextStyle(color: AppColors.gray400, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_biometricBusy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else
            Switch(
              value: lock.enabled,
              activeThumbColor: AppColors.primary,
              onChanged: supported == false ? null : _toggleBiometric,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_step == _TwoFactorStep.codeEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("We've emailed you a 6-digit code. Enter it below to turn two-factor on.", style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(counterText: '', hintText: '000000'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _TwoFactorStep.idle),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton(label: 'Confirm', isLoading: _busy, onPressed: _confirmEnable)),
            ],
          ),
        ],
      );
    }

    if (_step == _TwoFactorStep.disableConfirm) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your password to turn two-factor off.', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(hintText: '••••••••'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _TwoFactorStep.idle),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(label: 'Turn off', isLoading: _busy, onPressed: _confirmDisable),
              ),
            ],
          ),
        ],
      );
    }

    final enabled = _status?.enabled ?? false;
    return Row(
      children: [
        Expanded(
          child: Text(
            enabled ? 'Enabled · codes sent to ${_status?.email ?? 'your email'}' : 'Currently turned off.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: enabled ? AppColors.success : AppColors.gray400),
          ),
        ),
        if (enabled)
          OutlinedButton(
            onPressed: () => setState(() => _step = _TwoFactorStep.disableConfirm),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.rose, side: const BorderSide(color: AppColors.rose)),
            child: const Text('Turn off'),
          )
        else
          PrimaryButton(label: 'Turn on', expand: false, isLoading: _busy, onPressed: _startEnable),
      ],
    );
  }
}
