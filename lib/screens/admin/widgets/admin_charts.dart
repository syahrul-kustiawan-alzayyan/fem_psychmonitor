import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../models/emotion_model.dart';
import '../../../theme/resonance_colors.dart';

/// Aksen rose yang dapat dibaca di atas permukaan terang/gelap.
Color resonanceAccent(ResonanceColors c) =>
    c.primary == ResonanceColors.light.primary
        ? const Color(0xFFA05A6B)
        : c.primary;

class EmotionDistributionBarChart extends StatelessWidget {
  final Map<EmotionType, int> emotionCounts;

  const EmotionDistributionBarChart({
    super.key,
    required this.emotionCounts,
  });

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);
    final total = emotionCounts.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return ResonanceCard(
        c: c,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsRegular.chartBar,
                size: 24,
                color: resonanceAccent(c),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada data emosi',
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

    return SizedBox(
      height: 230,
      child: ResonanceCard(
        c: c,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Text(
                'DISTRIBUSI EMOSI',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: resonanceAccent(c),
                ),
              ),
              const Spacer(),
              Text(
                '$total total',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxCount().toDouble() * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => resonanceAccent(c),
                    getTooltipItem: (group, groupIdx, rod, rodIdx) {
                      final emotion = EmotionType.values[group.x];
                      final count = rod.toY.toInt();
                      final pct =
                          total > 0
                          ? (count / total * 100).toStringAsFixed(0)
                          : '0';
                      return BarTooltipItem(
                        '${emotion.displayName}\n$count ($pct%)',
                        GoogleFonts.inter(
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
                    color: c.outlineVariant.withValues(alpha: 0.6),
                    strokeWidth: 0.6,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, _) {
                        if (v == v.roundToDouble()) {
                          return Text(
                            v.toInt().toString(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: c.onSurfaceVariant.withValues(alpha: 0.7),
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
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _maxCount().toDouble() * 1.25,
                          color: emotion.color.withValues(alpha: 0.07),
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
    final c = ResonanceColors.of(context);
    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: List.generate(categories.length, (i) {
          final item = categories[i];
          final pct = scored > 0 ? item.count / scored * 100 : 0.0;
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: c.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${item.count} · ${pct.toStringAsFixed(0)}%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ResonanceProgressBar(
                  c: c,
                  progress: scored > 0 ? item.count / scored : 0,
                  color: item.color,
                  height: 6,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}