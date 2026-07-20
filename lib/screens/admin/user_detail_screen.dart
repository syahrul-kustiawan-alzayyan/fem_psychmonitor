import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emotion_model.dart';
import '../../services/database_service.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';

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
  List<Map<String, dynamic>> _recordings = [];

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
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(widget.userUid).get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            _error = 'Data pengguna tidak ditemukan';
            _isLoading = false;
          });
        }
        return;
      }

      final userData = userDoc.data()!;

      final recordingsSnapshot = await firestore
          .collection('users')
          .doc(widget.userUid)
          .collection('recordings')
          .orderBy('date', descending: true)
          .get();

      final recordings = recordingsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

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
    DateTime date;
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is String) {
      date = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else {
      return '--';
    }
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
      final recordings = _recordings
          .map((r) => RecordingData.fromFirestore(r['id']?.toString() ?? '', r))
          .toList();
      final pdf = await PdfExportService.generateUserReport(_userData!, recordings);
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          title: Text(
            'Detail Pengguna',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textP(context),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _handleExportPDF,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
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
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )
              : _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppTheme.spaceMd),

                            // ── Profile Header ────────────────────────
                            _buildProfileHeader(),

                            const SizedBox(height: AppTheme.spaceXl),

                            // ── Mental Health Score ──────────────────
                            _buildMentalHealthCard(),

                            const SizedBox(height: AppTheme.spaceLg),

                            // ── MBTI Section ────────────────────────
                            _buildMBTISection(),

                            const SizedBox(height: AppTheme.spaceLg),

                            // ── Big Five Section ────────────────────
                            _buildBigFiveSection(),

                            const SizedBox(height: AppTheme.spaceXl),

                            // ── Recordings Section ──────────────────
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFF87171),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textS(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Muat Ulang', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _userData?['name'] as String? ?? 'User';
    final email = _userData?['email'] as String? ?? '';
    final uid = widget.userUid;
    final createdAt = _userData?['created_at'];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final psychScore = _userData?['psych_score'] as int?;
    final scoreColor = _psychScoreColor(psychScore);

    String dateStr = '--';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scoreColor.withValues(alpha: 0.7), scoreColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 4),

          // Email
          if (email.isNotEmpty)
            Text(
              email,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(context),
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
                Icons.fingerprint_rounded,
                'UID: ${uid.substring(0, uid.length.clamp(0, 12))}...',
              ),
              _buildInfoChip(
                Icons.calendar_today_rounded,
                'Bergabung: $dateStr',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfVar(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textS(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.textS(context),
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
        borderRadius: BorderRadius.circular(22),
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
                'Skor Kesehatan Mental',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          if (psychScore != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
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

  Widget _buildMBTISection() {
    final mbtiType = _userData?['mbti_type'] as String? ?? '';
    final mbtiScores = _userData?['mbti_scores'] as Map<String, dynamic>? ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tipe Kepribadian MBTI',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (mbtiType.isNotEmpty) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  mbtiType,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Text(
                'Belum mengisi asesmen MBTI',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textH(context),
                ),
              ),
            ),
          ],

          if (mbtiScores.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...mbtiScores.entries.map((entry) {
              final label = _mbtiDimensionLabel(entry.key);
              final value = (entry.value as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMBTIBar(entry.key, label, value),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _mbtiDimensionLabel(String key) {
    switch (key) {
      case 'E': return 'Ekstrovert';
      case 'I': return 'Introvert';
      case 'S': return 'Sensing';
      case 'N': return 'Intuition';
      case 'T': return 'Thinking';
      case 'F': return 'Feeling';
      case 'J': return 'Judging';
      case 'P': return 'Perceiving';
      default: return key;
    }
  }

  Widget _buildMBTIBar(String key, String label, double value) {
    final maxScore = 10.0;
    final fraction = (value / maxScore).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$key - $label',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textP(context),
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textS(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.surfVar(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBigFiveSection() {
    final bigFiveScores = _userData?['bigfive_scores'] as Map<String, dynamic>? ?? {};

    if (bigFiveScores.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Profil Big Five',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textP(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Belum mengisi asesmen Big Five',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textH(context),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_search_rounded, size: 18, color: AppTheme.iconColor(context)),
              const SizedBox(width: 8),
              Text(
                'Profil Big Five',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...dimensions.entries.map((entry) {
            final score = (bigFiveScores[entry.key] as num?)?.toDouble() ?? 0.0;
            final fraction = (score / 5.0).clamp(0.0, 1.0);
            final level = score >= 3.5 ? 'Tinggi' : (score <= 2.5 ? 'Rendah' : 'Sedang');
            final levelColor = score >= 3.5
                ? const Color(0xFF10B981)
                : (score <= 2.5 ? const Color(0xFFF59E0B) : AppTheme.textS(context));

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${entry.key} - ${entry.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Text(
                              level,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: levelColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            score.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textS(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.surfVar(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Riwayat Rekaman',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${_recordings.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMd),

        if (_recordings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.mic_off_rounded, size: 36, color: AppTheme.textH(context)),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada rekaman',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textS(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recordings.map((rec) => _buildRecordingItem(rec)),
      ],
    );
  }

  Widget _buildRecordingItem(Map<String, dynamic> rec) {
    final emotionName = rec['dominant_emotion'] as String? ?? 'neutral';
    final emotion = EmotionType.values.firstWhere(
      (e) => e.name == emotionName,
      orElse: () => EmotionType.neutral,
    );
    final confidence = (rec['confidence'] as num?)?.toDouble() ?? 0.0;
    final date = rec['date'];
    final duration = (rec['duration_seconds'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => _showRecordingDetail(rec),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.cardShadow,
        ),
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
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: emotion.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          '${(confidence * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: emotion.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textS(context),
                    ),
                  ),
                ],
              ),
            ),

            // Duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.timer_rounded, size: 14, color: AppTheme.textH(context)),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(duration),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textS(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordingDetail(Map<String, dynamic> rec) {
    final emotionName = rec['dominant_emotion'] as String? ?? 'neutral';
    final emotion = EmotionType.values.firstWhere(
      (e) => e.name == emotionName,
      orElse: () => EmotionType.neutral,
    );
    final confidence = (rec['confidence'] as num?)?.toDouble() ?? 0.0;
    final date = rec['date'];
    final duration = (rec['duration_seconds'] as num?)?.toInt() ?? 0;
    final transcript = rec['transcript_text'] as String? ?? '';
    final audioUrl = rec['audio_url'] as String? ?? '';

    // Parse emotion maps
    Map<EmotionType, double> audioEmotions = {};
    final rawAudio = rec['audio_emotions'] as Map<String, dynamic>?;
    if (rawAudio != null) {
      audioEmotions = rawAudio.map((k, v) {
        final e = EmotionType.values.firstWhere(
          (x) => x.name == k,
          orElse: () => EmotionType.neutral,
        );
        return MapEntry(e, (v as num).toDouble());
      });
    }

    Map<EmotionType, double> transcriptEmotions = {};
    final rawTranscript = rec['transcript_emotions'] as Map<String, dynamic>?;
    if (rawTranscript != null) {
      transcriptEmotions = rawTranscript.map((k, v) {
        final e = EmotionType.values.firstWhere(
          (x) => x.name == k,
          orElse: () => EmotionType.neutral,
        );
        return MapEntry(e, (v as num).toDouble());
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppTheme.textH(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Text(emotion.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emotion.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textP(context),
                          ),
                        ),
                        Text(
                          _formatDate(date),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textS(context),
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
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: emotion.color,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textS(context),
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
                  'Emosi Audio',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 8),
                ...audioEmotions.entries.map((e) => _buildEmotionBar(e.key, e.value)),
                const SizedBox(height: 16),
              ],

              // Transcript emotions breakdown
              if (transcriptEmotions.isNotEmpty) ...[
                Text(
                  'Emosi Teks',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 8),
                ...transcriptEmotions.entries.map((e) => _buildEmotionBar(e.key, e.value)),
                const SizedBox(height: 16),
              ],

              // Transcript text
              if (transcript.isNotEmpty) ...[
                Text(
                  'Transkrip',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfVar(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transcript,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textP(context),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Audio download button
              if (audioUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadAudio(audioUrl),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Unduh Audio', style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(emotion.emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: Text(
              emotion.displayName,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textP(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: emotion.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(emotion.color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textS(context),
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
