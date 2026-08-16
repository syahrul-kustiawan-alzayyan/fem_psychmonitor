import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/emotion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
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
      final result = await DatabaseService.getAdminDashboard();

      if (mounted) {
        setState(() {
          _users = result.users;
          _emotionDistribution = result.emotionDistribution;
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

  String get _todayLabel {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Color _psychScoreColor(int? score) {
    if (score == null) return const Color(0xFF64748B);
    if (score >= 76) return const Color(0xFF10B981);
    if (score >= 51) return const Color(0xFFF59E0B);
    if (score >= 26) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  int _countInRange(int min, int max) {
    return _users.where((u) {
      final s = u['psych_score'] as int?;
      return s != null && s >= min && s <= max;
    }).length;
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
                            _buildHeader(),
                            const SizedBox(height: AppTheme.spaceMd),

                            // ── Stat Cards ────────────────────────────
                            _buildStatGrid(),

                            const SizedBox(height: AppTheme.spaceLg),

                            // ── Emotion Distribution Chart ───────────
                            _buildSectionTitle(
                              Icons.bar_chart_rounded,
                              'Distribusi Emosi',
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            EmotionDistributionBarChart(
                              emotionCounts: _emotionDistribution,
                            ),

                            const SizedBox(height: AppTheme.spaceLg),

                            // ── Mental Health Status ─────────────────
                            _buildSectionTitle(
                              Icons.health_and_safety_rounded,
                              'Status Kesehatan Mental',
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            _buildPsychStatusCard(),

                            const SizedBox(height: AppTheme.spaceLg),

                            // ── User List Section ────────────────────
                            _buildSectionTitle(
                              Icons.people_rounded,
                              'Daftar Pengguna',
                              trailing: '${_filteredUsers.length}',
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            _buildSearchBar(),
                            const SizedBox(height: AppTheme.spaceMd),

                            if (_filteredUsers.isEmpty)
                              _buildEmptyState()
                            else
                              ..._filteredUsers.map((user) =>
                                  _buildUserItem(user)),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ── Header hero dengan gradien ──────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        20,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Admin',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _todayLabel,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              _headerAction(
                icon: Icons.picture_as_pdf_rounded,
                tooltip: 'Export PDF',
                onTap: _handleExportPDF,
              ),
              const SizedBox(width: 8),
              _headerAction(
                icon: Icons.logout_rounded,
                tooltip: 'Logout',
                onTap: _handleLogout,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Ringkasan kondisi kesehatan pengguna',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${_users.length} pengguna terdaftar · $_totalRecordings rekaman terdeteksi',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ── Kartu statistik ───────────────────────────────────────────────
  Widget _buildStatGrid() {
    final stats = [
      (
        label: 'Total Pengguna',
        value: '${_users.length}',
        icon: Icons.people_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      (
        label: 'Rata-rata Skor',
        value: _avgPsychScore > 0 ? _avgPsychScore.toStringAsFixed(0) : '--',
        icon: Icons.favorite_rounded,
        color: _psychScoreColor(_avgPsychScore.round()),
      ),
      (
        label: 'Total Rekaman',
        value: '$_totalRecordings',
        icon: Icons.mic_rounded,
        color: const Color(0xFF10B981),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: _buildStatCard(
                label: stats[i].label,
                value: stats[i].value,
                icon: stats[i].icon,
                color: stats[i].color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textS(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header section ────────────────────────────────────────────────
  Widget _buildSectionTitle(IconData icon, String title, {String? trailing}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              trailing,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
      ],
    );
  }

  // ── Status kesehatan mental ───────────────────────────────────────
  Widget _buildPsychStatusCard() {
    final categories = [
      (
        label: 'Sehat Optimal',
        color: const Color(0xFF10B981),
        count: _countInRange(76, 100),
      ),
      (
        label: 'Cukup',
        color: const Color(0xFFF59E0B),
        count: _countInRange(51, 75),
      ),
      (
        label: 'Rentan',
        color: const Color(0xFFF97316),
        count: _countInRange(26, 50),
      ),
      (
        label: 'Butuh Perhatian',
        color: const Color(0xFFEF4444),
        count: _countInRange(0, 25),
      ),
    ];
    final scored = _users.where((u) => u['psych_score'] != null).length;

    return MentalHealthStatusCard(categories: categories, scored: scored);
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
    final noUsers = _users.isEmpty;
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
            noUsers ? Icons.people_outline_rounded : Icons.search_off_rounded,
            size: 40,
            color: AppTheme.textH(context),
          ),
          const SizedBox(height: 8),
          Text(
            noUsers ? 'Belum ada pengguna terdaftar' : 'Tidak ada pengguna ditemukan',
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
    final recordings = user['recording_count'] as int? ?? 0;
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scoreColor.withValues(alpha: 0.85), scoreColor],
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
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textP(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.isNotEmpty ? email : 'Tidak ada email',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textS(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.mic_none_rounded,
                        size: 11,
                        color: AppTheme.textH(context),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$recordings rekaman',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: AppTheme.textH(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
