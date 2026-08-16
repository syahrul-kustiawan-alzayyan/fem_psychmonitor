import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emotion_model.dart';
import '../../services/database_service.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/resonance_colors.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/admin_charts.dart' show resonanceAccent;

class UserDetailScreen extends StatefulWidget {
  final String userUid;

  const UserDetailScreen({super.key, required this.userUid});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  List<RecordingData> _recordings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await DatabaseService.getUserDataByUid(widget.userUid);
      final recordings = await DatabaseService.getUserRecordings(widget.userUid);

      if (userData == null) {
        if (mounted) {
          setState(() {
            _error = 'Data pengguna tidak ditemukan';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _userData = userData;
          _recordings = recordings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _psychScoreColor(int? score) {
    if (score == null) return const Color(0xFF64748B);
    if (score >= 76) return const Color(0xFF10B981);
    if (score >= 51) return const Color(0xFFF59E0B);
    if (score >= 26) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _psychScoreCategory(int? score) {
    if (score == null) return 'Belum Dinilai';
    if (score >= 76) return 'Sehat Optimal';
    if (score >= 51) return 'Cukup';
    if (score >= 26) return 'Rentan';
    return 'Butuh Perhatian';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds d';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '$m m $s d' : '$m m';
  }

  String _formatDate(dynamic dateValue) {
    DateTime? date;
    if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is String) {
      date = DateTime.tryParse(dateValue);
    }
    if (date == null) return '--';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleExportPDF() async {
    if (_userData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data belum dimuat')),
        );
      }
      return;
    }
    try {
      final pdf = await PdfExportService.generateUserReport(_userData!, _recordings);
      final name = _userData!['name'] as String? ?? 'pengguna';
      await Printing.sharePdf(bytes: pdf, filename: 'laporan_$name.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              PhosphorIconsRegular.arrowLeft,
              size: 22,
              color: c.onSurface,
            ),
          ),
          title: Text(
            'Detail Pengguna',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.onSurface,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _handleExportPDF,
              icon: Icon(
                PhosphorIconsRegular.filePdf,
                size: 22,
                color: c.onSurface,
              ),
              tooltip: 'Export PDF',
            ),
          ],
        ),
      ),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: resonanceAccent(c),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: kToolbarHeight),

                            // ── Profile Header ────────────────────────
                            _buildProfileHeader(),

                            const SizedBox(height: 20),

                            // ── Mental Health Score ──────────────────
                            _buildMentalHealthCard(),

                            const SizedBox(height: 22),

                            // ── Big Five Section ────────────────────
                            _buildSectionHeader(
                              'PERSONALITY',
                              'Profil Big Five',
                            ),
                            const SizedBox(height: 10),
                            _buildBigFiveSection(),

                            const SizedBox(height: 22),

