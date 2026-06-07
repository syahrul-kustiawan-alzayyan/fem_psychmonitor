import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import 'record_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HistoryScreen — Riwayat & Analitik Psikis
//
// Arsitektur Widget (modular):
//   • _buildStatsSummary()  → 3 kartu statistik
//   • _buildWeeklyChart()   → LineChart tren mingguan (fl_chart)
//   • _buildFilterChips()   → Filter emosi horizontal
//   • _buildLogList()       → List log emosi harian
// ─────────────────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// ── Enum filter waktu ──
enum TimeFilter { all, today, week7, month30, custom }

// ── Custom Dot Painters with data labels ──

class _ScoreLabelDotPainter extends FlDotCirclePainter {
  _ScoreLabelDotPainter({
    required this.label,
    required super.radius,
    required super.color,
    super.strokeWidth,
    super.strokeColor,
  });

  final String label;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    super.draw(canvas, spot, offset);

    if (label.isEmpty) return;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(offset, radius + 5, glowPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = offset.dx - tp.width / 2;
    final dy = offset.dy - radius - tp.height - 4;

    final bgRect = Rect.fromLTWH(dx - 4, dy - 2, tp.width + 8, tp.height + 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    tp.paint(canvas, Offset(dx, dy));
  }
}

class _EmotionLabelDotPainter extends FlDotCirclePainter {
  _EmotionLabelDotPainter({
    required this.label,
    required super.radius,
    required super.color,
    super.strokeWidth,
    super.strokeColor,
  });

  final String label;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    super.draw(canvas, spot, offset);

    if (label.isEmpty) return;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(offset, radius + 5, glowPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = offset.dx - tp.width / 2;
    final dy = offset.dy - radius - tp.height - 4;

    final bgRect = Rect.fromLTWH(dx - 4, dy - 2, tp.width + 8, tp.height + 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    tp.paint(canvas, Offset(dx, dy));
  }
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  EmotionType? _selectedFilter;
  TimeFilter _timeFilter = TimeFilter.all;
  DateTimeRange? _customRange;
  late TabController _tabCtrl;

  List<EmotionRecord> _dbHistory = [];
  bool _isLoading = true;
  int? _psychScore;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await DatabaseService.getUser();
    final recordings = await DatabaseService.getRecordings(userId: user?.id);
    if (mounted) {
      setState(() {
        _dbHistory = recordings.map((e) => e.toEmotionRecord()).toList();
        _isLoading = false;
        _psychScore = user?.psychologicalScore;
      });
    }
  }

  // ── Filter history berdasarkan waktu + emosi ────────────
  List<EmotionRecord> get _filteredHistory {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    List<EmotionRecord> result = _dbHistory;

    // Filter waktu
    switch (_timeFilter) {
      case TimeFilter.all:
        break;
      case TimeFilter.today:
        result = result.where((r) => r.timestamp.isAfter(todayStart)).toList();
        break;
      case TimeFilter.week7:
        final weekAgo = now.subtract(const Duration(days: 7));
        result = result.where((r) => r.timestamp.isAfter(weekAgo)).toList();
        break;
      case TimeFilter.month30:
        final monthAgo = now.subtract(const Duration(days: 30));
        result = result.where((r) => r.timestamp.isAfter(monthAgo)).toList();
        break;
      case TimeFilter.custom:
        if (_customRange != null) {
          result = result
              .where(
                (r) =>
                    r.timestamp.isAfter(
                      _customRange!.start.subtract(const Duration(days: 1)),
                    ) &&
                    r.timestamp.isBefore(
                      _customRange!.end.add(const Duration(days: 1)),
                    ),
              )
              .toList();
        }
        break;
    }

    // Filter emosi
    if (_selectedFilter != null) {
      result = result.where((r) => r.emotion == _selectedFilter).toList();
    }

    return result;
  }

  // ── Frequency map berdasarkan filtered data ────────────
  Map<EmotionType, int> get _filteredFrequency {
    final freq = <EmotionType, int>{};
    for (final r in _filteredHistory) {
      freq[r.emotion] = (freq[r.emotion] ?? 0) + 1;
    }
    return freq;
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
              secondary: AppTheme.secondaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _timeFilter = TimeFilter.custom;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: GradientBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTheme.spaceMd),

