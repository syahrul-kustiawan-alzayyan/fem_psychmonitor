import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/emotion_model.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../theme/resonance_colors.dart';
import '../widgets/painters.dart';
import '../widgets/suggestion_card.dart';

class ResultScreen extends StatefulWidget {
  final RecordingData recordingData;

  const ResultScreen({super.key, required this.recordingData});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  SuggestionResult? _suggestionResult;
  String _title = '';
  bool _loaded = false;
  String _selectedTrigger = '';
  bool _transcriptExpanded = false;

  Map<EmotionType, double> get _combinedScores {
    return GeminiService.combineResults(
      widget.recordingData.audioEmotions,
      widget.recordingData.transcriptEmotions,
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
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await DatabaseService.getUser();
    final service = SuggestionService();
    await service.load();

    final bigFiveScores = user?.bigFiveScores ?? {};
    final combined = _combinedScores;
    final dominant = combined.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final result = service.getStructuredSuggestions(bigFiveScores, dominant);
    final title = service.buildTitle(bigFiveScores, dominant);

    if (mounted) {
      setState(() {
        _suggestionResult = result;
        _title = title;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);
    final combined = _combinedScores;
    final sorted = _sortedScores;
    final domEntry = sorted.entries.first;
    final domEmotion = domEntry.key;
    final domConf = domEntry.value;

    return Scaffold(
      backgroundColor: c.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIconsRegular.chartBar,
                color: c.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.tr('detection_result'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        leading: const SizedBox.shrink(),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(context, domEmotion, domConf),
                    const SizedBox(height: 16),
                    _buildInsightRow(context, combined),
                    const SizedBox(height: 20),
                    _buildScoreBreakdown(context, sorted),
                    const SizedBox(height: 20),
                    _buildRadarChartCard(context, combined),
                    const SizedBox(height: 20),
                    _buildTranscriptCard(context),
                    const SizedBox(height: 20),
                    _buildSourceComparison(context),
                    const SizedBox(height: 20),
                    _buildScoreTrend(context, combined),
                    const SizedBox(height: 20),
                    if (_loaded && _suggestionResult != null)
                      SuggestionCard(
                        title: _title,
                        traitSuggestions: _suggestionResult!.traitSuggestions,
                        color: domEmotion.color,
                        isCollapsible: false,
                      )
                    else if (_loaded && _suggestionResult == null)
                      const SizedBox.shrink()
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildTriggerCard(context),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildDoneBar(context),
          ),
        ],
      ),
    );
  }

  /// ── HERO ──────────────────────────────────────────────────────────
  /// Kartu emosi dominan dengan watermark persentase raksasa, dekorasi
  /// lingkaran translusen, dan confidence ring mengelilingi ikon.
  Widget _buildHeroCard(
    BuildContext context,
    EmotionType emotion,
    double confidence,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pctText = '${(confidence * 100).toStringAsFixed(0)}%';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            emotion.color.withValues(alpha: 0.85),
            emotion.color,
            emotion.color.withValues(
              blue: (emotion.color.b + 0.12).clamp(0.0, 1.0),
            ),
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
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Dekorasi lingkaran translusen
            Positioned(
              top: -38,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -48,
              left: -26,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Watermark persentase raksasa
            Positioned(
              right: 12,
              bottom: -16,
              child: Text(
                pctText,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 74,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -4,
                  color: Colors.white.withValues(alpha: 0.12),
                  height: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.tr('dominant_emotion').toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          emotion.displayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.8,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _confidenceBadge(confidence),
                            const SizedBox(width: 8),
                            _infoChip(
                              Icons.access_time_rounded,
                              '${widget.recordingData.durationSeconds}s',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConfidenceRing(
                    progress: confidence,
                    size: 96,
                    strokeWidth: 5,
                    color: Colors.white,
                    trackColor: Colors.white.withValues(alpha: 0.22),
                    child: Image.asset(
                      emotion.assetIconPath,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(emotion.icon, size: 42, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          Icon(
            Icons.auto_awesome,
            size: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 5),
          Text(
            '${(confidence * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
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
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context,
    Map<EmotionType, double> combined,
  ) {
    final top3 = combined.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hasTranscript = widget.recordingData.transcriptText.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          _insightTile(
            Icons.emoji_emotions_outlined,
            AppLocalizations.tr('top_emotions'),
            top3
                .take(2)
                .map(
                  (e) =>
                      '${e.key.displayName} (${(e.value * 100).toStringAsFixed(0)}%)',
                )
                .join(', '),
            AppTheme.primaryColor,
          ),
          Container(width: 1, height: 36, color: AppTheme.surfVar(context)),
          _insightTile(
            Icons.text_fields_rounded,
            AppLocalizations.tr('transcript_label'),
            hasTranscript
                ? AppLocalizations.tr('available')
                : AppLocalizations.tr('none'),
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

  /// Judul seksi konsisten — ikon kotak + judul Space Grotesk.
  Widget _sectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool accent = false,
    Color? tint,
    Widget? trailing,
  }) {
    final tintColor = tint ?? AppTheme.iconColor(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: accent ? AppTheme.primaryGradient : null,
            color: accent ? null : tintColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 16,
            color: accent ? Colors.white : tintColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  /// ── RINCIAN SKOR ─────────────────────────────────────────────────
  /// Strip komposisi bertumpuk (proporsi sekilas) + daftar peringkat
  /// ringkas dengan angka mono — menggantikan deretan progress bar generik.
  Widget _buildScoreBreakdown(
    BuildContext context,
    Map<EmotionType, double> sorted,
  ) {
    final total = sorted.values.fold<double>(0, (a, b) => a + b);
    final top4 = sorted.entries.take(4).toList();
    final restTotal =
        sorted.values.skip(4).fold<double>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.bar_chart_rounded,
            title: AppLocalizations.tr('emotion_score'),
            accent: true,
          ),
          const SizedBox(height: 16),

          // Strip komposisi bertumpuk
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: [
                    for (final entry in sorted.entries)
                      Expanded(
                        flex:
                            ((entry.value / total) * 1000).round().clamp(1, 999),
                        child: ColoredBox(color: entry.key.color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Legenda strip
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final entry in top4)
                  _legendItem(entry.key, entry.value),
                if (restTotal > 0.005)
                  _legendItem(null, restTotal / total),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Daftar peringkat
          ...sorted.entries.toList().asMap().entries.map((ranked) {
            final rank = ranked.key + 1;
            final e = ranked.value.key;
            final val = ranked.value.value;
            final isDominant = rank == 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$rank'.padLeft(2, '0'),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isDominant ? e.color : AppTheme.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(e.assetIconPath, width: 17, height: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            e.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isDominant
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDominant
                                  ? e.color
                                  : AppTheme.textP(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDominant) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
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
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(val * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDominant ? e.color : AppTheme.textS(context),
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

  Widget _legendItem(EmotionType? emotion, double share) {
    final isEn = AppLocalizations.locale.startsWith('en');
    final color = emotion?.color ?? AppTheme.textHint;
    final label =
        emotion?.displayName ?? (isEn ? 'Others' : 'Lainnya');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          emotion != null ? emotion.displayName : label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textS(context),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(share * 100).toStringAsFixed(0)}%',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textS(context),
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChartCard(
    BuildContext context,
    Map<EmotionType, double> combined,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          _sectionTitle(
            context,
            icon: Icons.radar_rounded,
            title: AppLocalizations.tr('detail_emotion_distribution'),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 240, child: _buildRadarChart(combined)),
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

  /// ── TRANSKRIP ────────────────────────────────────────────────────
  /// Gaya kutipan: tanda petik besar + teks miring, bisa diciutkan
  /// jika panjang agar halaman tetap ramping.
  Widget _buildTranscriptCard(BuildContext context) {
    final c = ResonanceColors.of(context);
    final isEn = AppLocalizations.locale.startsWith('en');
    final hasTranscript = widget.recordingData.transcriptText.isNotEmpty;
    final hasTextEmotions = widget.recordingData.transcriptEmotions.values.any(
      (v) => v > 0.05,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow(context),
        border: Border.all(
          color: hasTranscript
              ? c.primary.withValues(alpha: 0.10)
              : Colors.orange.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: hasTranscript
                ? Icons.text_fields_rounded
                : Icons.warning_amber_rounded,
            title: AppLocalizations.tr('transcript_label'),
            accent: hasTranscript,
            tint: hasTranscript ? null : Colors.orange,
            trailing: Container(
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
                    hasTranscript
                        ? Icons.check_circle
                        : Icons.hourglass_empty_rounded,
                    size: 12,
                    color: hasTranscript
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasTranscript
                        ? AppLocalizations.tr('detected')
                        : AppLocalizations.tr('none'),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: hasTranscript
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (hasTranscript) ...[
            _quoteBlock(
              context,
              widget.recordingData.transcriptText,
              isEn,
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mic_off_rounded,
                    size: 32,
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
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
                    AppLocalizations.tr('transcript_unavailable_desc'),
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
              children: widget.recordingData.transcriptEmotions.entries
                  .where((e) => (e.value) > 0.05)
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: e.key.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            e.key.assetIconPath,
                            width: 11,
                            height: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${e.key.displayName}: ${(e.value * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: e.key.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quoteBlock(BuildContext context, String text, bool isEn) {
    const collapseAt = 280;
    final isLong = text.length > collapseAt;
    final shown =
        (isLong && !_transcriptExpanded) ? text.substring(0, collapseAt) : text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.surfVar(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -4,
            top: -10,
            child: Text(
              '"',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 58,
                fontWeight: FontWeight.w800,
                height: 1,
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shown,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.65,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textP(context),
                  ),
                ),
                if (isLong && !_transcriptExpanded) const Text('…'),
                if (isLong) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _transcriptExpanded = !_transcriptExpanded),
                    child: Text(
                      _transcriptExpanded
                          ? (isEn ? 'Show less' : 'Tutup')
                          : (isEn ? 'Read more' : 'Baca selengkapnya'),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ── SUMBER DETEKSI ───────────────────────────────────────────────
  /// Bar fusi bobot 60/40 + ringkasan dominan per sumber dalam dua
  /// baris ringkas — bukan dua kartu mini generik berdampingan.
  Widget _buildSourceComparison(BuildContext context) {
    final audio = widget.recordingData.audioEmotions;
    final text = widget.recordingData.transcriptEmotions;
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
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.compare_arrows_rounded,
            title: AppLocalizations.tr('detection_source'),
          ),
          const SizedBox(height: 16),

          // Bar fusi bobot
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mic_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(width: 3, height: 24, color: AppTheme.surface(context)),
              Expanded(
                flex: 4,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade300],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.text_fields_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppLocalizations.tr('voice_source').toUpperCase()} · 60%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                '${AppLocalizations.tr('text_source').toUpperCase()} · 40%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _sourceSummaryRow(
            context,
            icon: Icons.mic_rounded,
            label: AppLocalizations.tr('voice_source'),
            weightLabel: '60%',
            color: AppTheme.primaryColor,
            emotion: audioDominant.first.key,
            score: audioDominant.first.value,
          ),
          const SizedBox(height: 8),
          _sourceSummaryRow(
            context,
            icon: Icons.text_fields_rounded,
            label: AppLocalizations.tr('text_source'),
            weightLabel: '40%',
            color: Colors.green.shade600,
            emotion:
                hasTextData ? textDominant.first.key : EmotionType.neutral,
            score: hasTextData ? textDominant.first.value : 0,
            disabled: !hasTextData,
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
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppTheme.iconColor(context),
                ),
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

  Widget _sourceSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String weightLabel,
    required Color color,
    required EmotionType emotion,
    required double score,
    bool disabled = false,
  }) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfVar(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: disabled ? 0.06 : 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color.withValues(alpha: disabled ? 0.4 : 1.0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                Text(
                  'bobot $weightLabel',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (!disabled) ...[
            Image.asset(emotion.assetIconPath, width: 20, height: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  emotion.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: emotion.color,
                  ),
                ),
                Text(
                  '${(score * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textS(context),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              AppLocalizations.tr('not_available'),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textHint,
              ),
            ),
        ],
      ),
    );
    return Opacity(opacity: disabled ? 0.55 : 1.0, child: body);
  }

  /// ── TREN SKOR ────────────────────────────────────────────────────
  /// Blok kalkulasi bergaya struk/nota: garis putus-putus sebagai
  /// penghubung label↔nilai, angka mono — terasa "dihitung sungguhan".
  Widget _buildScoreTrend(
    BuildContext context,
    Map<EmotionType, double> combined,
  ) {
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
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.trending_up_rounded,
            title: AppLocalizations.tr('score_trend_title'),
            accent: true,
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
                errorBuilder: (_, _, _) =>
                    Icon(emotion.icon, size: 32, color: emotion.color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              emotion.displayName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: emotion.color,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
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
                _receiptRow(
                  context,
                  AppLocalizations.tr('base_value'),
                  baseVal > 0 ? '+$baseVal' : '$baseVal',
                  AppTheme.textP(context),
                ),
                const SizedBox(height: 10),
                _receiptRow(
                  context,
                  AppLocalizations.tr('final_confidence'),
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  AppTheme.textP(context),
                ),
                const SizedBox(height: 10),
                DashedLine(
                  color: AppTheme.textH(context).withValues(alpha: 0.3),
                ),
                const SizedBox(height: 10),
                _receiptRow(
                  context,
                  AppLocalizations.tr('emotion_score_result'),
                  '${score > 0 ? "+" : ""}${score.toStringAsFixed(2)}',
                  isPositive ? Colors.green.shade600 : Colors.red.shade600,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: AppTheme.textHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppLocalizations.tr('score_trend_desc'),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.textS(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Satu baris struk: label ……… nilai
  Widget _receiptRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textS(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DashedLine(
            color: AppTheme.textH(context).withValues(alpha: 0.22),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: bold ? 16 : 13,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerCard(BuildContext context) {
    final tags = TriggerTag.values;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.push_pin_rounded,
            title: AppLocalizations.tr('trigger_title'),
            accent: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _selectedTrigger.isEmpty
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _selectedTrigger.isEmpty ? 'WAJIB' : 'OK',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _selectedTrigger.isEmpty
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = _selectedTrigger == tag.name;
              return GestureDetector(
                onTap: () => setState(() => _selectedTrigger = tag.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.12)
                        : AppTheme.surfVar(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.4)
                          : AppTheme.textH(context).withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag.emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textP(context),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ── BAR SELESAI (menempel di bawah, aman dari gesture bar) ────────
  Widget _buildDoneBar(BuildContext context) {
    final c = ResonanceColors.of(context);
    final canProceed = _selectedTrigger.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColorStrong,
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: canProceed
              ? () {
                  DatabaseService.updateRecordingTrigger(
                    widget.recordingData.id ?? 0,
                    _selectedTrigger,
                  );
                  Navigator.pop(context);
                }
              : null,
          icon: Icon(
            canProceed ? Icons.check_rounded : Icons.lock_rounded,
            size: 20,
          ),
          label: Text(
            canProceed
                ? AppLocalizations.tr('done')
                : AppLocalizations.tr('trigger_title'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canProceed ? AppTheme.primaryColor : c.surfaceVariant,
            foregroundColor:
                canProceed ? Colors.white : AppTheme.textS(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: canProceed ? 6 : 0,
            shadowColor:
                canProceed ? c.shadowColorStrong : Colors.transparent,
          ),
        ),
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
        tickBorderData: BorderSide(
          color: AppTheme.surfVar(context),
          width: 0.5,
        ),
        gridBorderData: BorderSide(
          color: AppTheme.surfVar(context),
          width: 0.8,
        ),
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
}