                            // ── Recordings Section ──────────────────
                            _buildSectionHeader(
                              'HISTORY',
                              'Riwayat Rekaman',
                              trailing: '${_recordings.length}',
                            ),
                            const SizedBox(height: 12),
                            _buildRecordingsSection(),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String eyebrow, String title, {String? trailing}) {
    final c = ResonanceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: resonanceAccent(c),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (trailing != null)
              ResonanceChip(c: c, label: trailing),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final c = ResonanceColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surfaceLowest,
              shape: BoxShape.circle,
              border: Border.all(color: c.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1424161C),
                  offset: Offset(2, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: resonanceAccent(c),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Memuat data…',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final c = ResonanceColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF87171).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.warning,
                size: 28,
                color: Color(0xFFF87171),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadData,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: resonanceAccent(c),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2424161C),
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsRegular.arrowsClockwise,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Muat Ulang',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final c = ResonanceColors.of(context);
    final accent = resonanceAccent(c);
    final name = _userData?['name'] as String? ?? 'User';
    final email = _userData?['email'] as String? ?? '';
    final uid = widget.userUid;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final psychScore = _userData?['psych_score'] as int?;
    final scoreColor = _psychScoreColor(psychScore);

    String dateStr = '--';
    final createdAtRaw = _userData?['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }
    if (createdAt != null) {
      final d = createdAt;
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    return ResonanceCard(
      c: c,
      accent: accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  scoreColor.withValues(alpha: 0.85),
                  scoreColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          if (email.isNotEmpty)
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 12),

          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildInfoChip(
                PhosphorIconsRegular.fingerprint,
                'UID: ${uid.substring(0, uid.length.clamp(0, 12))}...',
              ),
              _buildInfoChip(
                PhosphorIconsRegular.calendarBlank,
                'Bergabung: $dateStr',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final c = ResonanceColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthCard() {
    final psychScore = _userData?['psych_score'] as int?;
    final color = _psychScoreColor(psychScore);
    final category = _psychScoreCategory(psychScore);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  PhosphorIconsRegular.heartbeat,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'SKOR KESEHATAN MENTAL',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text(
                psychScore != null ? '$psychScore / 100' : '-- / 100',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          if (psychScore != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: psychScore / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBigFiveSection() {
    final c = ResonanceColors.of(context);
    final bigFiveScores = _userData?['bigfive_scores'] as Map<String, dynamic>? ?? {};

    if (bigFiveScores.isEmpty) {
      return ResonanceCard(
        c: c,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.userFocus,
                    size: 16,
                    color: resonanceAccent(c),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Profil Big Five',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Belum mengisi asesmen Big Five',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dimensions = {
      'O': 'Openness',
      'C': 'Conscientiousness',
      'E': 'Extraversion',
      'A': 'Agreeableness',
      'N': 'Neuroticism',
    };

    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIconsRegular.userFocus,
                  size: 16,
                  color: resonanceAccent(c),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Profil Big Five',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...dimensions.entries.map((entry) {
            final score = (bigFiveScores[entry.key] as num?)?.toDouble() ?? 0.0;
            final fraction = (score / 5.0).clamp(0.0, 1.0);
            final level = score >= 3.5 ? 'Tinggi' : (score <= 2.5 ? 'Rendah' : 'Sedang');
            final levelColor = score >= 3.5
                ? const Color(0xFF10B981)
                : (score <= 2.5 ? const Color(0xFFF59E0B) : c.onSurfaceVariant);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${entry.key} · ${entry.value}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: c.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              level,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: levelColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            score.toStringAsFixed(1),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ResonanceProgressBar(
                    c: c,
                    progress: fraction,
                    color: levelColor == c.onSurfaceVariant
                        ? resonanceAccent(c)
                        : levelColor,
                    height: 6,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecordingsSection() {
    final c = ResonanceColors.of(context);

    if (_recordings.isEmpty) {
      return ResonanceCard(
        c: c,
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.waveSquare,
                  size: 24,
                  color: resonanceAccent(c),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada rekaman',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recordings.map((rec) => _buildRecordingItem(rec)).toList(),
    );
  }

  Widget _buildRecordingItem(RecordingData rec) {
    final c = ResonanceColors.of(context);
    final emotion = rec.dominantEmotion;
    final confidence = rec.confidence;
    final date = rec.date;
    final duration = rec.durationSeconds;

    return GestureDetector(
      onTap: () => _showRecordingDetail(rec),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ResonanceCard(
          c: c,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Emotion indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emotion.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    emotion.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          emotion.displayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.onSurface,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: emotion.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${(confidence * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: emotion.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    PhosphorIconsRegular.timer,
                    size: 14,
                    color: c.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(duration),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordingDetail(RecordingData rec) {
    final c = ResonanceColors.of(context);
    final emotion = rec.dominantEmotion;
    final confidence = rec.confidence;
    final date = rec.date;
    final duration = rec.durationSeconds;
    final transcript = rec.transcriptText;
    final audioUrl = rec.audioUrl;

    // Parse emotion maps
    Map<EmotionType, double> audioEmotions = rec.audioEmotions;
    Map<EmotionType, double> transcriptEmotions = rec.transcriptEmotions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: c.surfaceLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: c.outlineVariant),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: emotion.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        emotion.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emotion.displayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface,
                          ),
                        ),
                        Text(
                          _formatDate(date),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: emotion.color,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Audio emotions breakdown
              if (audioEmotions.isNotEmpty) ...[
                Text(
                  'EMOSI AUDIO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: resonanceAccent(c),
                  ),
                ),
                const SizedBox(height: 10),
                ...audioEmotions.entries.map((e) => _buildEmotionBar(e.key, e.value)),
                const SizedBox(height: 18),
              ],

              // Transcript emotions breakdown
              if (transcriptEmotions.isNotEmpty) ...[
                Text(
                  'EMOSI TEKS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: resonanceAccent(c),
                  ),
                ),
                const SizedBox(height: 10),
                ...transcriptEmotions.entries.map((e) => _buildEmotionBar(e.key, e.value)),
                const SizedBox(height: 18),
              ],

              // Transcript text
              if (transcript.isNotEmpty) ...[
                Text(
                  'TRANSCRIPT',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: resonanceAccent(c),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    border: Border.all(color: c.outlineVariant),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    transcript,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: c.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Audio download button
              if (audioUrl.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _downloadAudio(audioUrl),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: resonanceAccent(c),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2424161C),
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            PhosphorIconsRegular.downloadSimple,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unduh Audio',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionBar(EmotionType emotion, double score) {
    final c = ResonanceColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(emotion.emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(
              emotion.displayName,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: c.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ResonanceProgressBar(
              c: c,
              progress: score.clamp(0.0, 1.0),
              color: emotion.color,
              height: 6,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: c.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadAudio(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka audio: $e')),
        );
      }
    }
  }
}