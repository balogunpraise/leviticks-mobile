import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_logo.dart';

/// Full-bleed top banner for the login/register screens: the brand's event
/// cover photo (`eventcover_fx7g7k.jpg`, mirroring `AuthLayout.module.css`'s
/// `.left` cover panel on the web) with the Leviticks mark over a scrim that
/// blends into the page background.
class AuthCoverBanner extends StatelessWidget {
  const AuthCoverBanner({super.key, this.height = 170});

  final double height;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: 'https://res.cloudinary.com/dvoez6mj2/image/upload/v1789201566/eventcover_fx7g7k.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.35), bg],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          const Positioned(left: 24, bottom: 18, child: AppLogo(height: 32)),
        ],
      ),
    );
  }
}
