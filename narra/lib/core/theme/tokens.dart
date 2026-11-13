import 'package:material_ui/material_ui.dart';

/// Design tokens measured from the reference screenshots.
///
/// The reference captures were taken at ~1.357 device pixels per CSS pixel, so
/// every value here is the measured pixel value divided by 1.357 and rounded to
/// the nearest sensible unit. Colours were sampled directly from the captures.
abstract final class NarraColors {
  static const primary = Color(0xFF2E43F9);
  static const onPrimary = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF777777);

  static const surface = Color(0xFFFFFFFF);

  /// Pills, the active navigation item and the reader canvas.
  static const surfaceMuted = Color(0xFFF6F6F6);

  static const sidebarBorder = Color(0xFFEBEBEB);
  static const divider = Color(0xFFEEEEEE);
  static const checkboxBorder = Color(0xFFDCDCDC);

  static const avatar = Color(0xFF522EAC);

  /// Read-along highlights (reader, milestone 3).
  static const sentenceHighlight = Color(0xFFDFE4FF);
  static const wordHighlight = Color(0xFF959FFD);

  // "Create" tiles: background / icon pairs.
  static const documentTile = Color(0xFFE7E8FE);
  static const documentIcon = Color(0xFF3252E0);
  static const podcastTile = Color(0xFFEDEFFE);
  static const podcastIcon = Color(0xFF5464D5);
  static const quizTile = Color(0xFFFDEAFE);
  static const quizIcon = Color(0xFFB12ABE);
  static const summaryTile = Color(0xFFFDF1DC);
  static const summaryIcon = Color(0xFFE58411);

  static const thumbnailShadow = Color(0x26000000);
}

abstract final class NarraSizes {
  static const sidebarWidth = 280.0;
  static const sidebarPadding = 12.0;
  static const controlHeight = 40.0;
  static const navItemGap = 2.0;
  static const profileHeight = 78.0;

  static const homeContentMaxWidth = 720.0;
  static const homeThumbnail = Size(73, 101);
  static const homeTitleBlockHeight = 44.0;

  static const createTile = 66.0;
  static const createTileRadius = 18.0;
  static const createCardPadding = 12.0;

  static const libraryHeaderHeight = 62.0;
  static const librarySortRowHeight = 33.0;
  static const libraryColumnWidth = 234.0;
  static const libraryThumbnail = Size(102, 145);
  static const libraryGridPadding = 12.0;
  static const libraryRunSpacing = 48.0;
  static const libraryTitleMaxWidth = 185.0;

  static const readerTopBarHeight = 62.0;

  /// Below this width the sidebar moves into a drawer.
  static const compactBreakpoint = 768.0;
}

/// Inter is a variable font, so the weight is applied both as a [FontWeight]
/// (for metrics and fallback fonts) and as an explicit `wght` axis value.
TextStyle narraText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = NarraColors.textPrimary,
  double? lineHeight,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: lineHeight == null ? null : lineHeight / size,
    letterSpacing: letterSpacing,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

abstract final class NarraText {
  static final sectionHeading = narraText(24, weight: FontWeight.w500, lineHeight: 32, letterSpacing: -0.9);
  static final pageTitle = narraText(18, weight: FontWeight.w600, lineHeight: 24, letterSpacing: -0.5);
  static final nav = narraText(14, weight: FontWeight.w500, lineHeight: 20, letterSpacing: -0.3);
  static final button = narraText(15, weight: FontWeight.w500, lineHeight: 20, letterSpacing: -0.55);
  static final cardTitle = narraText(15, weight: FontWeight.w500, lineHeight: 22, letterSpacing: -0.6);
  static final cardBody = narraText(14, color: NarraColors.textSecondary, lineHeight: 20, letterSpacing: -0.15);
  static final thumbnailTitle = narraText(15, lineHeight: 22);
  static final libraryTitle = narraText(14, lineHeight: 20, letterSpacing: -0.15);
  static final libraryMeta = narraText(12, color: NarraColors.textSecondary, lineHeight: 16);
  static final groupHeading = narraText(14, weight: FontWeight.w600, lineHeight: 20, letterSpacing: -0.1);
  static final control = narraText(14, weight: FontWeight.w500, lineHeight: 20, letterSpacing: -0.7);
  static final profileName = narraText(15, weight: FontWeight.w500, lineHeight: 22);
  static final profilePlan = narraText(14, color: NarraColors.textSecondary, lineHeight: 22);
  static final readerTitle = narraText(14, weight: FontWeight.w600, lineHeight: 20);
  static final body = narraText(16, lineHeight: 26);
}
