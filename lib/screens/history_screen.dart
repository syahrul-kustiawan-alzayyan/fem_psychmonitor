import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

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

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  EmotionType? _selectedFilter;
  TimeFilter _timeFilter = TimeFilter.all;
  DateTimeRange? _customRange;
  late TabController _tabCtrl;

  List<EmotionRecord> _dbHistory = [];
  bool _isLoading = true;

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

                  // ── Section Header: Emotion Value Chart ──────────
                  _buildSectionHeader(
                    context,
                    icon: Icons.show_chart_rounded,
                    title: 'Tren Nilai Emosi',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perkembangan skor emosi dari waktu ke waktu',
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
                  _buildSectionHeader(
                    context,
                    icon: Icons.filter_list_rounded,
                    title: AppLocalizations.tr('detection_log'),
                    trailingLabel: '${_filteredHistory.length} entri',
                    trailingColor: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 14),

                  // ── List Log ─────────────────────────────────────
                  ..._filteredHistory.map((r) => _buildLogItem(context, r)),
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
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.tr('nav_history')),
          ],
        ),
        iconTheme: IconThemeData(color: AppTheme.textP(context)),
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
        label: 'Total',
        icon: Icons.bar_chart_rounded,
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
                'Belum ada data emosi',
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
                'Rata-rata: ${avgScore > 0 ? "+" : ""}${avgScore.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: avgScore >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const Spacer(),
              Text(
                '${history.length} sesi',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 260,
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.cardShadow,
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) {
                  if (v == 0) {
                    return FlLine(
                      color: AppTheme.textH(context).withValues(alpha: 0.5),
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                    );
                  }
                  return FlLine(
                    color: AppTheme.textH(context).withValues(alpha: 0.1),
                    strokeWidth: 0.8,
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
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= history.length) return const SizedBox();
                      final rec = history[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rec.emotion.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${rec.timestamp.day}/${rec.timestamp.month}',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textH(context),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    reservedSize: 36,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2.5,
                    getTitlesWidget: (v, _) {
                      final label = v > 0 ? '+${v.toStringAsFixed(0)}' : v.toStringAsFixed(0);
                      return Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: v > 0
                              ? const Color(0xFF10B981)
                              : v < 0
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.textH(context),
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
                  curveSmoothness: 0.25,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF6366F1)],
                  ),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, pct, bar, idx) {
                      final dotColor = idx < emotionColors.length
                          ? emotionColors[idx]
                          : AppTheme.primaryColor;
                      return FlDotCirclePainter(
                        radius: 5,
                        color: dotColor,
                        strokeWidth: 2.5,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  // Area hijau di atas garis 0
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
                  // Area merah di bawah garis 0
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
                          ? '${rec.emotion.emoji} ${rec.emotion.displayName}\nSkor: ${rec.emotionScoreLabel} • ${rec.confidencePercent}'
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
        ),
      ],
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
        children: freq.entries.map((entry) {
          final pct = entry.value / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                // Emotion icon + name
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: entry.key.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(entry.key.icon, color: entry.key.color, size: 14),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    entry.key.displayName,
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
                          color: entry.key.color.withValues(alpha: 0.1),
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
                            color: entry.key.color,
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
                // Count + percent
                Text(
                  '${entry.value}x',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: entry.key.color,
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
              : '${e.emoji} ${e.displayName}';
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
                        // Name + time + score
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
  // Detail Bottom Sheet: data lengkap hasil deteksi
  // ─────────────────────────────────────────────────────────────
  void _showRecordDetail(BuildContext context, EmotionRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailBottomSheet(record: record),
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
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
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
// _DetailBottomSheet — Menampilkan detail lengkap deteksi emosi
// ─────────────────────────────────────────────────────────────────────────────
class _DetailBottomSheet extends StatelessWidget {
  final EmotionRecord record;

  const _DetailBottomSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    final emotion = record.emotion;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.textH(context).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header: Emoji besar + nama emosi + skor
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: emotion.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(emotion.emoji, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emotion.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textP(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildTag(
                                record.confidencePercent,
                                emotion.color,
                              ),
                              const SizedBox(width: 8),
                              _buildTag(
                                'Skor: ${record.emotionScoreLabel}',
                                record.emotionScore >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Waktu deteksi
                _buildInfoRow(
                  Icons.access_time_rounded,
                  'Waktu Deteksi',
                  record.formattedTime,
                  context,
                ),
                const SizedBox(height: 12),

                // Nilai emosi
                _buildInfoRow(
                  Icons.trending_up_rounded,
                  'Nilai Emosi',
                  '${emotion.valueLabel} (skala -5 s/d +5)',
                  context,
                ),
                const SizedBox(height: 12),

                // Confidence
                _buildInfoRow(
                  Icons.speed_rounded,
                  'Tingkat Kepercayaan',
                  '${(record.confidence * 100).toStringAsFixed(1)}%',
                  context,
                ),
                const SizedBox(height: 12),

                // Skor berbobot
                _buildInfoRow(
                  Icons.calculate_rounded,
                  'Skor Berbobot',
                  '${emotion.valueLabel} × ${record.confidencePercent} = ${record.emotionScoreLabel}',
                  context,
                ),

                const SizedBox(height: 24),

                // Divider
                Container(
                  height: 1,
                  color: AppTheme.textH(context).withValues(alpha: 0.1),
                ),

                const SizedBox(height: 20),

                // Tabel semua emosi
                Text(
                  '📊 Skala Nilai Emosi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...EmotionType.values.map((e) => _buildEmotionRow(context, e, e == emotion)),

                const SizedBox(height: 24),

                // Saran
                Text(
                  '💡 Saran Berdasarkan Emosi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...emotion.recordingSuggestions.take(3).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: emotion.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textS(context),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textH(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionRow(BuildContext context, EmotionType e, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? e.color.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: e.color.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Text(e.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e.displayName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? e.color : AppTheme.textP(context),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (e.emotionValue >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444))
                  .withValues(alpha: isActive ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              e.valueLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: e.emotionValue >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: e.color, size: 18),
          ],
        ],
      ),
    );
  }
}
