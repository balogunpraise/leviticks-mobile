import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/auth_models.dart';
import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';

/// Mirrors `src/components/forms/ResetPasswordForm.tsx`: reached from the
/// emailed link's `email`/`token` query params. Requires upper+lower+digit+
/// special char, min 6 characters — same regex as the web form.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.email, this.token});

  final String? email;
  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

final _passwordComplexity = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{6,}$');

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _submitting = false;
  bool _done = false;
  String? _error;

  bool get _linkValid => (widget.email?.isNotEmpty ?? false) && (widget.token?.isNotEmpty ?? false);

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_passwordComplexity.hasMatch(_password.text)) {
      setState(() => _error = 'Password must be 6+ characters with upper/lowercase, a number and a special character.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final authService = context.read<AuthService>();
    final response = await authService.resetPassword(
      ResetPasswordRequest(email: widget.email!, token: widget.token!, newPassword: _password.text),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (response?.isSuccess ?? false) {
      setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) context.go('/login');
    } else {
      setState(() => _error = response?.message ?? 'Failed to reset password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(LucideIcons.moveLeft), onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: !_linkValid
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.circleAlert, color: AppColors.rose, size: 36),
                    const SizedBox(height: 16),
                    const Text('Invalid reset link', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'This password reset link is missing or malformed. Request a new one.',
                      style: TextStyle(color: AppColors.gray500),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(label: 'Request a new link', onPressed: () => context.go('/forgot-password')),
                  ],
                )
              : _done
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.checkCircle, color: AppColors.success, size: 36),
                        SizedBox(height: 16),
                        Text('Password reset!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        SizedBox(height: 8),
                        Text('Redirecting you to log in...', style: TextStyle(color: AppColors.gray500)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reset your password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('Choose a new password for your account.', style: TextStyle(color: AppColors.gray500)),
                        const SizedBox(height: 28),
                        const Text('New Password', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _password,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppColors.gray400),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirm,
                          obscureText: !_showPassword,
                          decoration: const InputDecoration(hintText: '••••••••'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 12)),
                        ],
                        const SizedBox(height: 20),
                        PrimaryButton(label: 'Reset password', isLoading: _submitting, onPressed: _submit),
                      ],
                    ),
        ),
      ),
    );
  }
}
