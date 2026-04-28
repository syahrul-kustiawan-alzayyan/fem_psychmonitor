import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import '../widgets/gradient_background.dart';
import '../widgets/suggestion_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Dashboard Utama Fem-Psych Monitor
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
  final VoidCallback? onNavigateToHistory;
  const HomeScreen({super.key, required this.onStartRecording, this.onNavigateToHistory});

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

    _loadProfilePhoto();
  }

  String? _photoPath;

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('auth_email') ?? '';
    final savedPhoto = prefs.getString('profile_photo_$email');
    if (mounted) {
      setState(() {
        _photoPath = savedPhoto;
      });
    }
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
    final monthKeys = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final wd = AppLocalizations.tr(dayKeys[now.weekday - 1]);
    final month = AppLocalizations.tr(monthKeys[now.month - 1]);
    return '$wd, ${now.day} $month ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Buat Future baru setiap build untuk memastikan data selalu fresh
    final recordingsFuture = DatabaseService.getRecordings();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false, // bottom nav melayang di atasnya
          child: FutureBuilder<List<RecordingData>>(
            future: recordingsFuture,
            builder: (context, snapshot) {
              final recordings = snapshot.data ?? [];
              final historyList = recordings
                  .map((r) => r.toEmotionRecord())
                  .toList();

              // Only show emotion data if there are actual recordings
              final latest = historyList.isNotEmpty ? historyList.first : null;

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
                        child: _buildPsychCard(context, latest, historyList),
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
          onSelected: (val) async {
            if (val == 'profile') {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              _loadProfilePhoto();
            } else if (val == 'settings') {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadProfilePhoto();
            } else if (val == 'login') {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
              _loadProfilePhoto();
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
                image: _photoPath != null && File(_photoPath!).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(_photoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _photoPath == null || !File(_photoPath!).existsSync()
                  ? Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Kartu Status Psikis dengan Gradien
  // Menampilkan hasil asesmen kesehatan mental dari onboarding
  // ─────────────────────────────────────────────────────────────
  Widget _buildPsychCard(BuildContext context, EmotionRecord? latest, List<EmotionRecord> history) {
    // Ambil data user dari database
    return FutureBuilder<AppUser?>(
      future: DatabaseService.getUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final basePsychScore = user?.psychologicalScore; // 0-60 (tinggi = buruk)

        // Hitung skor emosi dari deteksi terbaru (max 10 sesi terakhir)
        double emotionAdjustment = 0;
        if (history.isNotEmpty) {
          final recentSessions = history.take(10).toList();
          final avgEmotionScore = recentSessions.fold<double>(
            0, (sum, r) => sum + r.emotionScore,
          ) / recentSessions.length;
          // Normalisasi: avgEmotionScore range -5..+5
          emotionAdjustment = avgEmotionScore;
        }

        // Konversi ke skala 0-100 (tinggi = sehat)
        // Skor kuesioner: 0-60 → invert ke 0-100
        // Base: (60 - psychScore) / 60 * 100
        // Adjustment: emotionAdjustment range -5..+5 → mapped to ±17 poin
        int? displayScore100;
        if (basePsychScore != null) {
          final baseScore100 = ((60 - basePsychScore) / 60 * 100).round();
          final adjustment100 = (emotionAdjustment / 5 * 17).round();
          displayScore100 = (baseScore100 + adjustment100).clamp(0, 100);
        }

        // Tentukan warna dan info berdasarkan skor (0-100, tinggi = baik)
        Color primaryColor;
        Color secondaryColor;
        String statusLabel;
        IconData statusIcon;
        String emoji;
        String description;

        if (displayScore100 == null) {
          primaryColor = const Color(0xFF64748B);
          secondaryColor = const Color(0xFF94A3B8);
          statusLabel = AppLocalizations.tr('not_assessed');
          statusIcon = Icons.help_outline_rounded;
          emoji = '📋';
          description = AppLocalizations.tr('fill_questionnaire_to_see_score');
        } else if (displayScore100 >= 75) {
          primaryColor = const Color(0xFF10B981); // Green - Baik
          secondaryColor = const Color(0xFF34D399);
          statusLabel = AppLocalizations.tr('psych_excellent');
          statusIcon = Icons.check_circle_rounded;
          emoji = '😊';
          description = _getHealthClassDescription(displayScore100);
        } else if (displayScore100 >= 50) {
          primaryColor = const Color(0xFFF59E0B); // Amber - Cukup
          secondaryColor = const Color(0xFFFBBF24);
          statusLabel = AppLocalizations.tr('psych_good');
          statusIcon = Icons.check_circle_outline_rounded;
          emoji = '🙂';
          description = _getHealthClassDescription(displayScore100);
        } else if (displayScore100 >= 25) {
          primaryColor = const Color(0xFFF97316); // Orange - Rentan
          secondaryColor = const Color(0xFFFB923C);
          statusLabel = AppLocalizations.tr('psych_fair');
          statusIcon = Icons.warning_amber_rounded;
          emoji = '😔';
          description = _getHealthClassDescription(displayScore100);
        } else {
          primaryColor = const Color(0xFFEF4444); // Red - Perlu perhatian
          secondaryColor = const Color(0xFFF87171);
          statusLabel = AppLocalizations.tr('psych_needs_attention');
          statusIcon = Icons.error_rounded;
          emoji = '😰';
          description = _getHealthClassDescription(displayScore100);
        }

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Dekorasi background ────────────────────────────
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Opacity(
                  opacity: 0.1,
                  child: Column(
                    children: List.generate(
                      3,
                      (i) => Row(
                        children: List.generate(
                          3,
                          (j) => Container(
                            margin: const EdgeInsets.all(4),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Konten Utama ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.tr('mental_health'),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Skor besar: 0-100 scale
                    Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayScore100 != null
                                  ? '$displayScore100 / 100'
                                  : '--- / 100',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayScore100 != null
                                  ? _getScoreCategory100(displayScore100)
                                  : AppLocalizations.tr('mental_health_score'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress bar visual
                    if (displayScore100 != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: displayScore100 / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Deskripsi/saran
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              description,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indikator dampak emosi terbaru
                    if (history.isNotEmpty && displayScore100 != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.tr('emotion_impact_on_score'),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  emotionAdjustment >= 0
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    emotionAdjustment >= 0
                                        ? AppLocalizations.tr('positive_emotions_increase')
                                        : AppLocalizations.tr('negative_emotions_decrease'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    emotionAdjustment >= 0
                                        ? '+${(emotionAdjustment.abs() / 5 * 17).round()}'
                                        : '-${(emotionAdjustment.abs() / 5 * 17).round()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Deteksi terakhir (jika ada)
                    if (latest != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              latest.emotion.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.tr('last_detection'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${latest.emotion.displayName} • ${(latest.confidence * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              latest.formattedTime,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper untuk kategori skor 0-100 (tinggi = baik)
  String _getScoreCategory100(int score) {
    if (score >= 75) return AppLocalizations.tr('psych_excellent');
    if (score >= 50) return AppLocalizations.tr('psych_good');
    if (score >= 25) return AppLocalizations.tr('psych_fair');
    return AppLocalizations.tr('psych_needs_attention');
  }

  // Helper untuk get description kelas kesehatan mental
  String _getHealthClassDescription(int score) {
    if (score >= 75) return AppLocalizations.tr('overall_exc_1');
    if (score >= 50) return AppLocalizations.tr('overall_good_1');
    if (score >= 25) return AppLocalizations.tr('overall_fair_1');
    return AppLocalizations.tr('overall_attn_1');
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

    // Gunakan FutureBuilder untuk mengambil MBTI dan saran dari SuggestionService
    return FutureBuilder<AppUser?>(
      future: DatabaseService.getUser(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final mbtiType = user?.mbtiType ?? 'XXXX';
        final psychLabel = (mbtiType.isNotEmpty && mbtiType != 'XXXX')
            ? mbtiType
            : AppLocalizations.tr('info');

        return FutureBuilder<void>(
          future: SuggestionService().load(),
          builder: (context, _) {
            final svc = SuggestionService();
            final suggestions = svc.getSuggestions(mbtiType, dominant);
            final title = svc.buildTitle(mbtiType, dominant);

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

                // Card saran collapsible — dari SuggestionService
                SuggestionCard(
                  title: title,
                  suggestions: suggestions,
                  icon: Icons.tips_and_updates_rounded,
                  color: AppTheme.primaryColor,
                  isCollapsible: true,
                ),
              ],
            );
          },
        );
      },
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
            GestureDetector(
              onTap: () {
                // Navigate ke tab Riwayat (index 2)
                widget.onNavigateToHistory?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  AppLocalizations.tr('see_all'),
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
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
