import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';

/// Small rounded badge used for event/ticket status labels
/// (mirrors the `statusBadgeClass`/`statusLabels` helpers on the web).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.dense = false});

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: dense ? 10 : 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class StatusColors {
  StatusColors._();

  static Color live = AppColors.success;
  static Color upcoming = AppColors.blue500;
  static Color ended = AppColors.orange500;
  static Color past = AppColors.orange500;
  static Color transferred = AppColors.purple500;
}
