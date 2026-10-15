import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';

/// Mirrors `src/components/shared/ResponseMessage.tsx`: a top-anchored toast
/// that slides down + fades in, auto-dismisses, and can be swiped/tapped away.
class AppToast {
  AppToast._();

  static const Duration _defaultDuration = Duration(milliseconds: 5000);
  static const Duration _exitDuration = Duration(milliseconds: 200);

  static void show(
    BuildContext context, {
    required String message,
    bool success = true,
    Duration duration = _defaultDuration,
  }) {
    if (message.trim().isEmpty) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    final key = GlobalKey<_ToastCardState>();

    void remove() {
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _ToastCard(
        key: key,
        message: message,
        success: success,
        duration: duration,
        exitDuration: _exitDuration,
        onDismissed: remove,
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    super.key,
    required this.message,
    required this.success,
    required this.duration,
    required this.exitDuration,
    required this.onDismissed,
  });

  final String message;
  final bool success;
  final Duration duration;
  final Duration exitDuration;
  final VoidCallback onDismissed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.exitDuration);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.easeOut);
    _slide = Tween<double>(begin: -8, end: 0).animate(curved);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);

    // Enter on the next frame (mirrors the requestAnimationFrame mount → enter sequence).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });

    Future.delayed(widget.duration, dismiss);
  }

  Future<void> dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.success ? AppColors.success : AppColors.rose;
    final iconBg = widget.success
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
        : (isDark ? const Color(0xFF4C0519) : const Color(0xFFFFE4E6));
    final iconColor = widget.success
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48));

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 20,
      left: 20,
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.translate(offset: Offset(0, _slide.value), child: child),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray900 : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: isDark ? AppColors.gray800 : AppColors.gray100),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 4, height: 36, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                        child: Icon(widget.success ? LucideIcons.circleCheckBig : LucideIcons.circleX, size: 16, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            widget.message,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3, color: isDark ? AppColors.gray200 : AppColors.gray700),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: dismiss,
                        icon: Icon(LucideIcons.x, size: 16, color: AppColors.gray400),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
