import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/auth_models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/auth_cover_banner.dart';
import '../../widgets/primary_button.dart';

/// Mirrors `src/components/forms/LoginForm.tsx` inside `(auth)/login/page.tsx`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _submitting = false;
  AuthenticateResponseDto? _twoFactorChallenge;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    final data = result?.data;
    if (data?.requiresTwoFactor ?? false) {
      setState(() => _twoFactorChallenge = data);
      return;
    }
    if (data?.jwtToken?.accessToken.isEmpty ?? true) {
      AppToast.show(
        context,
        message: 'Login failed. Check email/password and try again.',
        success: false,
      );
    }
    // A successful login flips `AuthProvider.isAuthenticated`; the router's
    // `refreshListenable` redirect takes it from here (mirrors the router.push in LoginForm).
  }

  @override
  Widget build(BuildContext context) {
    if (_twoFactorChallenge != null) {
      return _TwoFactorChallengeScreen(
        challenge: _twoFactorChallenge!,
        onUseDifferentAccount: () => setState(() => _twoFactorChallenge = null),
      );
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthCoverBanner(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter your details to access your account.',
                      style: TextStyle(color: AppColors.gray500),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Email',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/forgot-password'),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            size: 18,
                            color: AppColors.gray400,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Log in',
                      isLoading: _submitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: TextStyle(
                              color: AppColors.gray400,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            glyph: const Icon(
                              Icons.facebook,
                              size: 18,
                              color: AppColors.blue500,
                            ),
                            label: 'Facebook',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SocialButton(
                            glyph: const Text(
                              'G',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.rose,
                              ),
                            ),
                            label: 'Google',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Wrap(
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The emailed-code step shown when `LoginScreen._submit` gets back
/// `requiresTwoFactor: true` — mirrors `LoginForm.tsx`'s 2FA challenge screen.
class _TwoFactorChallengeScreen extends StatefulWidget {
  const _TwoFactorChallengeScreen({required this.challenge, required this.onUseDifferentAccount});

  final AuthenticateResponseDto challenge;
  final VoidCallback onUseDifferentAccount;

  @override
  State<_TwoFactorChallengeScreen> createState() => _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState extends State<_TwoFactorChallengeScreen> {
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    final expiresAt = widget.challenge.twoFactorCodeExpiresAt;
    _ticker?.cancel();
    if (expiresAt == null) return;
    void tick() {
      final remaining = expiresAt.difference(DateTime.now());
      setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().length < 4) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final result = await auth.completeTwoFactorLogin(widget.challenge.userId, _code.text.trim());
    if (!mounted) return;
    setState(() => _verifying = false);
    if (result?.data?.jwtToken?.accessToken.isEmpty ?? true) {
      setState(() => _error = result?.message ?? 'Invalid or expired code. Please try again.');
    }
    // A successful verify flips `AuthProvider.isAuthenticated`; the router's redirect takes it from here.
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final auth = context.read<AuthProvider>();
    await auth.resendTwoFactorCode(widget.challenge.userId);
    if (!mounted) return;
    setState(() => _resending = false);
    _startCountdown();
    AppToast.show(context, message: 'A new code has been sent.', success: true);
  }

  String get _countdownLabel {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.shieldCheck, size: 36, color: AppColors.primary),
              const SizedBox(height: 20),
              const Text('Two-factor verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                widget.challenge.twoFactorCodeSentTo?.isNotEmpty ?? false
                    ? 'Enter the 6-digit code we sent to ${widget.challenge.twoFactorCodeSentTo}.'
                    : 'Enter the 6-digit code we emailed you.',
                style: const TextStyle(color: AppColors.gray500),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                decoration: const InputDecoration(counterText: '', hintText: '000000'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 13)),
              ],
              const SizedBox(height: 18),
              PrimaryButton(label: 'Verify', isLoading: _verifying, onPressed: _verify),
              const SizedBox(height: 18),
              Center(
                child: _remaining > Duration.zero
                    ? Text('New code in $_countdownLabel', style: const TextStyle(color: AppColors.gray400, fontSize: 13))
                    : TextButton(
                        onPressed: _resending ? null : _resend,
                        child: Text(_resending ? 'Sending…' : 'Send a new code'),
                      ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: widget.onUseDifferentAccount,
                  child: const Text('Use a different account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.glyph, required this.label});

  final Widget glyph;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppColors.gray200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          glyph,
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.gray700)),
        ],
      ),
    );
  }
}
