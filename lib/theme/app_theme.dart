import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────
/// AppTheme — Sistem Desain Premium Fem-PhysicsMonitor
///
/// Panduan Warna Psikologi:
///   • Background  : Off-white #F8FAFC  → bersih, tidak melelahkan mata
///   • Primary     : Sage Green #6BAE8A → menenangkan, alami, menyehatkan
///   • Secondary   : Soft Lavender #A78BFA → lembut, kreatif
///   • Emotion     : Palet pastel/muted agar tidak memicu kecemasan
///
/// Tipografi: Poppins (Google Fonts) — modern, premium, rounded
/// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._(); // Prevent instantiation

  // ── Warna Utama ─────────────────────────────────────────────
  static const Color primaryColor    = Color(0xFF6BAE8A); // Sage Green
  static const Color primaryLight    = Color(0xFF8EC4A8); // Lighter sage
  static const Color primaryDark     = Color(0xFF4D9270); // Darker sage
  static const Color secondaryColor  = Color(0xFFA78BFA); // Soft Lavender
  static const Color accentColor     = Color(0xFF7DD3C0); // Aquamarine

  // ── Warna Surface & Background ──────────────────────────────
  static const Color backgroundColor = Color(0xFFF8FAFC); // Off-white
  static const Color surfaceColor    = Color(0xFFFFFFFF); // Pure white
  static const Color cardColor       = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF1F5F9); // Very light gray

  // ── Warna Teks ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B); // Near-black slate
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textHint      = Color(0xFF94A3B8); // Slate-400

  // ── Warna Emosi (Pastel/Muted — ramah psikologis) ───────────
  static const Map<String, Color> emotionColors = {
    'Happy'  : Color(0xFFF59E0B), // Amber-warm (bukan kuning neon)
    'Sad'    : Color(0xFF60A5FA), // Sky Blue (lembut, bukan biru tua)
    'Angry'  : Color(0xFFF87171), // Coral-red (bukan merah terang)
    'Disgust': Color(0xFF34D399), // Emerald-muted
    'Neutral': Color(0xFF94A3B8), // Slate-muted-gray
    'Fear'   : Color(0xFFA78BFA), // Soft Lavender (bukan ungu gelap)
  };

  // ── Warna Emosi Background (versi lebih terang untuk card) ──
  static const Map<String, Color> emotionBgColors = {
    'Happy'  : Color(0xFFFEF3C7), // Amber-50
    'Sad'    : Color(0xFFEFF6FF), // Blue-50
    'Angry'  : Color(0xFFFEF2F2), // Red-50
    'Disgust': Color(0xFFECFDF5), // Emerald-50
    'Neutral': Color(0xFFF8FAFC), // Slate-50
    'Fear'   : Color(0xFFF5F3FF), // Violet-50
  };

  // ── Gradien Utama ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6BAE8A), Color(0xFF7DD3C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFF6BAE8A), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient recordingGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
  static const double radiusSm  = 12.0;
  static const double radiusMd  = 16.0;
  static const double radiusLg  = 20.0;
  static const double radiusXl  = 24.0;
  static const double radiusFull = 100.0;

  // ── Spacing Tokens ───────────────────────────────────────────
  static const double spaceSm  = 8.0;
  static const double spaceMd  = 16.0;
  static const double spaceLg  = 20.0;
  static const double spaceXl  = 24.0;
  static const double space2xl = 32.0;

  /// ── ThemeData Lengkap ────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);

    // Poppins Text Theme
    final poppinsText = GoogleFonts.poppinsTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        brightness: Brightness.light,
      ).copyWith(
        primaryContainer: primaryColor.withValues(alpha: 0.12),
        secondaryContainer: secondaryColor.withValues(alpha: 0.12),
      ),
      scaffoldBackgroundColor: backgroundColor,

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
          backgroundColor: primaryColor,
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

      // ── Bottom Navigation Bar ──────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
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
  static const Color darkBackground   = Color(0xFF121212);
  static const Color darkSurface      = Color(0xFF1E1E1E);
  static const Color darkCard         = Color(0xFF252525);
  static const Color darkSurfaceVar   = Color(0xFF2C2C2C);
  static const Color darkTextPrimary  = Color(0xDEFFFFFF); // white 87%
  static const Color darkTextSecondary = Color(0x99FFFFFF); // white 60%
  static const Color darkTextHint     = Color(0x61FFFFFF); // white 38%

  /// ── ThemeData Dark ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final poppinsText = GoogleFonts.poppinsTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        brightness: Brightness.dark,
      ).copyWith(
        primaryContainer: primaryColor.withValues(alpha: 0.2),
        secondaryContainer: secondaryColor.withValues(alpha: 0.2),
      ),
      scaffoldBackgroundColor: darkBackground,

      textTheme: poppinsText.copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: darkTextPrimary, letterSpacing: -0.5, height: 1.2,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: darkTextPrimary, letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: darkTextPrimary, letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: darkTextSecondary, letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: darkTextPrimary, height: 1.6,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: darkTextSecondary, height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w400,
          color: darkTextHint,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: darkTextPrimary, letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: darkTextSecondary, letterSpacing: 0.3,
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
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3,
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
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF616161),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: darkTextPrimary, letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd, vertical: spaceMd,
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
      Theme.of(context).brightness == Brightness.dark
          ? darkCard
          : cardColor;

  static Color textP(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : textPrimary;

  static Color textS(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : textSecondary;

  static Color textH(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextHint
          : textHint;

  static Color surfVar(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceVar
          : surfaceVariant;
}
