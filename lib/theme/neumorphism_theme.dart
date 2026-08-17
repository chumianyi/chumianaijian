import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:google_fonts/google_fonts.dart';

class NeumorphismTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: GoogleFonts.notoSansScTextTheme().copyWith(
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: AppColors.textSecondary),
      dividerColor: AppColors.windowBorder.withOpacity(0.3),
      splashFactory: InkRipple.splashFactory,
    );
  }
}

class NeuShadow {
  static List<BoxShadow> convex({double blur = 12, double spread = 0, Offset offset = const Offset(4, 4)}) {
    return [
      BoxShadow(
        color: AppColors.shadowDark.withOpacity(0.5),
        offset: offset,
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: AppColors.shadowLight.withOpacity(0.9),
        offset: Offset(-offset.dx, -offset.dy),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> concave({double blur = 10, double spread = 0}) {
    return [
      BoxShadow(
        color: AppColors.shadowDark.withOpacity(0.45),
        offset: const Offset(3, 3),
        blurRadius: blur,
        spreadRadius: spread,
        blurStyle: BlurStyle.inner,
      ),
      BoxShadow(
        color: AppColors.shadowLight.withOpacity(0.85),
        offset: const Offset(-3, -3),
        blurRadius: blur,
        spreadRadius: spread,
        blurStyle: BlurStyle.inner,
      ),
    ];
  }

  static List<BoxShadow> flat({double blur = 6}) {
    return [
      BoxShadow(
        color: AppColors.shadowDark.withOpacity(0.3),
        offset: const Offset(2, 2),
        blurRadius: blur,
      ),
      BoxShadow(
        color: AppColors.shadowLight.withOpacity(0.7),
        offset: const Offset(-2, -2),
        blurRadius: blur,
      ),
    ];
  }
}
