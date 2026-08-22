import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────
/// AppTheme — Sistem Desain Premium Fem-Psych Monitor
///
/// Palet terpadu dengan tema "Resonance" (warm rose — sophisticated):
///   • Background  : Warm off-white #FAF6F3 → bersih, hangat
///   • Primary     : Rose #D6336C          → aksen utama
///   • Container   : Blush #FFDCE7         → aksen lembut
///   • Surface     : Putih hangat + border outline lembut
///
/// Tipografi: Poppins (Google Fonts) — modern, premium, rounded
/// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._(); // Prevent instantiation

  // ── Warna Utama (Resonance Rose Dusty) ───────────────────────
  static const Color primaryColor = Color(
    0xFFC77E8C,
  ); // Resonance primary (dusty rose)
  static const Color primaryLight = Color(
    0xFFF0D9DE,
  ); // Dusty blush / primaryContainer
  static const Color primaryDark = Color(
    0xFFA05A6B,
  ); // Deep dusty rose (untuk teks/ikon — kontras lebih baik)
  static const Color secondaryColor = Color(
    0xFFD9A3AE,
  ); // Soft dusty rose
  static const Color accentColor = Color(
    0xFFE2B6BF,
  ); // Dusty pink accent (Resonance dark primary)

  // ── Warna Surface & Background ──────────────────────────────
  static const Color backgroundColor = Color(0xFFFAF6F3); // Warm off-white
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1EAE6); // Warm gray

  // ── Warna Teks ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF24161C); // Warm near-black
  static const Color textSecondary = Color(0xFF5E4B53); // Warm gray-brown
  static const Color textHint = Color(0xFFBBA8A1); // Soft outline tone

  // ── Warna Emosi (Pastel — lembut, feminin, ramah) ───────────
  static const Map<String, Color> emotionColors = {
    'Happy': Color(0xFFFCD34D), // Pastel Yellow
    'Sad': Color(0xFF93C5FD), // Pastel Blue
    'Angry': Color(0xFFFCA5A5), // Pastel Red
    'Disgust': Color(0xFF6EE7B7), // Pastel Green
    'Neutral': Color(0xFFCBD5E1), // Pastel Slate
    'Fear': Color(0xFFC4B5FD), // Pastel Lavender
  };

  // ── Warna Emosi Background (pastel lebih terang) ─────────────
  static const Map<String, Color> emotionBgColors = {
    'Happy': Color(0xFFFEF9C3), // Yellow-50
    'Sad': Color(0xFFDBEAFE), // Blue-50
    'Angry': Color(0xFFFEE2E2), // Red-50
    'Disgust': Color(0xFFD1FAE5), // Emerald-50
    'Neutral': Color(0xFFF1F5F9), // Slate-50
    'Fear': Color(0xFFEDE9FE), // Violet-50
  };

  // ── Gradien Utama (Rose → Coral) ──────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [primaryLight, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient recordingGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient Background untuk seluruh screen
  static const LinearGradient lightGradientBackground = LinearGradient(
    colors: [
      Color(0xFFFAF6F3), // Warm off-white
      Color(0xFFF9ECEE), // Blush hint
      Color(0xFFF7E9EC), // Pink-50 warm
      Color(0xFFFAF6F3), // Warm off-white
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient darkGradientBackground = LinearGradient(
    colors: [
      Color(0xFF211B1E), // Dark warm brown
      Color(0xFF2E2226), // Dark plum
      Color(0xFF211B1E), // Dark warm brown
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ── Shadow Reusable (theme-aware) ─────────────────────────────
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? const Color(0x4D000000) // Darker, more visible shadow for dark mode
        : const Color(0x1424161C);
    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: isDark ? 8 : 0,
        spreadRadius: isDark ? -2 : 0,
        offset: const Offset(2, 2),
      ),
    ];
  }

  static List<BoxShadow> primaryShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? const Color(0x66000000)
        : const Color(0x4024161C);
    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: isDark ? 12 : 0,
        spreadRadius: isDark ? -3 : 0,
        offset: const Offset(4, 4),
      ),
    ];
  }

  // Legacy getters for backward compatibility (default to light mode)
  static List<BoxShadow> get cardShadowLight => [
    BoxShadow(
      color: const Color(0x1424161C),
      blurRadius: 0,
      spreadRadius: 0,
      offset: const Offset(2, 2),
    ),
  ];

  static List<BoxShadow> get primaryShadowLight => [
    BoxShadow(
      color: const Color(0x4024161C),
      blurRadius: 0,
      spreadRadius: 0,
      offset: const Offset(4, 4),
    ),
  ];

  // ── Border Radius Tokens ─────────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // ── Spacing Tokens ───────────────────────────────────────────
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 24.0;
  static const double space2xl = 32.0;

  /// ── ThemeData Lengkap ────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);

    // Space Grotesk (judul) + Inter (isi)
    final brandText = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primaryColor,
            primary: primaryColor,
            secondary: secondaryColor,
            surface: surfaceColor,
            brightness: Brightness.light,
          ).copyWith(
            primaryContainer: Color(0xFFF0D9DE),
            secondaryContainer: Color(0xFFF0D9DE),
          ),
      scaffoldBackgroundColor: Colors.transparent, // Use gradient decorator
      // ── Decorator untuk gradient background ───────────────
      pageTransitionsTheme: PageTransitionsTheme(
        builders: Map.fromEntries(
          TargetPlatform.values.map(
            (platform) =>
                MapEntry(platform, const CupertinoPageTransitionsBuilder()),
          ),
        ),
      ),

      // ── Tipografi Space Grotesk + Inter ────────────────────
      textTheme: brandText.copyWith(
        // Heading besar (dashboard title)
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        // Section heading
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        // Card title
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.1,
        ),
        // Body teks
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textHint,
        ),
        // Label untuk tombol / chip
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.3,
        ),
      ),

      // ── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Bottom Navigation Bar ──────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryDark,
        unselectedItemColor: Color(0xFFCBD5E1), // Slate-300
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // ── AppBar ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        foregroundColor: textPrimary,
      ),

      // ── Input Decoration ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
      ),

      // ── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2D7D1), // Warm outline
        space: 1,
        thickness: 1,
      ),
    );
  }

  // ── Warna Dark Mode (Resonance warm dark) ─────────────────────
  static const Color darkBackground = Color(0xFF211B1E); // Warm near-black
  static const Color darkSurface = Color(0xFF2A2226); // Warm dark surface
  static const Color darkCard = Color(0xFF332A2E); // Warm dark card
  static const Color darkSurfaceVar = Color(0xFF3A2E33); // Warm dark variant
  static const Color darkTextPrimary = Color(0xFFF4EDF0); // Warm white 92%
  static const Color darkTextSecondary = Color(0xFFCBBBC1); // Warm gray 70%
  static const Color darkTextHint = Color(0xFF8C7075); // Warm gray 45%

  /// ── ThemeData Dark ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final brandText = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primaryColor,
            primary: primaryColor,
            secondary: secondaryColor,
            surface: darkSurface,
            brightness: Brightness.dark,
          ).copyWith(
            primaryContainer: const Color(0xFF5C0E2F),
            secondaryContainer: const Color(0xFF5C0E2F),
          ),
      scaffoldBackgroundColor: Colors.transparent, // Use gradient decorator

      textTheme: brandText.copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleSmall: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: darkTextHint,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
          letterSpacing: 0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF616161),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
        foregroundColor: darkTextPrimary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF4A3B41),
        space: 1,
        thickness: 1,
      ),
    );
  }

  // ── Helper: warna adaptif berdasarkan brightness ────────────
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkBackground
      : backgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSurface
      : surfaceColor;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : cardColor;

  static Color textP(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextPrimary
      : textPrimary;

  static Color textS(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextSecondary
      : textSecondary;

  static Color textH(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextHint : textHint;

  static Color iconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? primaryColor
      : primaryDark;

  static Color surfVar(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSurfaceVar
      : surfaceVariant;
}
