import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../models/user_model.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/suggestion_service.dart';
import '../theme/resonance_colors.dart';
import '../utils/animations.dart';
import '../widgets/decorative_painters.dart';
import '../widgets/suggestion_card.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Dashboard Utama Fem-Psych Monitor
//
// Desain: Executive Dashboard + Bento Grid (ui-ux-pro-max skill)
//   • _buildHeader()        → Greeting + avatar inisial
//   • _buildPsychCard()     → Kartu status psikis (layered card)
//   • _buildStatsBento()    → 2x2 grid statistik mini
//   • _buildCTAButton()     → Tombol rekam besar (taktil)
//   • _buildOverallSuggestion() → Rekomendasi psikis keseluruhan
//   • _buildRecentHistory() → Cuplikan 3 log terbaru
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

String get _greetingAsset {
    final h = DateTime.now().hour;
    if (h < 11) return 'assets/icon/icon_greeting/pagi.png';
    if (h < 15) return 'assets/icon/icon_greeting/siang.png';
    if (h < 18) return 'assets/icon/icon_greeting/sore.png';
    return 'assets/icon/icon_greeting/malam.png';
  }

  // ── Time-based greeting accent color ─────────────────────────
  Color get _greetingColor {
    final h = DateTime.now().hour;
    if (h < 11) return const Color(0xFFE8A33D);
    if (h < 15) return const Color(0xFF4E97D9);
    if (h < 18) return const Color(0xFFF0793C);
    return const Color(0xFF7C6FE8);
  }

  // ── Formatted date ───────────────────────────────────────────
  String get _todayLabel {
    final now = DateTime.now();
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
    final c = ResonanceColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

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

                  const SizedBox(height: 24),

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

                  const SizedBox(height: 16),

                  // ── Bento Stats ─────────────────────────────────
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
                      child: _buildStatsBento(context, historyList),
                    ),
                  ),

                  const SizedBox(height: 24),

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

                  const SizedBox(height: 24),

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
                    const SizedBox(height: 24),
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Header — Greeting + Avatar
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final c = ResonanceColors.of(context);
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
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: c.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
// Greeting + nama
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
                    decoration: BoxDecoration(
                      color: _greetingColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _greetingColor.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          _greetingAsset,
                          width: 15,
                          height: 15,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _greeting,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _greetingColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.tr('how_are_you'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: c.onSurfaceVariant,
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
            borderRadius: BorderRadius.circular(16),
          ),
          color: c.surfaceLowest,
          onSelected: (val) async {
            if (val == 'settings') {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadProfilePhoto();
            } else if (val == 'logout') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: c.surfaceLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Text(
                    AppLocalizations.tr('logout_confirm'),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      color: c.onSurface,
                    ),
                  ),
                  content: Text(
                    AppLocalizations.tr('logout_confirm_desc'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        AppLocalizations.tr('cancel'),
                        style: GoogleFonts.inter(color: c.onSurfaceVariant),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        AppLocalizations.tr('logout'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF87171),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                if (!context.mounted) return;
                DatabaseService.resetInstance();
                // Play Billing terikat akun Google di device — premium
                // tetap berlaku; dicek ulang saat login berikutnya.
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AppRouter()),
                    (route) => false,
                  );
                }
              }
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
              value: 'settings',
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.gearSix,
                    color: c.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.tr('settings_menu'),
                    style: GoogleFonts.inter(
                      color: c.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (auth.isLoggedIn) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF87171).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.signOut,
                        color: Color(0xFFF87171),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.tr('logout'),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF87171),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!auth.isLoggedIn) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'login',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.signIn,
                        color: c.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.tr('login_signup'),
                      style: GoogleFonts.inter(
                        color: c.primary,
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
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1424161C),
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceLowest,
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
                        style: GoogleFonts.spaceGrotesk(
                          color: c.primary,
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
  // Widget: Kartu Status Psikis — layered card dengan accent status
  // ─────────────────────────────────────────────────────────────
  Widget _buildPsychCard(BuildContext context, EmotionRecord? latest, List<EmotionRecord> history) {
    // Ambil data user dari database
    return FutureBuilder<AppUser?>(
      future: DatabaseService.getUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final basePsychScore = user?.psychologicalScore; // 0-100 (tinggi = baik)

        // Skor langsung 0-100 dari Firebase (tinggi = sehat)
        // Skor sudah termasuk adjustment dari rekaman emosi sebelumnya
        int? displayScore100;
        if (basePsychScore != null) {
          displayScore100 = basePsychScore;
          // Override skor untuk testing safety layer
          if (FirebaseAuth.instance.currentUser?.uid ==
              '3v01CZB4LQMblWB2Z2AHv5Sv8q63') {
            displayScore100 = 20;
          }
        }

        // Tentukan warna dan info berdasarkan skor (0-100, tinggi = baik)
        Color statusColor;
        String statusLabel;
        IconData statusIcon;
        String description;

        if (displayScore100 == null) {
          statusColor = const Color(0xFF8C7075);
          statusLabel = AppLocalizations.tr('not_assessed');
          statusIcon = PhosphorIconsRegular.question;
          description = AppLocalizations.tr('fill_questionnaire_to_see_score');
        } else if (displayScore100 >= 76) {
          statusColor = const Color(0xFF10B981); // Green - Optimal
          statusLabel = AppLocalizations.tr('psych_excellent');
          statusIcon = PhosphorIconsRegular.checkCircle;
          description = _getHealthClassDescription(displayScore100);
        } else if (displayScore100 >= 51) {
          statusColor = const Color(0xFFF59E0B); // Amber - Cukup
          statusLabel = AppLocalizations.tr('psych_good');
          statusIcon = PhosphorIconsRegular.checkCircle;
          description = _getHealthClassDescription(displayScore100);
        } else if (displayScore100 >= 26) {
          statusColor = const Color(0xFFF97316); // Orange - Rentan
          statusLabel = AppLocalizations.tr('psych_fair');
          statusIcon = PhosphorIconsRegular.warning;
          description = _getHealthClassDescription(displayScore100);
        } else {
          statusColor = const Color(0xFFEF4444); // Red - Perlu perhatian
          statusLabel = AppLocalizations.tr('psych_needs_attention');
          statusIcon = PhosphorIconsRegular.warningCircle;
          description = _getHealthClassDescription(displayScore100);
        }

        final cardEnd = Color.lerp(statusColor, Colors.black, 0.32)!;
        final white70 = Colors.white.withValues(alpha: 0.7);
        final white90 = Colors.white.withValues(alpha: 0.9);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statusColor, cardEnd],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.35),
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PsychCardDecorPainter(color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
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
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.heart,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.tr('mental_health'),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

const SizedBox(height: 16),

              // Hero skor zen — baris skor + garis progress tipis
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayScore100 != null ? '$displayScore100' : '---',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '/ 100',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: white70,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Garis progress tipis
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: displayScore100 != null
                      ? displayScore100 / 100
                      : 0,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

              const SizedBox(height: 14),

              // Deskripsi/saran
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.lightbulb,
                      color: white90,
                      size: 15,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: white90,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Indikator dampak emosi
              if (history.isNotEmpty && displayScore100 != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          history.first.emotionScore >= 0
                              ? PhosphorIconsRegular.trendUp
                              : PhosphorIconsRegular.trendDown,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.tr('emotion_impact_on_score'),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              history.first.emotionScore >= 0
                                  ? AppLocalizations.tr('positive_emotions_increase')
                                  : AppLocalizations.tr('negative_emotions_decrease'),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          history.first.emotionScore >= 0
                              ? '+${history.first.emotionScore.toStringAsFixed(1)}'
                              : history.first.emotionScore.toStringAsFixed(1),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Safety layer (butuh perhatian klinis)
              if (displayScore100 != null && displayScore100 < 26) ...[
                const SizedBox(height: 14),
                _buildPsychSafetyReferral(context),
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
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Image.asset(
                            latest.emotion.assetIconPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.tr('last_detection'),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: white70,
                              ),
                            ),
                            Text(
                              '${latest.emotion.displayName} (${(latest.confidence * 100).toStringAsFixed(0)}%)',
                              style: GoogleFonts.spaceGrotesk(
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
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: white70,
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
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Bento Stats — grid 2x2 statistik mini
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatsBento(BuildContext context, List<EmotionRecord> history) {
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
        painter: FlowerPainter(color: ResonanceColors.of(context).primary),
        color: ResonanceColors.of(context).primary,
      ),
      (
        value: '$positiveCount',
        label: AppLocalizations.tr('positive'),
        painter: SunSmilePainter(color: const Color(0xFFF59E0B)),
        color: const Color(0xFFF59E0B),
      ),
      (
        value: '$negativeCount',
        label: AppLocalizations.tr('attention'),
        painter: HeartLeafPainter(color: const Color(0xFFF87171)),
        color: const Color(0xFFF87171),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
Expanded(
              child: _buildStatTile(
                context,
                value: stats[0].value,
                label: stats[0].label,
                painter: stats[0].painter,
                color: stats[0].color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatTile(
                context,
                value: stats[1].value,
                label: stats[1].label,
                painter: stats[1].painter,
                color: stats[1].color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                context,
                value: stats[2].value,
                label: stats[2].label,
                painter: stats[2].painter,
                color: stats[2].color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRemainingTile(context),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildStatTile(
    BuildContext context, {
    required String value,
    required String label,
    required CustomPainter painter,
    required Color color,
  }) {
    final c = ResonanceColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1424161C),
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(38, 38),
            painter: painter,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCounter(
                  value: double.parse(value),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: c.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingTile(BuildContext context) {
    final c = ResonanceColors.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FutureBuilder<int>(
      future: StorageService.getRemainingDetections(uid),
      builder: (context, snapshot) {
        final premium = context.watch<PremiumProvider>();
        final remaining = snapshot.data ?? 5;
        final isLow = remaining <= 2;
        final color = premium.isPremium
            ? const Color(0xFF10B981)
            : isLow
                ? const Color(0xFFF87171)
                : const Color(0xFFF59E0B);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surfaceLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.outlineVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1424161C),
                offset: Offset(2, 2),
              ),
            ],
          ),
child: Row(
            children: [
              CustomPaint(
                size: const Size(38, 38),
                painter: LeafTimerPainter(color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      premium.isPremium
                          ? '∞'
                          : '$remaining/5',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.tr('remaining_detections'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: c.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Tombol CTA Rekam — taktil, pill besar
  // ─────────────────────────────────────────────────────────────
  Widget _buildCTAButton(BuildContext context) {
    final c = ResonanceColors.of(context);
    return GestureDetector(
      onTap: widget.onStartRecording,
      child: ResonanceCard(
        c: c,
        padding: const EdgeInsets.all(24),
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
                    Transform.scale(
                      scale: _pulseAnim.value * 1.35,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primaryContainer,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _pulseAnim.value * 1.18,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primaryContainer.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.primary,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4024161C),
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        PhosphorIconsRegular.microphone,
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
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.tr('start_recording_desc'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: c.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // Feature tags
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureTag(
                  context,
                  PhosphorIconsRegular.waveform,
                  'Real-time',
                  c.primary,
                ),
                const SizedBox(width: 8),
                _buildFeatureTag(
                  context,
                  PhosphorIconsRegular.lock,
                  'Private',
                  c.primary,
                ),
                const SizedBox(width: 8),
                _buildFeatureTag(
                  context,
                  PhosphorIconsRegular.brain,
                  '6 Emosi',
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTag(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Rekomendasi Psikis Keseluruhan (Big Five OCEAN v2)
  // ─────────────────────────────────────────────────────────────
  Widget _buildOverallSuggestion(
    BuildContext context,
    List<EmotionRecord> history,
  ) {
    final dominant = history.isNotEmpty
        ? history.first.emotion
        : EmotionType.neutral;

    return FutureBuilder<AppUser?>(
      future: DatabaseService.getUser(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final bigFiveScores = user?.bigFiveScores ?? {};

          return FutureBuilder<void>(
            future: SuggestionService().load(),
            builder: (context, _) {
              final svc = SuggestionService();
              final result = svc.getStructuredSuggestions(bigFiveScores, dominant);
              final title = svc.buildTitle(bigFiveScores, dominant);

              if (result.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    icon: PhosphorIconsRegular.sparkle,
                    title: AppLocalizations.tr('psych_recommendation'),
                  ),
                  const SizedBox(height: 14),
                  SuggestionCard(
                    title: title,
                    traitSuggestions: result.traitSuggestions,
                    icon: PhosphorIconsRegular.lightbulb,
                    color: dominant.color,
                    isCollapsible: true,
                  ),
                ],
              );
            },
          );
      },
    );
  }

  // ── Safety Referral (inside psych card) ──
  Widget _buildPsychSafetyReferral(BuildContext context) {
    return FutureBuilder<SuggestionResult?>(
      future: SuggestionService().getSafetyData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        return _buildSafetyReferral(context, snapshot.data!);
      },
    );
  }

  // ── Safety Referral Card ──
  Widget _buildSafetyReferral(BuildContext context, SuggestionResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  PhosphorIconsRegular.warningCircle,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.locale.startsWith('en')
                      ? 'Need Help?'
                      : 'Butuh Bantuan?',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (result.safetyMessage != null)
            Text(
              result.safetyMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.5,
              ),
            ),
          if (result.safetyActions != null) ...[
            const SizedBox(height: 12),
            ...result.safetyActions!.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(PhosphorIconsRegular.arrowRight,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          action,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:199')),
              icon: const Icon(PhosphorIconsRegular.phone, size: 18),
              label: Text(
                AppLocalizations.locale.startsWith('en')
                    ? 'Call 199 (Sejiwa)'
                    : 'Hubungi 199 (Sejiwa)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Riwayat Terbaru — 3 entry terakhir
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecentHistory(
    BuildContext context,
    List<EmotionRecord> history,
  ) {
    final c = ResonanceColors.of(context);
    final recent = history.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              context,
              icon: PhosphorIconsRegular.clock,
              title: AppLocalizations.tr('recent_detections'),
            ),
            GestureDetector(
              onTap: () {
                // Navigate ke tab Riwayat (index 2)
                widget.onNavigateToHistory?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceLowest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.tr('see_all'),
                      style: GoogleFonts.inter(
                        color: c.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      PhosphorIconsRegular.arrowUpRight,
                      color: c.onSurface,
                      size: 13,
                    ),
                  ],
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

  // Item list riwayat dengan dekorasi lembut
  Widget _buildHistoryItem(BuildContext context, EmotionRecord record) {
    final c = ResonanceColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: record.emotion.color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: c.outlineVariant.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: record.emotion.color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Decorative left border with gradient
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      record.emotion.color.withValues(alpha: 0.4),
                      record.emotion.color,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Decorative background dots
                    Positioned(
                      right: 12,
                      top: 8,
                      child: CustomPaint(
                        size: const Size(60, 50),
                        painter: DotsDecorationPainter(color: record.emotion.color),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // Decorative emotion graphic
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: record.emotion.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Image.asset(
                              record.emotion.assetIconPath,
                              width: 32,
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.emotion.displayName,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: c.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  record.formattedTime,
                                  style: GoogleFonts.inter(
                                    color: c.onSurfaceVariant,
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
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: record.emotion.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              record.confidencePercent,
                              style: GoogleFonts.jetBrainsMono(
                                color: record.emotion.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    final c = ResonanceColors.of(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: c.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        if (trailingLabel != null && trailingColor != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: trailingColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailingLabel,
              style: GoogleFonts.inter(
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

// Helper untuk get description kelas kesehatan mental
  String _getHealthClassDescription(int score) {
    if (score >= 91) return AppLocalizations.tr('overall_exc_4');
    if (score >= 81) return AppLocalizations.tr('overall_exc_3');
    if (score >= 76) return AppLocalizations.tr('overall_exc_2');
    if (score >= 66) return AppLocalizations.tr('overall_good_4');
    if (score >= 61) return AppLocalizations.tr('overall_good_3');
    if (score >= 56) return AppLocalizations.tr('overall_good_2');
    if (score >= 51) return AppLocalizations.tr('overall_good_1');
    if (score >= 41) return AppLocalizations.tr('overall_fair_5');
    if (score >= 36) return AppLocalizations.tr('overall_fair_4');
    if (score >= 31) return AppLocalizations.tr('overall_fair_3');
    if (score >= 26) return AppLocalizations.tr('overall_fair_2');
    if (score >= 16) return AppLocalizations.tr('overall_attn_5');
    if (score >= 11) return AppLocalizations.tr('overall_attn_4');
    if (score >= 6)  return AppLocalizations.tr('overall_attn_3');
    return AppLocalizations.tr('overall_attn_2');
  }
}
// -------------------------------------------------------------
// _PsychCardDecorPainter — Dekorasi halus di dalam kartu kesehatan mental
// -------------------------------------------------------------
class _PsychCardDecorPainter extends CustomPainter {
  final Color color;

  const _PsychCardDecorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Lingkaran lembut di pojok
    canvas.drawCircle(
      Offset(size.width * 0.98, -24),
      110,
      Paint()..color = color.withValues(alpha: 0.05),
    );
    canvas.drawCircle(
      Offset(-14, size.height * 0.72),
      70,
      Paint()..color = color.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.92),
      34,
      Paint()..color = color.withValues(alpha: 0.07),
    );

    // Titik-titik kecil
    final dot = Paint()..color = color.withValues(alpha: 0.1);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.1), 3, dot);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.05), 2.2, dot);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.94), 2.5, dot);

    // Gelombang sinus halus
    _drawWave(
      canvas,
      size,
      baseY: size.height * 0.3,
      amp: 7,
      freq: 5,
      phase: 0,
      stroke: 1.6,
      alpha: 0.1,
    );
    _drawWave(
      canvas,
      size,
      baseY: size.height * 0.36,
      amp: 12,
      freq: 3.2,
      phase: math.pi,
      stroke: 1.4,
      alpha: 0.07,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double amp,
    required double freq,
    required double phase,
    required double stroke,
    required double alpha,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY +
          math.sin((x / size.width) * 2 * math.pi * freq + phase) * amp;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

@override
  bool shouldRepaint(covariant _PsychCardDecorPainter oldDelegate) => false;
}
