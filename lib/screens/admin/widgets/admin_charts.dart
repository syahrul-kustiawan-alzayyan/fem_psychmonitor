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

class PsychScoreLegend extends StatelessWidget {
  const PsychScoreLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (const Color(0xFF10B981), '76-100', 'Sehat Optimal'),
      (const Color(0xFFF59E0B), '51-75', 'Cukup'),
      (const Color(0xFFF97316), '26-50', 'Rentan'),
      (const Color(0xFFEF4444), '0-25', 'Butuh Perhatian'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.$1,
                  borderRadius: BorderRadius.circular(2),
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
                      fontSize: 8,
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
}
