/// The reader's visual voice: parchment, ink, and gold leaf.
///
/// The app used stock Material indigo, which reads as "utility app" — fine for
/// a settings screen, wrong for a page someone opens to sit with for twenty
/// quiet minutes. This replaces it with a half-tone palette: warm, low-contrast
/// tonal steps rather than saturated fills, hairline borders rather than
/// shadows, and a book serif for anything that carries scripture.
///
/// Two rules hold the whole thing together, and breaking either is what makes
/// a religious interface look cheap:
///
/// 1. **Gold is an accent, never a fill.** It appears in rules, small icons,
///    verse numbers, and focus states. A large gold surface reads as gaudy.
/// 2. **Nothing is pure black or pure white.** Both are warmed slightly, so
///    the page looks like paper under lamplight instead of a backlit screen.
library;

import 'package:flutter/material.dart';

/// Body font. Bundled with the app, so it works offline — `google_fonts`
/// would fetch over the network and break the offline-first promise.
const String _serif = 'Gentium';

/// Scripts Gentium has no glyphs for. Falling back to the platform font is
/// far better than rendering tofu in a Bible.
const Set<String> _nonLatinInterfaceLanguages = {'zh', 'ko', 'ru'};

class AppTheme {
  const AppTheme._();

  // --- Parchment (light) ---
  static const _inkDark = Color(0xFF211D17);
  static const _inkMuted = Color(0xFF5B5346);
  static const _parchment = Color(0xFFF7F2E8);
  static const _parchmentRaised = Color(0xFFFDFAF3);
  static const _parchmentSunk = Color(0xFFEFE7D8);
  // Darker than the original 0xFF8A6D25, which measured 4.38:1 on parchment —
  // under the 4.5:1 AA floor, and this is the colour the Hebrew and Greek text
  // itself is set in, because every word in the database carries a Strong's
  // number. Chosen to clear 4.5:1 against *every* light surface, not only the
  // page: 5.34 on surface, 5.72 raised, 4.85 sunk, 4.55 on the highest
  // container. Visually the same gold.
  static const _goldLight = Color(0xFF7A6021);
  static const _goldLightContainer = Color(0xFFEFE1BE);
  static const _lapis = Color(0xFF3E5171);
  static const _lapisContainer = Color(0xFFDCE3EF);
  static const _hairlineLight = Color(0xFFDDD2BC);

  // --- Night office (dark) ---
  static const _nightSurface = Color(0xFF14120E);
  static const _nightRaised = Color(0xFF1E1B15);
  static const _nightSunk = Color(0xFF272319);
  static const _paleInk = Color(0xFFEDE5D4);
  static const _paleInkMuted = Color(0xFFB6AC97);
  static const _goldDark = Color(0xFFD9BC72);
  static const _goldDarkContainer = Color(0xFF473A1C);
  static const _lapisDark = Color(0xFFA9BEDF);
  static const _lapisDarkContainer = Color(0xFF2C3A50);
  static const _hairlineDark = Color(0xFF3B3529);

  /// Returns null for scripts the bundled serif cannot render, letting the
  /// platform pick a font that can.
  static String? fontFamilyFor(String appLanguage) {
    final normalized = appLanguage.trim().toLowerCase();
    return _nonLatinInterfaceLanguages.contains(normalized) ? null : _serif;
  }

  static ThemeData light(String appLanguage) =>
      _build(_lightScheme, fontFamilyFor(appLanguage));

  static ThemeData dark(String appLanguage) =>
      _build(_darkScheme, fontFamilyFor(appLanguage));

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _goldLight,
    onPrimary: Color(0xFFFFFBF2),
    primaryContainer: _goldLightContainer,
    onPrimaryContainer: Color(0xFF2E2408),
    secondary: _lapis,
    onSecondary: Color(0xFFFFFBF2),
    secondaryContainer: _lapisContainer,
    onSecondaryContainer: Color(0xFF16202F),
    tertiary: Color(0xFF7A5545),
    onTertiary: Color(0xFFFFFBF2),
    tertiaryContainer: Color(0xFFF2DFD5),
    onTertiaryContainer: Color(0xFF2C1911),
    error: Color(0xFF8C2F2A),
    onError: Color(0xFFFFFBF2),
    errorContainer: Color(0xFFF6DAD7),
    onErrorContainer: Color(0xFF370F0C),
    surface: _parchment,
    onSurface: _inkDark,
    surfaceContainerLowest: _parchmentRaised,
    surfaceContainerLow: Color(0xFFF9F4EB),
    surfaceContainer: Color(0xFFF3EDE1),
    surfaceContainerHigh: _parchmentSunk,
    surfaceContainerHighest: Color(0xFFE9E0CE),
    onSurfaceVariant: _inkMuted,
    outline: Color(0xFF8C8371),
    outlineVariant: _hairlineLight,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2B2720),
    onInverseSurface: Color(0xFFF5EFE3),
    inversePrimary: _goldDark,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _goldDark,
    onPrimary: Color(0xFF2A2008),
    primaryContainer: _goldDarkContainer,
    onPrimaryContainer: Color(0xFFF6E5BC),
    secondary: _lapisDark,
    onSecondary: Color(0xFF13202F),
    secondaryContainer: _lapisDarkContainer,
    onSecondaryContainer: Color(0xFFDCE6F6),
    tertiary: Color(0xFFDCB6A3),
    onTertiary: Color(0xFF3A2318),
    tertiaryContainer: Color(0xFF4E3428),
    onTertiaryContainer: Color(0xFFF7DFD4),
    error: Color(0xFFE7A6A0),
    onError: Color(0xFF44100C),
    errorContainer: Color(0xFF62231E),
    onErrorContainer: Color(0xFFF9DAD6),
    surface: _nightSurface,
    onSurface: _paleInk,
    surfaceContainerLowest: Color(0xFF0F0D0A),
    surfaceContainerLow: _nightRaised,
    surfaceContainer: Color(0xFF221E17),
    surfaceContainerHigh: _nightSunk,
    surfaceContainerHighest: Color(0xFF322D21),
    onSurfaceVariant: _paleInkMuted,
    outline: Color(0xFF8A8171),
    outlineVariant: _hairlineDark,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEDE5D4),
    onInverseSurface: Color(0xFF211D17),
    inversePrimary: _goldLight,
  );

  static ThemeData _build(ColorScheme scheme, String? fontFamily) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
    );

    // Scripture is read slowly. Everything gets more air than Material's
    // defaults give it, and headings are set in the serif at a weight that
    // reads as engraved rather than shouted.
    final text = base.textTheme
        .apply(fontFamily: fontFamily)
        .copyWith(
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
            height: 1.2,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
          labelLarge: base.textTheme.labelLarge?.copyWith(letterSpacing: 0.4),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        // A hairline instead of a shadow: the page should look like paper, and
        // paper does not float.
        shape: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.6),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant, width: 0.8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.6,
        space: 0.6,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        // Five destinations, four of them unlabelled, with a bookmark and a
        // book icon side by side: hiding the labels bought nothing here.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            letterSpacing: 0.3,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant, width: 0.8),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// A hairline rule with a small gold diamond at its centre.
///
/// Used to separate sections without the visual weight of a [Divider]; it is
/// the one place the palette's gold is allowed to be decorative.
class DivineRule extends StatelessWidget {
  const DivineRule({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Expanded(
      child: Container(height: 0.8, color: scheme.outlineVariant),
    );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Transform.rotate(
              angle: 0.785398, // 45°, so the square reads as a diamond
              child: Container(
                width: 5,
                height: 5,
                color: scheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}
