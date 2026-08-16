import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/emotion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/resonance_colors.dart';
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
    final c = ResonanceColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: c.outlineVariant),
        ),
        title: Text(
          'Konfirmasi Logout',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.onSurface,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari mode admin?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: c.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: c.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF87171),
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
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: resonanceAccent(ResonanceColors.of(context)),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 18),

                            // ── Stat Cards ────────────────────────────
                            _buildStatGrid(),

                            const SizedBox(height: 22),

                            // ── Emotion Distribution Chart ───────────
                            _buildSectionHeader(
                              'ANALYTICS',
                              'Distribusi Emosi',
                            ),
                            const SizedBox(height: 10),
                            EmotionDistributionBarChart(
                              emotionCounts: _emotionDistribution,
                            ),

                            const SizedBox(height: 22),

                            // ── Mental Health Status ─────────────────
                            _buildSectionHeader(
                              'WELLNESS',
                              'Status Kesehatan Mental',
                            ),
                            const SizedBox(height: 10),
                            _buildPsychStatusCard(),

                            const SizedBox(height: 22),

                            // ── User List Section ────────────────────
                            _buildSectionHeader(
                              'USERS',
                              'Daftar Pengguna',
                              trailing: '${_filteredUsers.length}',
                            ),
                            const SizedBox(height: 12),
                            _buildSearchBar(),
                            const SizedBox(height: 14),

                            if (_filteredUsers.isEmpty)
                              _buildEmptyState()
                            else
                              ..._filteredUsers.map(
                                (user) => _buildUserItem(user),
                              ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────
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

  // ── Header hero dengan kartu berlapis Resonance ─────────────────
  Widget _buildHeader() {
    final c = ResonanceColors.of(context);
    final accent = resonanceAccent(c);

    return ResonanceCard(
      c: c,
      accent: accent,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      Color.lerp(accent, c.onSurface, 0.28)!,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.surfaceLowest.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1424161C),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: GoogleFonts.spaceGrotesk(
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
                      'ADMIN · OVERVIEW',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dashboard Admin',
                      style: GoogleFonts.spaceGrotesk(
                        color: c.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _todayLabel,
                      style: GoogleFonts.inter(
                        color: c.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              ResonanceIconButton(
                c: c,
                icon: PhosphorIconsRegular.filePdf,
                onTap: _handleExportPDF,
              ),
              const SizedBox(width: 8),
              ResonanceIconButton(
                c: c,
                icon: PhosphorIconsRegular.signOut,
                onTap: _handleLogout,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ringkasan kondisi kesehatan pengguna',
            style: GoogleFonts.inter(
              color: c.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${_users.length} pengguna terdaftar · $_totalRecordings rekaman terdeteksi',
            style: GoogleFonts.spaceGrotesk(
              color: c.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu statistik ─────────────────────────────────────────────
  Widget _buildStatGrid() {
    final c = ResonanceColors.of(context);
    final avgScore = _avgPsychScore.round();
    final stats = [
      (
        label: 'Total Pengguna',
        value: '${_users.length}',
        icon: PhosphorIconsRegular.usersThree,
        color: resonanceAccent(c),
      ),
      (
        label: 'Rata-rata Skor',
        value: _avgPsychScore > 0 ? _avgPsychScore.toStringAsFixed(0) : '--',
        icon: PhosphorIconsRegular.heartbeat,
        color: _psychScoreColor(avgScore),
      ),
      (
        label: 'Total Rekaman',
        value: '$_totalRecordings',
        icon: PhosphorIconsRegular.microphone,
        color: const Color(0xFF2E5F6E),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
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
    final c = ResonanceColors.of(context);
    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(14),
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
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.9,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header section (eyebrow mono + judul) ───────────────────────
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

  // ── Status kesehatan mental ─────────────────────────────────────
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
            _buildPillButton(
              icon: PhosphorIconsRegular.arrowsClockwise,
              label: 'Muat Ulang',
              onTap: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final c = ResonanceColors.of(context);
    final accent = resonanceAccent(c);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: accent,
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
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
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
    );
  }

  Widget _buildSearchBar() {
    final c = ResonanceColors.of(context);
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: GoogleFonts.inter(
        fontSize: 13,
        color: c.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Cari pengguna…',
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: c.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          PhosphorIconsRegular.magnifyingGlass,
          color: c.onSurfaceVariant,
          size: 18,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(
                  PhosphorIconsRegular.x,
                  color: c.onSurfaceVariant,
                  size: 16,
                ),
              )
            : null,
        filled: true,
        fillColor: c.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: resonanceAccent(c), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = ResonanceColors.of(context);
    final noUsers = _users.isEmpty;
    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(28),
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
              noUsers
                  ? PhosphorIconsRegular.users
                  : PhosphorIconsRegular.magnifyingGlass,
              size: 24,
              color: resonanceAccent(c),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            noUsers
                ? 'Belum ada pengguna terdaftar'
                : 'Tidak ada pengguna ditemukan',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final c = ResonanceColors.of(context);
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ResonanceCard(
          c: c,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withValues(alpha: 0.85),
                      scoreColor,
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1424161C),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.spaceGrotesk(
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
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isNotEmpty ? email : 'Tidak ada email',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: c.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.microphone,
                          size: 11,
                          color: c.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$recordings rekaman',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: c.onSurfaceVariant,
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  psychScore != null ? '$psychScore' : '--',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              Icon(
                PhosphorIconsRegular.caretRight,
                color: c.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}