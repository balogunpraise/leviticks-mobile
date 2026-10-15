import 'package:flutter/material.dart';

/// Color tokens mirrored from pamweb-next's `src/app/globals.css` (`@theme` block)
/// plus the Tailwind gray scale used throughout the attendee pages, so the
/// mobile app reads as the same product as the web app.
///
/// gray700/800/900/950 are anchored on the brand black (see globals.css) so
/// every dark surface/border/text token across the app reads the same near-black
/// as the web app instead of the old blue-gray Tailwind defaults.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF65801);
  static const Color success = Color(0xFF10B981);
  static const Color pending = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFF59E0B);

  // --color-shaded / --color-secondary (light + dark overrides from the `.dark` block).
  static const Color shadedLight = Color(0xFFF7F5F3);
  static const Color shadedDark = Color(0xFF181818);
  static const Color secondaryLight = Color(0xFFFDECE1);
  static const Color secondaryDark = Color(0xFF2E2115);
  static const Color customGrayLight = Color(0xFFE8E8E8);
  static const Color customGrayDark = Color(0xFF141414);

  // Tailwind gray scale, used verbatim across the web app's borders/text.
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF3A3A3A);
  static const Color gray800 = Color(0xFF2B2B2B);
  static const Color gray900 = Color(0xFF1F1F1F);
  static const Color gray950 = Color(0xFF141414);

  static const Color orange500 = Color(0xFFF97316);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color purple500 = Color(0xFFA855F7);
}
