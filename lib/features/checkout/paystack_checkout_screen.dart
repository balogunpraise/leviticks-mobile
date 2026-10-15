import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/loading_and_empty.dart';

/// Hosts the Paystack checkout page returned by `bookTicket`'s `checkoutUrl`.
/// On completion Paystack redirects the browser away from its own domain
/// back to the merchant's callback URL with `reference`/`trxref` query
/// params; we watch for that and pop with the reference so the caller can
/// verify server-side — mirrors the web app's `payment/callback?reference=...`
/// handoff. Matching is scoped to navigations OFF paystack's own domain —
/// Paystack's hosted checkout page itself commonly embeds a `trxref` in its
/// own URL (e.g. mid-flow redirects, 3D Secure), so matching on the query
/// param alone closed the sheet before the user ever saw the payment form.
class PaystackCheckoutScreen extends StatefulWidget {
  const PaystackCheckoutScreen({super.key, required this.checkoutUrl, required this.paymentReference});

  final String checkoutUrl;
  final String paymentReference;

  @override
  State<PaystackCheckoutScreen> createState() => _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState extends State<PaystackCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loading = true;
            _loadError = null;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (error) {
            // Sub-resource errors (ads/analytics blocked, etc.) are common and harmless;
            // only surface a failure for the main-frame document itself.
            if (error.isForMainFrame == false) return;
            setState(() {
              _loading = false;
              _loadError = 'Could not load the checkout page. Check your connection and try again.';
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final host = uri?.host.toLowerCase() ?? '';
            final isPaystackDomain = host.contains('paystack');
            final hasRef = (uri?.queryParameters['reference']?.isNotEmpty ?? false) ||
                (uri?.queryParameters['trxref']?.isNotEmpty ?? false);
            // Once Paystack hands control back to the merchant's own callback URL, the
            // flow is done — use our own known reference rather than trusting whatever
            // the redirect's query param happens to be named.
            if (!isPaystackDomain && hasRef && !_resolved) {
              _finish(widget.paymentReference);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _finish(String reference) {
    if (_resolved) return;
    _resolved = true;
    Navigator.of(context).pop(reference);
  }

  void _cancel() {
    if (_resolved) return;
    _resolved = true;
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(LucideIcons.x), onPressed: _cancel),
          title: const Text('Secure Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          actions: [
            TextButton(
              onPressed: () => _finish(widget.paymentReference),
              child: const Text("I've paid", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const Positioned.fill(child: LoadingView()),
            if (_loadError != null)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.wifiOff, size: 36, color: AppColors.gray400),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gray400)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() => _loadError = null);
                            _controller.loadRequest(Uri.parse(widget.checkoutUrl));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
