import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/emotion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';
import 'user_detail_screen.dart';
import 'widgets/admin_charts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  Map<EmotionType, int> _emotionDistribution = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final usersSnapshot = await firestore.collection('users').get();

      final users = <Map<String, dynamic>>[];
      final emotionDist = <EmotionType, int>{};

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final uid = userDoc.id;

        final recordingsSnapshot = await firestore
            .collection('users')
            .doc(uid)
            .collection('recordings')
            .get();

        final recordings = recordingsSnapshot.docs;

        for (final recDoc in recordings) {
          final recData = recDoc.data();
          final emotionName = recData['dominant_emotion'] as String? ?? '';
          final emotion = EmotionType.values.firstWhere(
            (e) => e.name == emotionName,
            orElse: () => EmotionType.neutral,
          );
          emotionDist[emotion] = (emotionDist[emotion] ?? 0) + 1;
        }

        users.add({
          'uid': uid,
          'name': userData['name'] as String? ?? 'User',
          'email': userData['email'] as String? ?? '',
          'psych_score': userData['psych_score'] as int?,
          'created_at': userData['created_at'],
          'recording_count': recordings.length,
        });
      }

      if (mounted) {
        setState(() {
          _users = users;
          _emotionDistribution = emotionDist;
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

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int get _totalRecordings =>
      _users.fold<int>(0, (a, u) => a + (u['recording_count'] as int));

  double get _avgPsychScore {
    final scored = _users.where((u) => u['psych_score'] != null).toList();
    if (scored.isEmpty) return 0;
    final total = scored.fold<int>(0, (a, u) => a + (u['psych_score'] as int));
    return total / scored.length;
  }

  Color _psychScoreColor(int? score) {
    if (score == null) return const Color(0xFF64748B);
    if (score >= 76) return const Color(0xFF10B981);
    if (score >= 51) return const Color(0xFFF59E0B);
    if (score >= 26) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  void _handleExportPDF() async {
    if (_users.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk di-export')),
        );
      }
      return;
    }
    try {
      final pdf = await PdfExportService.generateAllUsersReport(_users);
      await Printing.sharePdf(bytes: pdf, filename: 'laporan_pengguna.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e')),
        );
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          'Konfirmasi Logout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppTheme.textP(ctx),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari mode admin?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textS(ctx),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppTheme.textS(ctx)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: const Color(0xFFF87171),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppRouter()),
          (route) => false,
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
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                child: Text(
                  'Admin Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _handleExportPDF,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
              tooltip: 'Export PDF',
            ),
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, size: 22),
              tooltip: 'Logout',
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

                            // ── Summary Cards ─────────────────────────
                            _buildSummaryCards(),

                            const SizedBox(height: AppTheme.spaceXl),

                            // ── Emotion Distribution Chart ───────────
                            EmotionDistributionBarChart(
                              emotionCounts: _emotionDistribution,
                            ),

                            const SizedBox(height: AppTheme.spaceXl),

                            // ── Psych Score Legend ────────────────────
                            const PsychScoreLegend(),

                            const SizedBox(height: AppTheme.spaceXl),

                            // ── Search Bar ───────────────────────────
                            _buildSearchBar(),

                            const SizedBox(height: AppTheme.spaceMd),

                            // ── User List Section Header ─────────────
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.people_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Semua Pengguna',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textP(context),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    '${_filteredUsers.length}',
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

                            // ── User List ────────────────────────────
                            if (_filteredUsers.isEmpty)
                              _buildEmptyState()
                            else
                              ..._filteredUsers.map(
                                (user) => _buildUserItem(user),
                              ),

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
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: const Color(0xFFF87171),
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

  Widget _buildSummaryCards() {
    final cards = [
      (
        value: '${_users.length}',
        label: 'Pengguna',
        icon: Icons.people_rounded,
        color: AppTheme.iconColor(context),
      ),
      (
        value: _avgPsychScore > 0 ? _avgPsychScore.toStringAsFixed(0) : '--',
        label: 'Rata Skor',
        icon: Icons.favorite_rounded,
        color: _psychScoreColor(_avgPsychScore.round()),
      ),
      (
        value: '$_totalRecordings',
        label: 'Rekaman',
        icon: Icons.mic_rounded,
        color: AppTheme.primaryColor,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Container(
            margin: EdgeInsets.only(right: i < cards.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(c.icon, color: c.color, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.value,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: c.color,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.label,
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: AppTheme.textP(context),
      ),
      decoration: InputDecoration(
        hintText: 'Cari pengguna...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppTheme.textH(context),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppTheme.textH(context),
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(
                  Icons.clear_rounded,
                  color: AppTheme.textH(context),
                  size: 18,
                ),
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfVar(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceMd,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppTheme.textH(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada pengguna ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textS(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final name = user['name'] as String;
    final email = user['email'] as String;
    final psychScore = user['psych_score'] as int?;
    final scoreColor = _psychScoreColor(psychScore);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(userUid: user['uid'] as String),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scoreColor.withValues(alpha: 0.8), scoreColor],
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textP(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    email.isNotEmpty ? email : 'Tidak ada email',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textS(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                psychScore != null ? '$psychScore' : '--',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ),

            const SizedBox(width: 2),

            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textH(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
