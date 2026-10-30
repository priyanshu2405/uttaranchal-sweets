// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens sampled directly from the Uttaranchal XD/SVG screens.
class AppColors {
  AppColors._();

  static const cream = Color(0xFFFFF9ED); // page background
  static const header = Color(0xFFFFF6E4); // app bar / bottom bar
  static const surface = Color(0xFFFFFDF5); // cards & inputs
  static const ink = Color(0xFF472F3B); // primary text
  static const muted = Color(0xFF8B7770); // secondary text
  static const berry = Color(0xFFA81656); // brand primary
  static const teal = Color(0xFF007F7C); // brand secondary
  static const tealDark = Color(0xFF00746F);
  static const yellow = Color(0xFFFFCD45); // brand accent
  static const yellowSoft = Color(0xFFFFF0C8);
  static const purple = Color(0xFF602462); // rewards
  static const border = Color(0xFFEAD0A9);
  static const borderSoft = Color(0xFFECDFC9);
  static const mint = Color(0xFFDFF0E7);
  static const peach = Color(0xFFF9E8CD);
  static const pink = Color(0xFFF8DFE8);
  static const mapBg = Color(0xFFE7EDDF);
  static const white = Color(0xFFFFFFFF);
  static const whiteSoft = Color(0xCCFFFFFF);
}

class AppFonts {
  AppFonts._();
  static const serif = 'CormorantGaramond';
  static const sans = 'DMSans';
  static const deva = 'NotoSerifDevanagari';
}

/// Typography helpers – keep every screen consistent with the design system.
class T {
  T._();

  static TextStyle display(double size, {Color color = AppColors.berry, FontWeight weight = FontWeight.w600, bool italic = false, double height = 1.05}) =>
      TextStyle(
        fontFamily: AppFonts.serif,
        fontSize: size,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color,
        height: height,
      );

  static TextStyle sans(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w400, double height = 1.4, double spacing = 0}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );

  static TextStyle body([Color color = AppColors.muted]) => sans(13, color: color, height: 1.55);
  static TextStyle small([Color color = AppColors.muted]) => sans(11, color: color, height: 1.45);
  static TextStyle tiny([Color color = AppColors.muted]) => sans(10, color: color, height: 1.45);
  static TextStyle label([Color color = AppColors.ink]) => sans(12, color: color, weight: FontWeight.w500);
  static TextStyle eyebrow([Color color = AppColors.teal]) => sans(9.5, color: color, weight: FontWeight.w700, spacing: 1.6);
  static TextStyle title([Color color = AppColors.ink]) => sans(13.5, color: color, weight: FontWeight.w600);
  static TextStyle deva(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: AppFonts.deva, fontSize: size, color: color, fontWeight: weight);
}

class AppTheme {
  AppTheme._();

  static const overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
    systemNavigationBarColor: AppColors.header,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.berry,
      primary: AppColors.berry,
      secondary: AppColors.teal,
      surface: AppColors.surface,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: AppFonts.sans,
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.berry),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: T.sans(13, color: AppColors.white, weight: FontWeight.w500),
        actionTextColor: AppColors.yellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.berry,
        headerForegroundColor: AppColors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.berry : Colors.transparent),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.teal : AppColors.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
