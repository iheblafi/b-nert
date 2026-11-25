import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Calm and professional: navy and white, generous space, soft shadows.
/// Brand values are placeholders until the client sends its style guide.
abstract final class AppColors {
  static const brand = Color(0xFF1F5F99);
  static const navy = Color(0xFF0B2545);
  static const mint = Color(0xFF5EE6A8);
  static const success = Color(0xFF2E7D4F);
  static const warning = Color(0xFFB26A00);

  // Light
  static const canvas = Color(0xFFF5F7FB);
  static const field = Color(0xFFEEF2F7);
  static const line = Color(0xFFE1E7EF);

  // Dark: deep navy instead of grey, so the brand carries through.
  static const darkCanvas = Color(0xFF0A1220);
  static const darkSurface = Color(0xFF111B2E);
  static const darkRaised = Color(0xFF17243B);
  static const darkField = Color(0xFF1C2B45);
  static const darkLine = Color(0xFF26375A);
  static const darkPrimary = Color(0xFF8CB8EC);
}

abstract final class Gap {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

abstract final class Radii {
  static const field = 14.0;
  static const card = 22.0;
  static const sheet = 28.0;
}

/// Soft, low shadow for raised cards: navy-tinted, never black.
List<BoxShadow> softShadow(Brightness brightness) =>
    brightness == Brightness.dark
    ? const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ]
    : const [
        BoxShadow(
          color: Color(0x140B2545),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Color(0x0A0B2545),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];

/// Status and navigation bar colours that contrast with [theme]'s surface.
/// Android 15 draws apps edge to edge and ignores the bar colour, so the
/// icon brightness is what keeps the buttons visible.
SystemUiOverlayStyle systemBarsFor(ThemeData theme) {
  final dark = theme.brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: theme.brightness, // iOS
    systemNavigationBarColor: theme.colorScheme.surface,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: dark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Light icons on a dark background, for the splash and navy headers.
const systemBarsOnDark = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark, // iOS
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness b) {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: b,
    );
    return b == Brightness.light
        ? base.copyWith(
            primary: AppColors.brand,
            onPrimary: Colors.white,
            secondary: AppColors.navy,
            tertiary: AppColors.mint,
            surface: Colors.white,
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: AppColors.canvas,
            surfaceContainer: AppColors.canvas,
            surfaceContainerHighest: AppColors.field,
            outlineVariant: AppColors.line,
          )
        : base.copyWith(
            primary: AppColors.darkPrimary,
            onPrimary: AppColors.navy,
            secondary: AppColors.darkPrimary,
            tertiary: AppColors.mint,
            surface: AppColors.darkSurface,
            surfaceContainerLowest: AppColors.darkCanvas,
            surfaceContainerLow: AppColors.darkCanvas,
            surfaceContainer: AppColors.darkSurface,
            surfaceContainerHigh: AppColors.darkRaised,
            surfaceContainerHighest: AppColors.darkField,
            outlineVariant: AppColors.darkLine,
          );
  }

  static TextTheme _text(TextTheme t) => t
      .apply(fontFamily: fontFamily)
      .copyWith(
        displaySmall: t.displaySmall?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: t.labelLarge?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      );

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);
    final dark = brightness == Brightness.dark;
    final base = ThemeData(brightness: brightness, colorScheme: scheme);
    final text = _text(base.textTheme);
    // Touch targets of at least 48 dp (spec section 9).
    const minSize = Size(48, 48);
    final fieldRadius = BorderRadius.circular(Radii.field);
    final buttonShape = RoundedRectangleBorder(borderRadius: fieldRadius);
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.darkField : AppColors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.m,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: buttonShape,
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: buttonShape,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minSize),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? AppColors.darkRaised : Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.field),
        ),
        iconColor: scheme.primary,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? AppColors.darkRaised : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.field),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: dark ? AppColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
