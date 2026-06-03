import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/emotion_model.dart';
import '../services/database_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/suggestion_card.dart';

class ResultScreen extends StatefulWidget {
  final RecordingData recordingData;

  const ResultScreen({Key? key, required this.recordingData}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<String> _suggestions = [];
  String _title = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await DatabaseService.getUser();
    final service = SuggestionService();
    await service.load();

    final mbtiType = user?.mbtiType ?? '';
    final emotion = widget.recordingData.dominantEmotion;

    List<String> suggestions;
    String title;

    if (mbtiType.isNotEmpty && mbtiType != 'XXXX') {
      suggestions = service.getSuggestions(mbtiType, emotion);
      title = service.buildTitle(mbtiType, emotion);
    } else {
      suggestions = emotion.recordingSuggestions;
      title = 'Saran untuk Emosi ${emotion.displayName}';
    }

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _title = title;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final domEmotion = widget.recordingData.dominantEmotion;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.analytics_rounded,
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
                'Hasil Deteksi',
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
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
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
                    child: Image.asset(
                      domEmotion.assetIconPath,
                      width: 68,
                      height: 68,
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
                          'Akurasi: ${(widget.recordingData.confidence * 100).toStringAsFixed(1)}%',
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
                          color: AppTheme.iconColor(context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.radar_rounded, color: AppTheme.iconColor(context), size: 20),
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

            // Suggestion Card — dynamic dari saran.json
            if (_loaded)
              SuggestionCard(
                title: _title,
                suggestions: _suggestions,
                icon: Icons.lightbulb_outline_rounded,
                color: domEmotion.color,
                isCollapsible: false,
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            
            const SizedBox(height: 48),
          ],
        ),
        ),
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
              return RadarEntry(value: widget.recordingData.audioEmotions[e] ?? 0.0);
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

