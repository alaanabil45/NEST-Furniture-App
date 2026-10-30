import 'package:flutter/material.dart';

abstract final class NestColors {
  static const Color cobalt = Color(0xFF2855D9);
  static const Color butter = Color(0xFFF4C95D);
  static const Color coral = Color(0xFFF07854);
  static const Color cream = Color(0xFFF8F3E8);
  static const Color charcoal = Color(0xFF252923);
  static const Color softGreen = Color(0xFFA8BFA0);

  // Supporting neutrals
  static const Color creamDeep = Color(0xFFEFE6D2);
  static const Color muted = Color(0xFF6A6E65);
  static const Color line = Color(0x33252923);
}

abstract final class NestMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 560);
  static const Duration stagger = Duration(milliseconds: 70);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve press = Curves.easeOut;
}

abstract final class NestText {
  static const String _serif = 'InstrumentSerif';
  static const String _sans = 'Lato';

  /// Editorial serif headline at any size.
  static TextStyle display(double size) => TextStyle(
    fontFamily: _serif,
    fontSize: size,
    height: 0.98,
    letterSpacing: -size * 0.015,
    color: NestColors.charcoal,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.45,
    color: NestColors.muted,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: NestColors.charcoal,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: NestColors.charcoal,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: NestColors.charcoal,
  );
}

ThemeData buildNestTheme() {
  final scheme = const ColorScheme.light(
    primary: NestColors.cobalt,
    onPrimary: NestColors.cream,
    secondary: NestColors.butter,
    onSecondary: NestColors.charcoal,
    tertiary: NestColors.coral,
    onTertiary: NestColors.charcoal,
    surface: NestColors.cream,
    onSurface: NestColors.charcoal,
    error: Color(0xFFB3261E),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Lato',
    scaffoldBackgroundColor: NestColors.cream,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: NestColors.cobalt,
      selectionHandleColor: NestColors.cobalt,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: NestColors.cobalt,
      inactiveTrackColor: Color(0xFFDCD3BD),
      thumbColor: NestColors.cobalt,
      overlayColor: Color(0x1F2855D9),
      trackHeight: 6,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll<Color>(NestColors.cream),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (states) => states.contains(WidgetState.selected)
            ? NestColors.cobalt
            : const Color(0xFFCFC6B0),
      ),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: NestColors.cream,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: NestColors.line,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
  );
}
