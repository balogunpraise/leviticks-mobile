import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The Leviticks wordmark, mirroring the `LT-on_black_keanin.png` mark used
/// across `pamweb-next`'s Sidebar/Footer/AttendeeLayout.
const String kLevitticksLogoUrl =
    'https://res.cloudinary.com/dvoez6mj2/image/upload/v1789213304/LT-on_black_keanin.png';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 32});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      kLevitticksLogoUrl,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        'Leviticks',
        style: TextStyle(color: AppColors.primary, fontSize: height * 0.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}
