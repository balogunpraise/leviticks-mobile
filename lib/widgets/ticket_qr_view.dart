import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../services/event_service.dart';
import '../state/auth_provider.dart';
import 'qr_pattern.dart';

/// Fetches the real, scannable QR for a ticket (an authenticated PNG blob,
/// mirroring the `useTicketQr` hook on web) and shows it once ready, falling
/// back to the decorative seeded pattern while loading or on error.
class TicketQrView extends StatefulWidget {
  const TicketQrView({super.key, required this.ticketId, required this.fallbackCode, this.size = 160});

  final String ticketId;
  final String fallbackCode;
  final double size;

  @override
  State<TicketQrView> createState() => _TicketQrViewState();
}

class _TicketQrViewState extends State<TicketQrView> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final eventService = context.read<EventService>();
    final token = await auth.getValidAccessToken();
    final bytes = await eventService.getTicketQrImage(token, widget.ticketId);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(_bytes!, width: widget.size, height: widget.size, fit: BoxFit.contain);
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        QrPatternView(code: widget.fallbackCode, size: widget.size, color: AppColors.gray300),
        if (_loading) const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }
}

/// Fullscreen QR, opened from a "Show QR" button — mirrors the web app's
/// `QrFullscreen` modal.
class TicketQrFullscreenSheet extends StatelessWidget {
  const TicketQrFullscreenSheet({super.key, required this.ticketId, required this.ticketCode, required this.eventTitle});

  final String ticketId;
  final String ticketCode;
  final String eventTitle;

  static void show(BuildContext context, {required String ticketId, required String ticketCode, required String eventTitle}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => TicketQrFullscreenSheet(ticketId: ticketId, ticketCode: ticketCode, eventTitle: eventTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(eventTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black)),
                const SizedBox(height: 18),
                TicketQrView(ticketId: ticketId, fallbackCode: ticketCode, size: 220),
                const SizedBox(height: 14),
                Text(ticketCode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.black)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
