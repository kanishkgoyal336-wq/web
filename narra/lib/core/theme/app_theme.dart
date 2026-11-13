import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Material 3 is kept for its widgets, but tinted surfaces, elevation and
/// splash effects are turned off so components render flat like the reference.
ThemeData buildNarraTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NarraColors.primary,
    primary: NarraColors.primary,
    onPrimary: NarraColors.onPrimary,
    surface: NarraColors.surface,
    onSurface: NarraColors.textPrimary,
  ).copyWith(surfaceTint: Colors.transparent);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: NarraColors.surface,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: NarraColors.surfaceMuted,
    dividerTheme: const DividerThemeData(color: NarraColors.divider, thickness: 1, space: 1),
    textTheme: TextTheme(bodyMedium: NarraText.body, bodyLarge: NarraText.body),
    dialogTheme: DialogThemeData(
      backgroundColor: NarraColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: NarraColors.surface,
      surfaceTintColor: Colors.transparent,
      textStyle: NarraText.control,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: NarraColors.textPrimary,
      contentTextStyle: narraText(14, color: NarraColors.onPrimary),
    ),
  );
}
