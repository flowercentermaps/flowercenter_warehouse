import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static const _radius = 14.0;

  // ── Light theme — mirrors CRM's lightGoldTheme ───────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        colorScheme: const ColorScheme.light(
          primary: AppConstants.primaryColor,
          onPrimary: Colors.white,
          secondary: Color(0xFFD49D37),
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF1C1C1E),
          surfaceContainerHighest: Color(0xFFFFF8E7),
          primaryContainer: Color(0xFFFFF3D6),
          onPrimaryContainer: Color(0xFF3A2F0B),
          error: Color(0xFFFF3B30),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F2F7),
          foregroundColor: AppConstants.primaryColor,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: Color(0x14000000),
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 2,
          shadowColor: const Color(0xFFD49D37),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8D5A0), width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFD1D1D6),
          thickness: 0.5,
          space: 1,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.1),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFFE8D5A0)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            textStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8D5A0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8D5A0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppConstants.primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppConstants.dangerColor, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppConstants.dangerColor, width: 1.5),
          ),
          hintStyle:
              const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          labelStyle: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w500),
          prefixIconColor: AppConstants.primaryColor,
          suffixIconColor: AppConstants.primaryColor,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFFF8E7),
          selectedColor: AppConstants.primaryColor,
          disabledColor: const Color(0xFFEEEEEE),
          secondarySelectedColor: AppConstants.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: Color(0xFFE8D5A0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E)),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Color(0xFF8E8E93),
          labelStyle:
              TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          unselectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        iconTheme: const IconThemeData(color: AppConstants.primaryColor),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppConstants.primaryColor,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppConstants.primaryColor,
              letterSpacing: -0.5),
          titleLarge: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1C1C1E)),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1C1C1E)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF3C3C43)),
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          labelMedium: TextStyle(fontSize: 13, color: Color(0xFF3C3C43)),
        ),
      );

  // ── Dark theme — mirrors CRM's blackGoldTheme ────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0B),
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryColor,
          onPrimary: Color(0xFF111111),
          secondary: Color(0xFFFFD700),
          onSecondary: Color(0xFF111111),
          surface: Color(0xFF121212),
          onSurface: Color(0xFFF5E7B2),
          surfaceContainerHighest: Color(0xFF1C1C1C),
          primaryContainer: Color(0xFF3A2F0B),
          onPrimaryContainer: Color(0xFFF5E7B2),
          error: Color(0xFFCF6679),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0B0B),
          foregroundColor: AppConstants.primaryColor,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: Color(0x28000000),
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF141414),
          elevation: 3,
          shadowColor: Colors.black54,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF3A2F0B), width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF3A2F0B),
          thickness: 1,
          space: 1,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: const Color(0xFF111111),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.1),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: Color(0xFF4A3B12)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            textStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B0B0B),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: Color(0xFF6E5A1E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: Color(0xFF4A3B12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(
                color: AppConstants.primaryColor, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide:
                const BorderSide(color: AppConstants.dangerColor, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide:
                const BorderSide(color: AppConstants.dangerColor, width: 1.5),
          ),
          hintStyle:
              const TextStyle(color: Color(0xFFBFA75A), fontSize: 14),
          labelStyle: const TextStyle(
              color: Color(0xFFBFA75A),
              fontSize: 14,
              fontWeight: FontWeight.w500),
          prefixIconColor: AppConstants.primaryColor,
          suffixIconColor: AppConstants.primaryColor,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF181818),
          selectedColor: AppConstants.primaryColor,
          disabledColor: const Color(0xFF1F1F1F),
          secondarySelectedColor: AppConstants.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: Color(0xFF4A3B12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5E7B2)),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Color(0xFF6E5A1E),
          labelStyle:
              TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          unselectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        iconTheme: const IconThemeData(color: AppConstants.primaryColor),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppConstants.primaryColor,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppConstants.primaryColor,
              letterSpacing: -0.5),
          titleLarge: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFFF5E7B2)),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFFF5E7B2)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFF5E7B2)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFE8D89A)),
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFFBFA75A)),
          labelMedium: TextStyle(fontSize: 13, color: Color(0xFFF5E7B2)),
        ),
      );
}
