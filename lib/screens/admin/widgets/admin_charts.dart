import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/emotion_model.dart';
import '../../../theme/app_theme.dart';

class EmotionDistributionBarChart extends StatelessWidget {
  final Map<EmotionType, int> emotionCounts;

  const EmotionDistributionBarChart({
    super.key,
    required this.emotionCounts,
  });

  @override
  Widget build(BuildContext context) {
    final total = emotionCounts.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        width: double.infinity,
        height: 220,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 40, color: AppTheme.textH(context)),
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

    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: AppTheme.iconColor(context)),
              const SizedBox(width: 8),
              Text(
                'Distribusi Emosi',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textP(context),
                ),
              ),
              const Spacer(),
              Text(
                '$total total',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxCount().toDouble() * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.primaryDark,
                    getTooltipItem: (group, groupIdx, rod, rodIdx) {
                      final emotion = EmotionType.values[group.x];
                      final count = rod.toY.toInt();
                      final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
                      return BarTooltipItem(
                        '${emotion.displayName}\n$count ($pct%)',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.textH(context).withValues(alpha: 0.08),
                    strokeWidth: 0.6,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        if (v == v.roundToDouble()) {
                          return Text(
                            v.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: AppTheme.textH(context).withValues(alpha: 0.6),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= EmotionType.values.length) {
                          return const SizedBox.shrink();
                        }
                        final emotion = EmotionType.values[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            emotion.emoji,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(EmotionType.values.length, (i) {
                  final emotion = EmotionType.values[i];
                  final count = emotionCounts[emotion] ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: emotion.color,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _maxCount().toDouble() * 1.3,
                          color: emotion.color.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _maxCount() {
    if (emotionCounts.isEmpty) return 1;
    return emotionCounts.values.reduce((a, b) => a > b ? a : b);
  }
}

class MentalHealthStatusCard extends StatelessWidget {
  final List<({String label, Color color, int count})> categories;
  final int scored;

  const MentalHealthStatusCard({
    super.key,
    required this.categories,
    required this.scored,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: List.generate(categories.length, (i) {
          final c = categories[i];
          final pct = scored > 0 ? c.count / scored * 100 : 0.0;
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    ),
                    Text(
                      '${c.count} · ${pct.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: scored > 0 ? c.count / scored : 0,
                    minHeight: 6,
                    backgroundColor: c.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(c.color),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
