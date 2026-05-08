import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class CustomColors extends ThemeExtension<CustomColors> {
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color primary;
  final List<Color> primaryGradient;
  final Color secondary;
  final List<Color> secondaryGradient;
  final Color accent;
  final Color error;
  final Color border;
  final Color card;
  final Color muted;
  final Color white;
  final Color glass;
  final Color warning;
  final Color info;
  final Color success;
  final Color successContainer;
  final Color warningContainer;
  final Color errorContainer;
  final Color infoContainer;

  CustomColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.primary,
    required this.primaryGradient,
    required this.secondary,
    required this.secondaryGradient,
    required this.accent,
    required this.error,
    required this.border,
    required this.card,
    required this.muted,
    required this.white,
    required this.glass,
    required this.warning,
    required this.info,
    required this.success,
    required this.successContainer,
    required this.warningContainer,
    required this.errorContainer,
    required this.infoContainer,
  });

  @override
  CustomColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? textSecondary,
    Color? primary,
    List<Color>? primaryGradient,
    Color? secondary,
    List<Color>? secondaryGradient,
    Color? accent,
    Color? error,
    Color? border,
    Color? card,
    Color? muted,
    Color? white,
    Color? glass,
    Color? warning,
    Color? info,
    Color? success,
    Color? successContainer,
    Color? warningContainer,
    Color? errorContainer,
    Color? infoContainer,
  }) {
    return CustomColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondary: secondary ?? this.secondary,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      accent: accent ?? this.accent,
      error: error ?? this.error,
      border: border ?? this.border,
      card: card ?? this.card,
      muted: muted ?? this.muted,
      white: white ?? this.white,
      glass: glass ?? this.glass,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      errorContainer: errorContainer ?? this.errorContainer,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryGradient: primaryGradient,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryGradient: secondaryGradient,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
      border: Color.lerp(border, other.border, t)!,
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      white: Color.lerp(white, other.white, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }

  // Deep black professional palette
  static final light = CustomColors(
    background: const Color(0xFFFFFFFF),
    surface: const Color(0xFFF8F9FA),
    text: const Color(0xFF000000),
    textSecondary: const Color(0xFF4B5563),
    primary: const Color(0xFF000000),
    primaryGradient: [const Color(0xFF000000), const Color(0xFF1A1A1A)],
    secondary: const Color(0xFFE2E8F0),
    secondaryGradient: [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
    accent: const Color(0xFF111827),
    error: const Color(0xFFDC2626),
    border: const Color(0xFFE2E8F0),
    card: const Color(0xFFFFFFFF),
    muted: const Color(0xFF94A3B8),
    white: const Color(0xFFFFFFFF),
    glass: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
    warning: const Color(0xFFD97706),
    info: const Color(0xFF2563EB),
    success: const Color(0xFF059669),
    successContainer: const Color(0xFFDCFCE7),
    warningContainer: const Color(0xFFFEF3C7),
    errorContainer: const Color(0xFFFEE2E2),
    infoContainer: const Color(0xFFDBEAFE),
  );

  // Deep black dark palette
  static final dark = CustomColors(
    background: const Color(0xFF000000),
    surface: const Color(0xFF121212),
    text: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFF94A3B8),
    primary: const Color(0xFFFFFFFF),
    primaryGradient: [const Color(0xFFFFFFFF), const Color(0xFFE2E8F0)],
    secondary: const Color(0xFF1E293B),
    secondaryGradient: [const Color(0xFF334155), const Color(0xFF1E293B)],
    accent: const Color(0xFFF8FAFC),
    error: const Color(0xFFEF4444),
    border: const Color(0xFF334155),
    card: const Color(0xFF121212),
    muted: const Color(0xFF64748B),
    white: const Color(0xFFFFFFFF),
    glass: const Color(0xFF000000).withValues(alpha: 0.8),
    warning: const Color(0xFFFBBF24),
    info: const Color(0xFF60A5FA),
    success: const Color(0xFF34D399),
    successContainer: const Color(0xFF064E3B),
    warningContainer: const Color(0xFF78350F),
    errorContainer: const Color(0xFF7F1D1D),
    infoContainer: const Color(0xFF1E3A8A),
  );
}

class AppTheme {
  static ThemeData getTheme(bool isDarkMode) {
    final colors = isDarkMode ? CustomColors.dark : CustomColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Inter',
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: isDarkMode ? Colors.black : Colors.white,
        secondary: colors.secondary,
        onSecondary: isDarkMode ? Colors.white : Colors.black,
        error: colors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.text,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          height: 1.1,
          color: colors.text,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: colors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: colors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.0,
          color: colors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5, // More subtle borders like premium native apps
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.text),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.text,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
