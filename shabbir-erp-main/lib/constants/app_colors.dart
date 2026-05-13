import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E1B4B);
  static const Color tint = Color(0xFF4F46E5);
  static const Color background = Color(0xFFFFFBEB);
  static const Color foreground = Color(0xFF1C1A0F);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF1C1A0F);
  static const Color secondary = Color(0xFFFEF3C7);
  static const Color secondaryForeground = Color(0xFF92400E);
  static const Color muted = Color(0xFFFEF9E7);
  static const Color mutedForeground = Color(0xFF78716C);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentForeground = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF16A34A);
  static const Color successForeground = Color(0xFFFFFFFF);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFFDE68A);
  static const Color input = Color(0xFFFDE68A);
  static const Color supplierAvatar = Color(0xFF92400E);

  static const double radius = 14.0;

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.amber.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  static BoxShadow get elevatedShadow => BoxShadow(
        color: Colors.amber.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(0, 4),
      );
}
