import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../services/database_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class RecordDetailScreen extends StatefulWidget {
  final EmotionRecord record;

  const RecordDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  RecordingData? _recordingData;
  List<String> _suggestions = [];
  bool _suggestionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRecordingData();
    _loadSuggestions();
  }

  Future<void> _loadRecordingData() async {
    final id = widget.record.recordingId;
    if (id == null) return;
    final data = await DatabaseService.getRecording(id);
    if (mounted) {
      setState(() => _recordingData = data);
    }
  }

  Future<void> _loadSuggestions() async {
    final user = await DatabaseService.getUser();
    final service = SuggestionService();
    await service.load();

    final mbtiType = user?.mbtiType ?? '';
    final emotion = widget.record.emotion;

    List<String> suggestions;
    if (mbtiType.isNotEmpty && mbtiType != 'XXXX') {
      suggestions = service.getSuggestions(mbtiType, emotion);
    } else {
      suggestions = emotion.recordingSuggestions;
    }

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _suggestionsLoaded = true;
      });
    }
  }

  EmotionRecord get _record => widget.record;

  @override
  Widget build(BuildContext context) {
    final emotion = _record.emotion;
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
                Icons.article_rounded,
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
                AppLocalizations.tr('detail_title'),
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
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, emotion),
            const SizedBox(height: 24),
            _buildInfoSection(context, emotion),
            const SizedBox(height: 24),
            if (_recordingData != null) ...[
              _buildRadarChartSection(context),
              const SizedBox(height: 24),
            ],
            _buildEmotionScaleSection(context, emotion),
            const SizedBox(height: 24),
            _buildSuggestionsSection(context, emotion),
          ],
        ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EmotionType emotion) {
    return Row(
      children: [
        Image.asset(
          emotion.assetIconPath,
          width: 76,
          height: 76,
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
                  _buildTag(_record.confidencePercent, emotion.color),
                  const SizedBox(width: 8),
                  _buildTag(
                    'Skor: ${_record.emotionScoreLabel}',
                    _record.emotionScore >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, EmotionType emotion) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.access_time_rounded,
          AppLocalizations.tr('detail_detection_time'),
          _record.formattedTime,
          context,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.trending_up_rounded,
          AppLocalizations.tr('detail_emotion_value'),
          '${emotion.valueLabel} ${AppLocalizations.tr('detail_scale_5')}',
          context,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.speed_rounded,
          AppLocalizations.tr('detail_confidence'),
          '${(_record.confidence * 100).toStringAsFixed(1)}%',
          context,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.calculate_rounded,
          AppLocalizations.tr('detail_weighted_score'),
          '${emotion.valueLabel} × ${_record.confidencePercent} = ${_record.emotionScoreLabel}',
          context,
        ),
      ],
    );
  }

  Widget _buildRadarChartSection(BuildContext context) {
    final emotions = EmotionType.values;
    return Container(
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
                child: const Icon(
                  Icons.radar_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.tr('detail_emotion_distribution'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                      ),
                    ),
                    Text(
                      AppLocalizations.tr('detail_radar_desc'),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textH(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderColor: AppTheme.primaryColor,
                    entryRadius: 4,
                    dataEntries: emotions.map((e) {
                      return RadarEntry(
                        value: _recordingData?.audioEmotions[e] ?? 0.0,
                      );
                    }).toList(),
                    borderWidth: 2.5,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                tickCount: 3,
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent, fontSize: 10),
                tickBorderData:
                    BorderSide(color: AppTheme.surfVar(context), width: 1),
                gridBorderData:
                    BorderSide(color: AppTheme.surfVar(context), width: 1.5),
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
            ),
          ),
          const SizedBox(height: 16),
          ...emotions.map((e) {
            final value = _recordingData?.audioEmotions[e] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Image.asset(e.assetIconPath, width: 40, height: 40),
                  const SizedBox(width: 8),
                  Text(
                    e.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(value * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: e == _record.emotion
                          ? e.color
                          : AppTheme.textS(context),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmotionScaleSection(BuildContext context, EmotionType emotion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.tr('detail_emotion_scale'),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textP(context),
          ),
        ),
        const SizedBox(height: 12),
        ...EmotionType.values.map(
          (e) => _buildEmotionRow(context, e, e == emotion),
        ),
      ],
    );
  }

  Widget _buildSuggestionsSection(
    BuildContext context,
    EmotionType emotion,
  ) {
    if (!_suggestionsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final title = _suggestions.isNotEmpty
        ? AppLocalizations.tr('detail_suggestion_mbti')
        : AppLocalizations.tr('detail_suggestion_emotion');
    final items = _suggestions.isNotEmpty
        ? _suggestions
        : emotion.recordingSuggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textP(context),
          ),
        ),
        const SizedBox(height: 12),
        ...items.take(5).map(
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.iconColor(context)),
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

  Widget _buildEmotionRow(
    BuildContext context,
    EmotionType e,
    bool isActive,
  ) {
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
          Image.asset(e.assetIconPath, width: 48, height: 48),
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
