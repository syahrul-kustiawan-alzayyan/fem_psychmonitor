import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/suggestion_card.dart';

class RecordDetailScreen extends StatefulWidget {
  final EmotionRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  RecordingData? _recordingData;
  List<String> _suggestions = [];
  String _title = '';
  bool _loaded = false;

  Map<EmotionType, double> get _combinedScores {
    final data = _recordingData;
    if (data == null) {
      return {for (final e in EmotionType.values) e: 1.0 / EmotionType.values.length};
    }
    return GeminiService.combineResults(
      data.audioEmotions,
      data.transcriptEmotions,
      audioWeight: 0.6,
      textWeight: 0.4,
    );
  }

  Map<EmotionType, double> get _sortedScores {
    final sorted = _combinedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

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
    final combined = _combinedScores;
    final dominant = combined.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    ).key;

    List<String> suggestions;
    String title;

    if (mbtiType.isNotEmpty && mbtiType != 'XXXX') {
      suggestions = service.getSuggestions(mbtiType, dominant);
      title = service.buildTitle(mbtiType, dominant);
    } else {
      suggestions = dominant.recordingSuggestions;
      title = AppLocalizations.tr('suggestion_for_emotion_name').replaceFirst('{emotion}', dominant.displayName);
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
    final combined = _combinedScores;
    final sorted = _sortedScores;
    final domEntry = sorted.entries.first;
    final domEmotion = domEntry.key;
    final domConf = domEntry.value;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(Icons.article_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(
                AppLocalizations.tr('detail_title'),
                style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(domEmotion, domConf),
                const SizedBox(height: 16),
                _buildInsightRow(combined),
                const SizedBox(height: 20),
                _buildScoreBreakdown(sorted),
                const SizedBox(height: 20),
                _buildRadarChartCard(combined),
                const SizedBox(height: 20),
                _buildTranscriptCard(),
                const SizedBox(height: 20),
                _buildSourceComparison(),
                const SizedBox(height: 20),
                if (_recordingData != null)
                  _buildScoreTrend(combined),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                _buildTriggerCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Card ──

  Widget _buildHeroCard(EmotionType emotion, double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            emotion.color.withValues(alpha: 0.85),
            emotion.color,
            emotion.color.withValues(blue: (emotion.color.b + 0.12).clamp(0.0, 1.0)),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: emotion.color.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr('dominant_emotion'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emotion.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _confidenceBadge(confidence),
                    const SizedBox(width: 8),
                    _infoChip(
                      Icons.access_time_rounded,
                      '${_recordingData?.durationSeconds ?? widget.record.confidence}s',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              emotion.assetIconPath,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => Icon(
                emotion.icon,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceBadge(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            '${(confidence * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Insight Row ──

  Widget _buildInsightRow(Map<EmotionType, double> combined) {
    final top3 = combined.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hasTranscript = _recordingData?.transcriptText.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          _insightTile(
            Icons.emoji_emotions_outlined,
            AppLocalizations.tr('top_emotions'),
            top3.take(2).map((e) => '${e.key.displayName} (${(e.value * 100).toStringAsFixed(0)}%)').join(', '),
            AppTheme.primaryColor,
          ),
          Container(
            width: 1,
            height: 36,
            color: AppTheme.surfVar(context),
          ),
          _insightTile(
            Icons.text_fields_rounded,
            AppLocalizations.tr('transcript_label'),
            hasTranscript ? AppLocalizations.tr('available') : AppLocalizations.tr('none'),
            hasTranscript ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _insightTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textS(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textP(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Score Breakdown ──

  Widget _buildScoreBreakdown(Map<EmotionType, double> sorted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.tr('emotion_score'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...sorted.entries.map((entry) {
            final e = entry.key;
            final val = entry.value;
            final isDominant = identical(e, sorted.entries.first.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(e.assetIconPath, width: 16, height: 16),
                      const SizedBox(width: 8),
                      Text(
                        e.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isDominant ? FontWeight.w700 : FontWeight.w500,
                          color: isDominant ? e.color : AppTheme.textP(context),
                        ),
                      ),
                      if (isDominant)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: e.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.tr('dominant_badge'),
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: e.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${(val * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: e.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: 1.0,
                          backgroundColor: AppTheme.surfVar(context),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.surfVar(context)),
                          minHeight: isDominant ? 10 : 8,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: val,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(e.color),
                          minHeight: isDominant ? 10 : 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Radar Chart ──

  Widget _buildRadarChartCard(Map<EmotionType, double> combined) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.iconColor(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.radar_rounded, color: AppTheme.iconColor(context), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.tr('detail_emotion_distribution'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: _buildRadarChart(combined),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr('combined_source_desc'),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.textHint,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<EmotionType, double> combined) {
    final emotions = EmotionType.values;
    final dominant = _sortedScores.entries.first.key;
    final entries = emotions.map((e) {
      return RadarEntry(value: (combined[e] ?? 0) * 100);
    }).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: dominant.color.withValues(alpha: 0.15),
            borderColor: dominant.color,
            borderWidth: 2.5,
            entryRadius: 4,
            dataEntries: entries,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.transparent),
        tickCount: 4,
        ticksTextStyle: GoogleFonts.poppins(
          fontSize: 9,
          color: AppTheme.textHint,
        ),
        tickBorderData: BorderSide(color: AppTheme.surfVar(context), width: 0.5),
        gridBorderData: BorderSide(color: AppTheme.surfVar(context), width: 0.8),
        titlePositionPercentageOffset: 0.18,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.textS(context),
        ),
        getTitle: (index, angle) {
          final e = emotions[index];
          final isDom = identical(e, dominant);
          return RadarChartTitle(
            text: isDom ? '★ ${e.displayName}' : e.displayName,
          );
        },
      ),
      duration: const Duration(milliseconds: 600),
    );
  }

  // ── Transcript Card ──

  Widget _buildTranscriptCard() {
    final data = _recordingData;
    final hasTranscript = data != null && data.transcriptText.isNotEmpty;
    final hasTextEmotions = data != null && data.transcriptEmotions.values.any((v) => v > 0.05);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: hasTranscript
              ? AppTheme.primaryColor.withValues(alpha: 0.10)
              : Colors.orange.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: hasTranscript ? AppTheme.primaryGradient : const LinearGradient(
                    colors: [Colors.orange, Colors.orangeAccent],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  hasTranscript ? Icons.text_fields_rounded : Icons.warning_amber_rounded,
                  color: Colors.white, size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.tr('transcript_label'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasTranscript
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasTranscript ? Icons.check_circle : Icons.hourglass_empty_rounded,
                      size: 12,
                      color: hasTranscript ? Colors.green.shade600 : Colors.orange.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasTranscript ? AppLocalizations.tr('detected') : AppLocalizations.tr('none'),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: hasTranscript ? Colors.green.shade600 : Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasTranscript) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfVar(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                data.transcriptText,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.6,
                  color: AppTheme.textP(context),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Icon(Icons.mic_off_rounded, size: 32, color: Colors.orange.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.tr('transcript_unavailable'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.tr('transcript_not_recorded'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textS(context),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          if (hasTextEmotions) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.tr('text_emotions_label'),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textS(context),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: data.transcriptEmotions.entries
                .where((e) => (e.value) > 0.05)
                .map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: e.key.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(e.key.assetIconPath, width: 11, height: 11),
                      const SizedBox(width: 4),
                      Text(
                        '${e.key.displayName}: ${(e.value * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: e.key.color,
                        ),
                      ),
                    ],
                  ),
                ))
                .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Source Comparison ──

  Widget _buildSourceComparison() {
    final data = _recordingData;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final audio = data.audioEmotions;
    final text = data.transcriptEmotions;
    final hasTextData = text.values.any((v) => v > 0);

    final audioDominant = audio.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final textDominant = text.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.iconColor(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.compare_arrows_rounded, color: AppTheme.iconColor(context), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.tr('detection_source'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _sourceCard(
                  AppLocalizations.tr('voice_source'),
                  60,
                  Icons.mic_rounded,
                  AppTheme.primaryColor,
                  audioDominant.first.key,
                  audioDominant.first.value,
                  audioDominant.length > 1 ? audioDominant[1].key : null,
                  audioDominant.length > 1 ? audioDominant[1].value : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sourceCard(
                  AppLocalizations.tr('text_source'),
                  40,
                  Icons.text_fields_rounded,
                  Colors.green.shade600,
                  hasTextData ? textDominant.first.key : EmotionType.neutral,
                  hasTextData ? textDominant.first.value : 0,
                  hasTextData && textDominant.length > 1 ? textDominant[1].key : null,
                  hasTextData && textDominant.length > 1 ? textDominant[1].value : null,
                  disabled: !hasTextData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  Colors.green.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.iconColor(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('combined_source_info'),
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      height: 1.4,
                      color: AppTheme.textS(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTrend(Map<EmotionType, double> combined) {
    final sorted = combined.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dom = sorted.first;
    final emotion = dom.key;
    final confidence = dom.value;
    final baseVal = emotion.emotionValue;
    final score = emotion.emotionValue * confidence;
    final isPositive = score >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.tr('score_trend_title'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: emotion.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                emotion.assetIconPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  emotion.icon, size: 32, color: emotion.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              emotion.displayName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: emotion.color,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.textHint),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.tr('score_trend_desc'),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfVar(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPositive
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                _calcRow(
                  AppLocalizations.tr('base_value'),
                  baseVal > 0 ? '+$baseVal' : '$baseVal',
                  AppTheme.textP(context),
                ),
                const SizedBox(height: 8),
                _calcRow(
                  AppLocalizations.tr('final_confidence'),
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  AppTheme.textP(context),
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: AppTheme.textH(context).withValues(alpha: 0.1)),
                const SizedBox(height: 8),
                _calcRow(
                  AppLocalizations.tr('emotion_score_result'),
                  '${score > 0 ? "+" : ""}${score.toStringAsFixed(2)}',
                  isPositive ? Colors.green.shade600 : Colors.red.shade600,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textS(context),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerCard() {
    final data = _recordingData;
    final tag = data?.triggerTag ?? '';
    if (tag.isEmpty) return const SizedBox.shrink();

    final tagEnum = TriggerTag.values.where((t) => t.name == tag).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.push_pin_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.tr('trigger_title'),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const Spacer(),
          if (tagEnum != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tagEnum.emoji}  ${tagEnum.displayName}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sourceCard(
    String label,
    int weight,
    IconData icon,
    Color color,
    EmotionType dominantEmotion,
    double dominantScore,
    EmotionType? secondEmotion,
    double? secondScore, {
    bool disabled = false,
  }) {
    final opacity = disabled ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfVar(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: disabled ? 0.08 : 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: disabled ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color.withValues(alpha: disabled ? 0.4 : 1.0)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
              ),
            ),
            Text(
              '($weight%)',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textS(context),
              ),
            ),
            const SizedBox(height: 10),
            if (!disabled) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dominantEmotion.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(dominantEmotion.assetIconPath, width: 20, height: 20),
              ),
              const SizedBox(height: 4),
              Text(
                dominantEmotion.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dominantEmotion.color,
                ),
              ),
              Text(
                '${(dominantScore * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textS(context),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  AppLocalizations.tr('not_available'),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
