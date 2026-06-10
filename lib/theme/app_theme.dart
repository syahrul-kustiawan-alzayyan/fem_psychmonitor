import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────
/// AppTheme — Sistem Desain Premium Fem-Psych Monitor
///
/// Panduan Warna (Rose Pink — warm & sophisticated):
///   • Background  : Off-white #F8FAFC  → bersih, tidak melelahkan mata
///   • Primary     : Rose #E8728A       → warm pink elegan
///   • Secondary   : Coral #F4A7B5      → aksen lembut
///   • Emotion     : Palet pastel/muted agar tidak memicu kecemasan
///
/// Tipografi: Poppins (Google Fonts) — modern, premium, rounded
/// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._(); // Prevent instantiation

  // ── Warna Utama (Pastel Pink) ───────────────────────────────
  static const Color primaryColor = Color.fromARGB(
    255,
    248,
    175,
    194,
  ); // Soft pastel pink
  static const Color primaryLight = Color.fromARGB(
    255,
    253,
    215,
    224,
  ); // Very light blush
  static const Color primaryDark = Color.fromARGB(
    255,
    224,
    137,
    160,
  ); // Dusty pastel pink
  static const Color secondaryColor = Color.fromARGB(
    255,
    250,
    196,
    206,
  ); // Muted rose
  static const Color accentColor = Color.fromARGB(
    255,
    255,
    186,
    208,
  ); // Cotton candy pink

  // ── Warna Surface & Background ──────────────────────────────
  static const Color backgroundColor = Color(0xFFF8FAFC); // Off-white
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Very light gray

  // ── Warna Teks ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B); // Near-black slate
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textHint = Color(0xFF94A3B8); // Slate-400

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
    colors: [primaryLight, primaryColor],
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
      Color(0xFFFFF0F5), // Lavender blush
      Color(0xFFFCE4EC), // Pink-50
      Color(0xFFFFF5F7), // Very light pink
      Color(0xFFF8FAFC), // Off-white
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient darkGradientBackground = LinearGradient(
    colors: [
      Color(0xFF0F172A), // Dark slate
      Color(0xFF2D1B2E), // Dark purple-pink
      Color(0xFF0F172A), // Dark slate
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ── Shadow Reusable ─────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1E293B).withValues(alpha: 0.06),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
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

    // Poppins Text Theme
    final poppinsText = GoogleFonts.poppinsTextTheme(base.textTheme);

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
            primaryContainer: primaryColor.withValues(alpha: 0.12),
            secondaryContainer: secondaryColor.withValues(alpha: 0.12),
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

      // ── Tipografi Poppins ──────────────────────────────────
      textTheme: poppinsText.copyWith(
        // Heading besar (dashboard title)
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        // Section heading
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        // Card title
        titleLarge: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.1,
        ),
        // Body teks
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textHint,
        ),
        // Label untuk tombol / chip
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.poppins(
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
          textStyle: GoogleFonts.poppins(
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
          textStyle: GoogleFonts.poppins(
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
        titleTextStyle: GoogleFonts.poppins(
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
        color: Color(0xFFE2E8F0), // Slate-200
        space: 1,
        thickness: 1,
      ),
    );
  }

  // ── Warna Dark Mode ──────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A); // Dark slate
  static const Color darkSurface = Color(0xFF1E293B); // Slate
  static const Color darkCard = Color(0xFF334155); // Light slate
  static const Color darkSurfaceVar = Color(0xFF475569); // Medium slate
  static const Color darkTextPrimary = Color(0xDEFFFFFF); // white 87%
  static const Color darkTextSecondary = Color(0x99FFFFFF); // white 60%
  static const Color darkTextHint = Color(0x61FFFFFF); // white 38%

  /// ── ThemeData Dark ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final poppinsText = GoogleFonts.poppinsTextTheme(base.textTheme);

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
            primaryContainer: primaryColor.withValues(alpha: 0.2),
            secondaryContainer: secondaryColor.withValues(alpha: 0.2),
          ),
      scaffoldBackgroundColor: Colors.transparent, // Use gradient decorator

      textTheme: poppinsText.copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: darkTextHint,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.poppins(
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
          textStyle: GoogleFonts.poppins(
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
          textStyle: GoogleFonts.poppins(
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
        titleTextStyle: GoogleFonts.poppins(
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
        color: Color(0xFF383838),
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
