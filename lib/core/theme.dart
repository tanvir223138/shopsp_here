import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4F46E5); // indigo
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color sale = Color(0xFFF43F5E); // discounts, low stock
  static const Color lightBg = Color(0xFFF5F6FA);
  static const Color darkBg = Color(0xFF0E1014);
  static const Color darkCard = Color(0xFF171A21);
  static const Color success = Color(0xFF10B981);
  static const Color star = Color(0xFFFFB400);
  static const Color lightBorder = Color(0xFFE8EAF2);
  static const Color darkBorder = Color(0xFF262A33);
}

extension ThemeX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get cardBg => isDarkMode ? AppColors.darkCard : Colors.white;
  Color get mutedText => isDarkMode ? Colors.white60 : Colors.black54;
  Color get borderColor => isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
}

/// Shared card decoration: soft border, rounded corners, no heavy shadow.
BoxDecoration cardDecoration(BuildContext context, {double radius = 12}) => BoxDecoration(
  color: context.cardBg,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: context.borderColor),
);

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(primary: AppColors.primary, onPrimary: Colors.white);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.darkBg : AppColors.lightBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        backgroundColor: dark ? AppColors.darkCard : Colors.white,
        foregroundColor: dark ? Colors.white : Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: dark ? Colors.white : Colors.black87,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? AppColors.darkCard : Colors.white,
        indicatorColor: AppColors.primary.withAlpha(36),
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        height: 66,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: dark ? AppColors.darkBorder : AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? AppColors.darkBorder : AppColors.lightBorder,
        space: 1,
        thickness: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: border(dark ? Colors.white24 : Colors.black26),
        enabledBorder: border(dark ? Colors.white24 : Colors.black26),
        focusedBorder: border(AppColors.primary, 1.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
