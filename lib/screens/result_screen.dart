import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/emotion_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/emotion_badge.dart';
import '../widgets/suggestion_card.dart';
import '../l10n/app_localizations.dart';

class ResultScreen extends StatelessWidget {
  final RecordingData recordingData;

  const ResultScreen({Key? key, required this.recordingData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final domEmotion = recordingData.dominantEmotion;
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text(
          'Hasil Deteksi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppTheme.textP(context),
          ),
        ),
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppTheme.textP(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dominant Emotion Hero Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    domEmotion.color.withValues(alpha: 0.8),
                    domEmotion.color,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: domEmotion.color.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      domEmotion.icon,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Emosi Dominan',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    domEmotion.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Akurasi: ${(recordingData.confidence * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Radar Chart Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: AppTheme.surfVar(context), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.radar_rounded, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Distribusi Emosi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 240,
                    child: _buildRadarChart(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Suggestion Card
            SuggestionCard(
              title: AppLocalizations.tr('psych_recommendation'),
              suggestions: domEmotion.recordingSuggestions,
              icon: Icons.lightbulb_outline_rounded,
              color: domEmotion.color,
              isCollapsible: false,
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChart(BuildContext context) {
    final emotions = EmotionType.values;

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderColor: AppTheme.primaryColor,
            entryRadius: 4,
            dataEntries: emotions.map((e) {
              return RadarEntry(value: recordingData.audioEmotions[e] ?? 0.0);
            }).toList(),
            borderWidth: 2.5,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.transparent),
        tickCount: 3,
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
        tickBorderData: BorderSide(color: AppTheme.surfVar(context), width: 1),
        gridBorderData: BorderSide(color: AppTheme.surfVar(context), width: 1.5),
        getTitle: (index, angle) {
          final emotion = emotions[index];
          return RadarChartTitle(
            text: emotion.displayName,
            angle: 0,
            positionPercentageOffset: 0.15,
          );
        },
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
    );
  }
}