                  // ── Filter Waktu ──────────────────────────────────
                  _buildTimeFilterBar(),
                  const SizedBox(height: AppTheme.spaceLg),

                  // ── Ringkasan Statistik ──────────────────────────
                  _buildStatsSummary(context),

                  const SizedBox(height: AppTheme.spaceXl),

                  // ── Section Header: Mental Score Chart ──────────
                  _buildSectionHeader(
                    context,
                    icon: Icons.monitor_heart_outlined,
                    title: AppLocalizations.tr('mental_score_trend'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.tr('mental_score_over_time'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textS(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMentalScoreChart(),

                  const SizedBox(height: AppTheme.spaceXl),

                  // ── Section Header: Emotion Value Chart ──────────
                  _buildSectionHeader(
                    context,
                    icon: Icons.show_chart_rounded,
                    title: AppLocalizations.tr('emotion_value_trend'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.tr('emotion_score_over_time'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textS(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Weekly Line Chart ────────────────────────────
                  _buildWeeklyLineChart(),

                  const SizedBox(height: AppTheme.spaceXl),

                  // ── Section Header: Emotional Breakdown ──────────
                  _buildSectionHeader(
                    context,
                    icon: Icons.donut_small_rounded,
                    title: AppLocalizations.tr('emotion_breakdown'),
                  ),
                  const SizedBox(height: 12),
                  _buildEmotionBreakdown(),

                  const SizedBox(height: AppTheme.spaceXl),

                  // ── Filter Chip ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildSectionHeader(
                          context,
                          icon: Icons.filter_list_rounded,
                          title: AppLocalizations.tr('detection_log'),
                          trailingLabel: AppLocalizations.tr('entries_count').replaceAll('{count}', _filteredHistory.length.toString()),
                          trailingColor: AppTheme.primaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _FullDetectionLogScreen(
                                allHistory: _dbHistory,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.iconColor(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            AppLocalizations.tr('see_all'),
                            style: GoogleFonts.poppins(
                              color: AppTheme.iconColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 14),

                  // ── List Log (max 5 ditampilkan) ──────────────────
                  ..._filteredHistory.take(5).map((r) => _buildLogItem(context, r)),
                  if (_filteredHistory.length > 5) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _FullDetectionLogScreen(
                                allHistory: _dbHistory,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                        label: Text(
                          AppLocalizations.tr('see_more_count').replaceAll('{count}', (_filteredHistory.length - 5).toString()),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ), // End GradientBackground
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: AppBar Custom - Sama dengan Record Screen
  // ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.bar_chart_rounded,
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
                AppLocalizations.tr('nav_history'),
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
        iconTheme: IconThemeData(
          color: AppTheme.textP(context),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Filter Waktu — Horizontal Chips
  // ─────────────────────────────────────────────────────────────
  Widget _buildTimeFilterBar() {
    final filters = [
      (
        filter: TimeFilter.all,
        label: AppLocalizations.tr('filter_all_time'),
        icon: Icons.all_inclusive_rounded,
      ),
      (
        filter: TimeFilter.today,
        label: AppLocalizations.tr('filter_today'),
        icon: Icons.today_rounded,
      ),
      (
        filter: TimeFilter.week7,
        label: AppLocalizations.tr('filter_7_days'),
        icon: Icons.date_range_rounded,
      ),
      (
        filter: TimeFilter.month30,
        label: AppLocalizations.tr('filter_30_days'),
        icon: Icons.calendar_month_rounded,
      ),
      (
        filter: TimeFilter.custom,
        label: AppLocalizations.tr('filter_custom'),
        icon: Icons.edit_calendar_rounded,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isActive = _timeFilter == f.filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (f.filter == TimeFilter.custom) {
                  _pickCustomRange();
                } else {
                  setState(() => _timeFilter = f.filter);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isActive ? AppTheme.primaryGradient : null,
                  color: isActive ? null : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.icon,
                      size: 14,
                      color: isActive ? Colors.white : AppTheme.textS(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeFilter == TimeFilter.custom &&
                              f.filter == TimeFilter.custom &&
                              _customRange != null
                          ? '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}'
                          : f.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : AppTheme.textS(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Ringkasan 3 kartu statistik mini
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatsSummary(BuildContext context) {
    final history = _filteredHistory;
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
        label: AppLocalizations.tr('total'),
        icon: Icons.bar_chart_rounded,
        color: AppTheme.iconColor(context),
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
        icon: Icons.sentiment_dissatisfied_rounded,
        color: const Color(0xFFF87171),
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: s.color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(s.icon, color: s.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  s.value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
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
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Emotion Value Line Chart (fl_chart)
  //
  // X-axis : urutan sesi rekaman (#1 terlama → #N terbaru)
  // Y-axis : nilai emosi berbobot (-5 s/d +5)
  // Dot    : berwarna sesuai EmotionType yang terdeteksi
  // Tooltip: emoji + nama + nilai emosi + confidence
  // Area   : hijau di atas 0, merah di bawah 0
  // ─────────────────────────────────────────────────────────────
  Widget _buildWeeklyLineChart() {
    // Urutkan history dari sesi terlama ke terbaru
    final history = List<EmotionRecord>.from(_filteredHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart_rounded, size: 40, color: AppTheme.textH(context)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.tr('no_emotion_data'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tiap FlSpot: x = indeks sesi, y = emotionScore (-5 s/d +5)
    final spots = List.generate(
      history.length,
      (i) => FlSpot(i.toDouble(), history[i].emotionScore),
    );

    // Warna per titik sesuai emosi rekaman
    final emotionColors = history.map((r) => r.emotion.color).toList();

    // Rata-rata skor emosi untuk label
    final avgScore = history.fold<double>(0, (sum, r) => sum + r.emotionScore) / history.length;

    return Column(
      children: [
        // Rata-rata skor
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: (avgScore >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (avgScore >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                avgScore >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: avgScore >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.tr('average_score_label').replaceAll('{score}', '${avgScore > 0 ? "+" : ""}${avgScore.toStringAsFixed(1)}'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: avgScore >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.tr('sessions_count').replaceAll('{count}', history.length.toString()),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildEmotionLegend(context),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 270,
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.cardShadow,
          ),
          child: history.length > 10
              ? Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 260,
                      child: _buildYAxisLabels(context),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: (MediaQuery.of(context).size.width - 48 - 32) * (history.length / 10),
                          height: 260,
                          child: _buildChart(
                            context, history, spots, emotionColors,
                            showLeftTitles: false,
                            showDataLabels: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  height: 260,
                  child: _buildChart(context, history, spots, emotionColors),
                ),
        ),
      ],
    );
  }

  Widget _buildEmotionLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.textH(context).withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: EmotionType.values.map((e) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                e.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMentalScoreChart() {
    final history = List<EmotionRecord>.from(_filteredHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (history.isEmpty || _psychScore == null) {
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_heart_outlined, size: 40, color: AppTheme.textH(context)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.tr('no_emotion_data'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final baseScore100 = ((60 - _psychScore!) / 60 * 100).toDouble();

    final spots = List.generate(
      history.length,
      (i) {
        final adjustment = history[i].emotionScore;
        final score = (baseScore100 + adjustment).clamp(0.0, 100.0);
        return FlSpot(i.toDouble(), score);
      },
    );

    final avgScore = spots.fold<double>(0, (sum, s) => sum + s.y) / spots.length;

    Color scoreColor(double s) {
      if (s >= 75) return const Color(0xFF10B981);
      if (s >= 50) return const Color(0xFFF59E0B);
      if (s >= 25) return const Color(0xFFF97316);
      return const Color(0xFFEF4444);
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: scoreColor(avgScore).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scoreColor(avgScore).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                avgScore >= 50 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: scoreColor(avgScore),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.tr('average_score_label').replaceAll('{score}', avgScore.toStringAsFixed(0)),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scoreColor(avgScore),
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.tr('sessions_count').replaceAll('{count}', history.length.toString()),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildScoreLegend(context),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 270,
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.cardShadow,
          ),
          child: history.length > 10
              ? Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 260,
                      child: _buildMentalScoreYAxisLabels(context),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: (MediaQuery.of(context).size.width - 48 - 32) * (history.length / 10),
                          height: 260,
                          child: _buildMentalScoreChartData(context, history, spots, scoreColor, showLeftTitles: false, showDataLabels: false),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  height: 260,
                  child: _buildMentalScoreChartData(context, history, spots, scoreColor),
                ),
        ),
      ],
    );
  }

  Widget _buildScoreLegend(BuildContext context) {
    final items = [
      (Color(0xFF10B981), '75-100', AppLocalizations.tr('psych_excellent')),
      (Color(0xFFF59E0B), '50-74', AppLocalizations.tr('psych_good')),
      (Color(0xFFF97316), '25-49', AppLocalizations.tr('psych_fair')),
      (Color(0xFFEF4444), '0-24', AppLocalizations.tr('psych_needs_attention')),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.textH(context).withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.$1,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$2,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: item.$1,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    item.$3,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textS(context),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMentalScoreChartData(
    BuildContext context,
    List<EmotionRecord> history,
    List<FlSpot> spots,
    Color Function(double) scoreColor, {
    bool showLeftTitles = true,
    bool showDataLabels = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) {
              Color lineColor;
              if (v == 25 || v == 50 || v == 75) {
                lineColor = scoreColor(v).withValues(alpha: 0.5);
                return FlLine(
                  color: lineColor,
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                );
              }
              return FlLine(
                color: AppTheme.textH(context).withValues(alpha: 0.06),
                strokeWidth: 0.6,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (history.length - 1).toDouble().clamp(0, double.infinity),
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLeftTitles && history.length <= 10,
                interval: history.length > 1 ? (history.length - 1) / 3 : 1,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                  final date = history[idx].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textH(context).withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLeftTitles,
                interval: 25,
                getTitlesWidget: (v, _) {
                  return Text(
                    v.toStringAsFixed(0),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textH(context).withValues(alpha: 0.7),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) {
                  return _ScoreLabelDotPainter(
                    label: showDataLabels ? spot.y.toStringAsFixed(0) : '',
                    radius: 6,
                    color: scoreColor(spot.y),
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  );
                },
              ),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF4444),
                  const Color(0xFFF97316),
                  const Color(0xFFF59E0B),
                  const Color(0xFF10B981),
                ],
                stops: const [0.0, 0.25, 0.5, 0.75],
              ),
              aboveBarData: BarAreaData(
                show: true,
                applyCutOffY: true,
                cutOffY: 25,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.08),
                    const Color(0xFF10B981).withValues(alpha: 0.0),
                  ],
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                applyCutOffY: true,
                cutOffY: 25,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.06),
                    const Color(0xFFEF4444).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) {
                return scoreColor(spot.y).withValues(alpha: 0.92);
              },
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final i = spot.spotIndex;
                  String label;
                  if (spot.y >= 75) {
                    label = AppLocalizations.tr('psych_excellent');
                  } else if (spot.y >= 50) {
                    label = AppLocalizations.tr('psych_good');
                  } else if (spot.y >= 25) {
                    label = AppLocalizations.tr('psych_fair');
                  } else {
                    label = AppLocalizations.tr('psych_needs_attention');
                  }
                  final date = i < history.length
                      ? '${history[i].timestamp.day}/${history[i].timestamp.month}'
                      : '';
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(0)}\n$date • $label',
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMentalScoreYAxisLabels(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('100', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textH(context))),
          Text('75', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textH(context))),
          Text('50', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textH(context))),
          Text('25', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textH(context))),
          Text('0', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textH(context))),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<EmotionRecord> history,
    List<FlSpot> spots,
    List<Color> emotionColors, {
    bool showLeftTitles = true,
    bool showDataLabels = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) {
              if (v == 0) {
                return FlLine(
                  color: AppTheme.textH(context).withValues(alpha: 0.5),
                  strokeWidth: 2,
                  dashArray: [4, 4],
                );
              }
              return FlLine(
                color: AppTheme.textH(context).withValues(alpha: 0.08),
                strokeWidth: 0.6,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (history.length - 1).toDouble().clamp(0, double.infinity),
          minY: -5.5,
          maxY: 5.5,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLeftTitles && history.length <= 10,
                interval: history.length > 1 ? (history.length - 1) / 3 : 1,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                  final date = history[idx].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textH(context).withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLeftTitles,
                interval: 2.5,
                getTitlesWidget: (v, _) {
                  final label = v > 0 ? '+${v.toStringAsFixed(0)}' : v.toStringAsFixed(0);
                  return Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: v > 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.8)
                          : v < 0
                              ? const Color(0xFFEF4444).withValues(alpha: 0.8)
                              : AppTheme.textH(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              gradient: LinearGradient(
                colors: [const Color(0xFF10B981), AppTheme.primaryDark],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) {
                  final dotColor = idx < emotionColors.length
                      ? emotionColors[idx]
                      : AppTheme.primaryColor;
                  final label = spot.y > 0
                      ? '+${spot.y.toStringAsFixed(1)}'
                      : spot.y.toStringAsFixed(1);
                  return _EmotionLabelDotPainter(
                    label: showDataLabels ? label : '',
                    radius: 6,
                    color: dotColor,
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  );
                },
              ),
              aboveBarData: BarAreaData(
                show: true,
                cutOffY: 0,
                applyCutOffY: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.15),
                    const Color(0xFF10B981).withValues(alpha: 0.0),
                  ],
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                cutOffY: 0,
                applyCutOffY: true,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.12),
                    const Color(0xFFEF4444).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) {
                final i = spot.x.toInt();
                if (i >= 0 && i < history.length) {
                  return history[i].emotion.color.withValues(alpha: 0.92);
                }
                return AppTheme.textP(context).withValues(alpha: 0.9);
              },
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((s) {
                  final i = s.x.toInt();
                  final rec = (i >= 0 && i < history.length)
                      ? history[i]
                      : null;
                  final label = rec != null
                      ? AppLocalizations.tr('chart_tooltip_format')
                          .replaceAll('{emoji}', rec.emotion.emoji)
                          .replaceAll('{name}', rec.emotion.displayName)
                          .replaceAll('{score}', rec.emotionScoreLabel)
                          .replaceAll('{confidence}', rec.confidencePercent)
                      : s.y.toStringAsFixed(1);
                  return LineTooltipItem(
                    label,
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYAxisLabels(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('+5', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
          Text('+2.5', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
          Text('0', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textH(context))),
          Text('-2.5', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
          Text('-5', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Distribusi Emosi — horizontal pill bars
  // ─────────────────────────────────────────────────────────────
  Widget _buildEmotionBreakdown() {
    final freq = _filteredFrequency;
    final total = freq.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: EmotionType.values.map((emotion) {
          final count = freq[emotion] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    emotion.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textP(context),
                    ),
                  ),
                ),
                // Progress pill
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: emotion.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: emotion.color,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Count
                Text(
                  '${count}x',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: emotion.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Filter Chips horizontal
  // ─────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final all = [null, ...EmotionType.values];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: all.map((e) {
          final isSelected = _selectedFilter == e;
          final label = e == null
              ? AppLocalizations.tr('all_filter')
                  : e.displayName;
          final color = e == null ? AppTheme.primaryColor : e.color;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Item Log Emosi — tappable card dengan accent border
  // ─────────────────────────────────────────────────────────────
  Widget _buildLogItem(BuildContext context, EmotionRecord record) {
    return GestureDetector(
      onTap: () => _showRecordDetail(context, record),
      child: Container(
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
                // Left accent border
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
                        // Icon
                        Image.asset(
                          record.emotion.assetIconPath,
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.emotion.displayName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.textP(context),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: AppTheme.textH(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    record.formattedTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: AppTheme.textS(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Emotion score badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (record.emotionScore >= 0
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444))
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      record.emotionScoreLabel,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: record.emotionScore >= 0
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Confidence chip + chevron
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: record.emotion.color.withValues(
                                  alpha: 0.12,
                                ),
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
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textH(context),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Detail Data Rekaman: navigasi ke halaman detail
  // ─────────────────────────────────────────────────────────────
  void _showRecordDetail(BuildContext context, EmotionRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordDetailScreen(record: record),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: Section Header reusable
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
            color: AppTheme.iconColor(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.iconColor(context), size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.textP(context)),
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// _FullDetectionLogScreen — Halaman lengkap log deteksi dengan filter
// ─────────────────────────────────────────────────────────────────────────────
class _FullDetectionLogScreen extends StatefulWidget {
  final List<EmotionRecord> allHistory;
  const _FullDetectionLogScreen({required this.allHistory});

  @override
  State<_FullDetectionLogScreen> createState() =>
      _FullDetectionLogScreenState();
}

class _FullDetectionLogScreenState extends State<_FullDetectionLogScreen> {
  EmotionType? _filterEmotion;
  String _sortOrder = 'newest';
  String _searchQuery = '';

  List<EmotionRecord> get _filtered {
    List<EmotionRecord> result = widget.allHistory;
    if (_filterEmotion != null) {
      result = result.where((r) => r.emotion == _filterEmotion).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((r) =>
              r.emotion.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.emotion.emoji.contains(_searchQuery))
          .toList();
    }
    if (_sortOrder == 'oldest') {
      result = List.from(result)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
      result = List.from(result)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.iconColor(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.list_alt_rounded, color: AppTheme.iconColor(context), size: 16),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.tr('detection_log'),
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        iconTheme: IconThemeData(color: AppTheme.textP(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textP(context)),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.tr('search_emotion_hint'),
                          hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textH(context)),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.textH(context)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _sortOrder = _sortOrder == 'newest' ? 'oldest' : 'newest';
                    }),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortOrder == 'newest' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            size: 16, color: AppTheme.iconColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(_sortOrder == 'newest' ? AppLocalizations.tr('sort_newest') : AppLocalizations.tr('sort_oldest'),
                              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.iconColor(context))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                children: [
                  _buildChip(null, AppLocalizations.tr('all_filter'), widget.allHistory.length),
                  ...EmotionType.values.map((e) {
                    final count = widget.allHistory.where((r) => r.emotion == e).length;
                    return _buildChip(e, e.displayName, count);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(AppLocalizations.tr('results_count').replaceAll('{count}', filtered.length.toString()),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textH(context)),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.tr('no_data_found'),
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textS(context))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildFullLogItem(context, filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(EmotionType? emotion, String label, int count) {
    final isActive = _filterEmotion == emotion;
    final chipColor = emotion?.color ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterEmotion = emotion),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? chipColor.withValues(alpha: 0.15) : AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: isActive ? chipColor.withValues(alpha: 0.5) : AppTheme.textH(context).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? chipColor : AppTheme.textS(context))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? chipColor.withValues(alpha: 0.2) : AppTheme.textH(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count', style: GoogleFonts.poppins(fontSize: 10,
                    fontWeight: FontWeight.w700, color: isActive ? chipColor : AppTheme.textH(context))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullLogItem(BuildContext context, EmotionRecord record) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordDetailScreen(record: record),
          ),
        );
      },
      child: Container(
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
              Container(width: 4, decoration: BoxDecoration(color: record.emotion.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd), bottomLeft: Radius.circular(AppTheme.radiusMd)))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      Image.asset(
                        record.emotion.assetIconPath,
                        width: 56,
                        height: 56,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.emotion.displayName,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textP(context)),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 11, color: AppTheme.textH(context)),
                                const SizedBox(width: 4),
                                Text(record.formattedTime,
                                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textS(context))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: (record.emotionScore >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(record.emotionScoreLabel,
                                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700,
                                          color: record.emotionScore >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: record.emotion.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(record.confidencePercent,
                            style: GoogleFonts.poppins(color: record.emotion.color, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
