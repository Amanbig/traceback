import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/threat_report.dart';

/// Global theme mode controller and state persistence
class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('setting_theme_mode');
      if (saved == 'light') {
        mode.value = ThemeMode.light;
      } else if (saved == 'dark') {
        mode.value = ThemeMode.dark;
      } else if (saved == 'system') {
        mode.value = ThemeMode.system;
      } else {
        mode.value = ThemeMode.dark;
      }
    } catch (_) {}
  }

  static Future<void> setTheme(ThemeMode newMode) async {
    mode.value = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = newMode == ThemeMode.light
          ? 'light'
          : newMode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await prefs.setString('setting_theme_mode', str);
    } catch (_) {}
  }
}

/// Design tokens shared across the app.
class AppColors {
  AppColors._();

  static const brand = Color(0xFF3B82F6);
  static const brandDeep = Color(0xFF1D4ED8);
  static const safe = Color(0xFF22C55E);
  static const warn = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Dark surfaces
  static const darkBg = Color(0xFF0A0F1C);
  static const darkSurface = Color(0xFF131B2E);
  static const darkSurfaceHigh = Color(0xFF1B2540);
  static const darkOutline = Color(0x1FFFFFFF);

  // Light surfaces
  static const lightBg = Color(0xFFF5F7FB);
  static const lightSurface = Colors.white;
  static const lightOutline = Color(0xFFE2E8F0);

  static Color forScore(int score) {
    if (score >= 70) return danger;
    if (score >= 40) return warn;
    return safe;
  }
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const screenH = 20.0;
}

extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get surfaceHighColor => isDark ? AppColors.darkSurfaceHigh : const Color(0xFFEEF2F8);
  Color get outlineColor => isDark ? AppColors.darkOutline : AppColors.lightOutline;
  Color get mutedText => isDark ? const Color(0xFF9AA7BD) : const Color(0xFF64748B);
}

extension ThreatLevelX on ThreatLevel {
  String get label {
    switch (this) {
      case ThreatLevel.safe:
        return 'Safe';
      case ThreatLevel.low:
        return 'Low risk';
      case ThreatLevel.suspicious:
        return 'Suspicious';
      case ThreatLevel.dangerous:
        return 'Dangerous';
      case ThreatLevel.critical:
        return 'Critical';
    }
  }
}

String relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? AppColors.darkBg : AppColors.lightBg;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final outline = dark ? AppColors.darkOutline : AppColors.lightOutline;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: b,
      surface: surface,
    );

    final base = ThemeData(brightness: b, useMaterial3: true);
    final text = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      displayColor: dark ? Colors.white : const Color(0xFF0F172A),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: outline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        hintStyle: TextStyle(color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: dark ? const Color(0xFF0D1424) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.brand.withOpacity(dark ? 0.22 : 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (dark ? const Color(0xFF93C5FD) : AppColors.brandDeep)
                : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          );
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
