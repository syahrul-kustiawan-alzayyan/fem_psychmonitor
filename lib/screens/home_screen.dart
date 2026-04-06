import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import '../widgets/gradient_background.dart';
import '../widgets/suggestion_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Dashboard Utama Fem-PhysicsMonitor
//
// Arsitektur Widget (dipisah agar mudah di-maintain):
//   • _buildHeader()           → Greeting + avatar inisial
//   • _buildPsychCard()        → Kartu status psikis hari ini (gradient)
//   • _buildQuickStats()       → 3 kartu statistik mini
//   • _buildCTAButton()        → Tombol rekam besar bergaya premium
//   • _buildOverallSuggestion()→ Rekomendasi psikis keseluruhan
//   • _buildRecentHistory()    → Cuplikan 3 log terbaru
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final VoidCallback onStartRecording;
  const HomeScreen({super.key, required this.onStartRecording});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Animation controller for staggered animations
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    // Subtle pulse untuk dekorasi CTA button
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Stagger animation controller
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  // ── Time-based greeting ──────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return AppLocalizations.tr('greeting_morning');
    if (h < 15) return AppLocalizations.tr('greeting_afternoon');
    if (h < 18) return AppLocalizations.tr('greeting_evening');
    return AppLocalizations.tr('greeting_night');
  }

  String get _greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 11) return '☀️';
    if (h < 15) return '🌤️';
    if (h < 18) return '🌅';
    return '🌙';
  }

  // ── Formatted date ───────────────────────────────────────────
  String get _todayLabel {
    final now = DateTime.now();
    final isId = AppLocalizations.currentLocale == 'id';
    final months = isId
        ? [
            'Januari',
            'Februari',
            'Maret',
            'April',
            'Mei',
            'Juni',
            'Juli',
            'Agustus',
            'September',
            'Oktober',
            'November',
            'Desember',
          ]
        : [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
    final days = isId
        ? ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
        : [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];
    final wd = days[now.weekday - 1];
    return '$wd, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false, // bottom nav melayang di atasnya
          child: FutureBuilder<List<RecordingData>>(
            future: DatabaseService.getRecordings(),
            builder: (context, snapshot) {
              final recordings = snapshot.data ?? [];
              final historyList = recordings
                  .map((r) => r.toEmotionRecord())
                  .toList();

              final latest = historyList.isNotEmpty
                  ? historyList.first
                  : DummyData.latestEmotion;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spaceLg),

                    // ── Header ─────────────────────────────────────
                    FadeTransition(
                      opacity: AnimationUtils.fadeInAnimation(
                        _staggerCtrl,
                        0,
                        0.15,
                      ),
                      child: SlideTransition(
                        position: AnimationUtils.slideUpAnimation(
                          _staggerCtrl,
                          0,
                          0.15,
                        ),
                        child: _buildHeader(context),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXl),

                    // ── Kartu Status Psikis ─────────────────────────
                    FadeTransition(
                      opacity: AnimationUtils.fadeInAnimation(
                        _staggerCtrl,
                        1,
                        0.15,
                      ),
                      child: SlideTransition(
                        position: AnimationUtils.slideUpAnimation(
                          _staggerCtrl,
                          1,
                          0.15,
                        ),
                        child: _buildPsychCard(context, latest),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceMd),

                    // ── Quick Stats ─────────────────────────────────
                    FadeTransition(
                      opacity: AnimationUtils.fadeInAnimation(
                        _staggerCtrl,
                        2,
                        0.15,
                      ),
                      child: SlideTransition(
                        position: AnimationUtils.slideUpAnimation(
                          _staggerCtrl,
                          2,
                          0.15,
                        ),
                        child: _buildQuickStats(context, historyList),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXl),

                    // ── Tombol CTA Rekam ────────────────────────────
                    FadeTransition(
                      opacity: AnimationUtils.fadeInAnimation(
                        _staggerCtrl,
                        3,
                        0.15,
                      ),
                      child: SlideTransition(
                        position: AnimationUtils.slideUpAnimation(
                          _staggerCtrl,
                          3,
                          0.15,
                        ),
                        child: _buildCTAButton(context),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXl),

                    // ── Rekomendasi Psikis ──────────────────────────
                    if (historyList.isNotEmpty) ...[
                      FadeTransition(
                        opacity: AnimationUtils.fadeInAnimation(
                          _staggerCtrl,
                          4,
                          0.15,
                        ),
                        child: SlideTransition(
                          position: AnimationUtils.slideUpAnimation(
                            _staggerCtrl,
                            4,
                            0.15,
                          ),
                          child: _buildOverallSuggestion(context, historyList),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXl),
                    ],

                    // ── Riwayat Terbaru ─────────────────────────────
                    if (historyList.isNotEmpty)
                      FadeTransition(
                        opacity: AnimationUtils.fadeInAnimation(
                          _staggerCtrl,
                          5,
                          0.15,
                        ),
                        child: SlideTransition(
                          position: AnimationUtils.slideUpAnimation(
                            _staggerCtrl,
                            5,
                            0.15,
                          ),
                          child: _buildRecentHistory(context, historyList),
                        ),
                      ),

                    // Padding akhir agar tidak tertutup bottom nav
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ),
      ), // End GradientBackground
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Header — Greeting + Avatar
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.username.isNotEmpty ? auth.username : 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal hari ini
              Text(
                _todayLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textH(context),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              // Greeting + nama
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_greeting $_greetingEmoji\n',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    TextSpan(
                      text: displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.tr('how_are_you'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // PopupMenuButton untuk Profil dan Settings
        PopupMenuButton<String>(
          offset: const Offset(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          color: AppTheme.surface(context),
          onSelected: (val) {
            if (val == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            } else if (val == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            } else if (val == 'login') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.textP(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.tr('profile_menu'),
                    style: GoogleFonts.poppins(
                      color: AppTheme.textP(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    color: AppTheme.textP(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.tr('settings_menu'),
                    style: GoogleFonts.poppins(
                      color: AppTheme.textP(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!auth.isLoggedIn) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'login',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.warmGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.login_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.tr('login_signup'),
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface(context),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Kartu Status Psikis dengan Gradien
  // ─────────────────────────────────────────────────────────────
  Widget _buildPsychCard(BuildContext context, EmotionRecord latest) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Dekorasi lingkaran latar ───────────────────────
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // ── Konten Kartu ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: label + status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.tr('psych_status_today'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.2,
                      ),
                    ),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        latest.emotion.psychStatus,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Row: ikon emosi + nama + waktu
                Row(
                  children: [
                    // Icon container frosted
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        latest.emotion.icon,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest.emotion.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            latest.emotion.displayName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${AppLocalizations.tr('last_detection')}: ${latest.formattedTime}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Confidence bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.tr('detection_confidence'),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          latest.confidencePercent,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      child: LinearProgressIndicator(
                        value: latest.confidence,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Quick Stats — 3 kartu statistik mini
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuickStats(BuildContext context, List<EmotionRecord> history) {
    final positiveCount = history
        .where((r) => r.emotion == EmotionType.happy)
        .length;
    final negativeCount = history
        .where(
          (r) =>
              r.emotion == EmotionType.angry ||
              r.emotion == EmotionType.sad ||
              r.emotion == EmotionType.fear,
        )
        .length;

    final stats = [
      (
        value: '${history.length}',
        label: AppLocalizations.tr('recordings'),
        icon: Icons.analytics_rounded,
        color: AppTheme.primaryColor,
      ),
      (
        value: '$positiveCount',
        label: AppLocalizations.tr('positive'),
        icon: Icons.sentiment_satisfied_alt_rounded,
        color: const Color(0xFFF59E0B),
      ),
      (
        value: '$negativeCount',
        label: AppLocalizations.tr('attention'),
        icon: Icons.favorite_border_rounded,
        color: const Color(0xFFF87171),
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
            child: GlassCard(
              useBlur:
                  !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s.icon, color: s.color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  AnimatedCounter(
                    value: double.parse(s.value),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: s.color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textS(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Tombol CTA Rekam — Besar, Elegan, Animated
  // ─────────────────────────────────────────────────────────────
  Widget _buildCTAButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.onStartRecording,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.secondaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lingkaran animasi pulse + tombol mic
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring luar (pulse)
                    Transform.scale(
                      scale: _pulseAnim.value * 1.35,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.08),
                              AppTheme.secondaryColor.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Ring tengah (pulse lambat)
                    Transform.scale(
                      scale: _pulseAnim.value * 1.18,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.12),
                              AppTheme.secondaryColor.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tombol utama dengan gradient border
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppTheme.secondaryColor.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            Text(
              AppLocalizations.tr('start_recording'),
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..shader = AppTheme.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.tr('start_recording_desc'),
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppTheme.textS(context),
              ),
            ),

            const SizedBox(height: 16),

            // Feature tags
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureTag('⚡ Real-time', AppTheme.primaryColor),
                const SizedBox(width: 8),
                _buildFeatureTag('🔒 Private', AppTheme.secondaryColor),
                const SizedBox(width: 8),
                _buildFeatureTag('🧠 6 Emotions', const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Rekomendasi Psikis Keseluruhan
  // ─────────────────────────────────────────────────────────────
  Widget _buildOverallSuggestion(
    BuildContext context,
    List<EmotionRecord> history,
  ) {
    final emotionCount = <EmotionType, int>{};
    for (final r in history) {
      emotionCount[r.emotion] = (emotionCount[r.emotion] ?? 0) + 1;
    }
    final dominant = emotionCount.isNotEmpty
        ? emotionCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key
        : EmotionType.neutral;

    final psychLabel = context.watch<AuthProvider>().isLoggedIn
        ? 'MBTI'
        : 'Info';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _buildSectionHeader(
          context,
          icon: Icons.auto_awesome_rounded,
          title: AppLocalizations.tr('psych_recommendation'),
          trailingLabel: psychLabel,
          trailingColor: AppTheme.primaryColor,
        ),

        const SizedBox(height: 14),

        // Emosi dominan info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dominant.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: dominant.color.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dominant.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(dominant.icon, color: dominant.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${AppLocalizations.tr('dominant_emotion')}: ',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textS(context),
                        ),
                      ),
                      TextSpan(
                        text: '${dominant.emoji} ${dominant.displayName}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Card saran collapsible
        SuggestionCard(
          title: '${AppLocalizations.tr('suggestion_for')} Anda',
          suggestions: const [
            'Lakukan deteksi emosi secara rutin untuk memahami pola perasaan Anda.',
            'Gunakan hasil MBTI Anda untuk mendapatkan saran yang lebih personal.',
            'Cobalah meditasi 5 menit setiap hari untuk keseimbangan emosional.',
          ],
          icon: Icons.tips_and_updates_rounded,
          color: AppTheme.primaryColor,
          isCollapsible: true,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Riwayat Terbaru — 3 entry terakhir
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecentHistory(
    BuildContext context,
    List<EmotionRecord> history,
  ) {
    final recent = history.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.history_rounded,
              title: AppLocalizations.tr('recent_detections'),
            ),
            Text(
              AppLocalizations.tr('see_all'),
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...recent.map((r) => _buildHistoryItem(context, r)),
      ],
    );
  }

  // Item list riwayat dengan left-border accent
  Widget _buildHistoryItem(BuildContext context, EmotionRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent border berwarna emosi
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: record.emotion.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd),
                    bottomLeft: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      // Ikon emosi
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: record.emotion.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Icon(
                          record.emotion.icon,
                          color: record.emotion.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nama + waktu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${record.emotion.emoji} ${record.emotion.displayName}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textP(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              record.formattedTime,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textS(context),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Confidence chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: record.emotion.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          record.confidencePercent,
                          style: GoogleFonts.poppins(
                            color: record.emotion.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: Section Header (icon + title + optional trailing chip)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingLabel,
    Color? trailingColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (trailingLabel != null && trailingColor != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: trailingColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              trailingLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: trailingColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
