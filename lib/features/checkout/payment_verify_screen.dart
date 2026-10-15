import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/common.dart';
import '../../models/ticket_models.dart';
import '../../services/event_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/loading_and_empty.dart';
import '../../widgets/primary_button.dart';

/// Mirrors `src/app/payment/callback/page.tsx`: verifies a Paystack
/// `reference` server-side and shows the resulting order summary.
class PaymentVerifyScreen extends StatefulWidget {
  const PaymentVerifyScreen({super.key, required this.reference});

  final String reference;

  @override
  State<PaymentVerifyScreen> createState() => _PaymentVerifyScreenState();
}

enum _VerifyState { verifying, success, failed }

class _PaymentVerifyScreenState extends State<PaymentVerifyScreen> {
  _VerifyState _state = _VerifyState.verifying;
  VerifyCheckoutResponse? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    setState(() => _state = _VerifyState.verifying);
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final response = await eventService.verifyCheckout(token, widget.reference);
    if (!mounted) return;
    if (response?.statusCode == ApiResponse.successCode && response?.data != null && response!.data!.isSuccessful) {
      setState(() {
        _result = response.data;
        _state = _VerifyState.success;
      });
    } else {
      setState(() {
        _error = response?.message ?? 'We could not confirm this payment. Please retry.';
        _state = _VerifyState.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_state) {
            _VerifyState.verifying => const _VerifyingView(),
            _VerifyState.success => _SuccessView(result: _result!),
            _VerifyState.failed => _FailedView(error: _error!, onRetry: _verify),
          },
        ),
      ),
    );
  }
}

class _VerifyingView extends StatelessWidget {
  const _VerifyingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingView(),
        SizedBox(height: 16),
        Text('Confirming your payment...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        SizedBox(height: 6),
        Text('Secured by Paystack', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.circleX, color: AppColors.rose, size: 44),
        const SizedBox(height: 14),
        const Text('Payment not confirmed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gray400, fontSize: 13)),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Retry Verification', icon: LucideIcons.refreshCw, onPressed: onRetry),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result});

  final VerifyCheckoutResponse result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 48),
        const SizedBox(height: 14),
        const Text('Payment successful!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        const Text('Your tickets are ready in My Tickets.', style: TextStyle(color: AppColors.gray400, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Order', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                  Text(result.orderId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 10),
              for (final t in result.bookedTickets) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${t.quantity} × ${t.ticketTypeName}', style: const TextStyle(fontSize: 13)),
                      Text('₦${(t.pricePerTicket * t.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(
                    '₦${result.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'View My Tickets', onPressed: () => context.go('/my-tickets')),
      ],
    );
  }
}
