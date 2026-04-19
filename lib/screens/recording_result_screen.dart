import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/emotion_badge.dart';
import '../widgets/gradient_background.dart';
import '../widgets/suggestion_card.dart';

class RecordingResultScreen extends StatefulWidget {
  final EmotionType detectedEmotion;
  final double confidence;
  final Map<EmotionType, double> scores;

  const RecordingResultScreen({
    super.key,
    required this.detectedEmotion,
    required this.confidence,
    required this.scores,
  });

  @override
  State<RecordingResultScreen> createState() => _RecordingResultScreenState();
}

class _RecordingResultScreenState extends State<RecordingResultScreen> {
  AppUser? _user;
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
    final emotion = widget.detectedEmotion;

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
        _user = user;
        _suggestions = suggestions;
        _title = title;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.tr('detection_result')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmotionResultCard(
                  emotion: widget.detectedEmotion,
                  confidence: widget.confidence,
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // Suggestion Card — dynamic dari saran.json
                if (_loaded)
                  _buildSuggestionSection()
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                const SizedBox(height: AppTheme.space2xl),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Rekam Ulang'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionSection() {
    final hasMbti = _user != null &&
        _user!.mbtiType.isNotEmpty &&
        _user!.mbtiType != 'XXXX';

    if (hasMbti) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: widget.detectedEmotion.color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.detectedEmotion.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: widget.detectedEmotion.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      Text(
                        '${_user!.mbtiNickname} (${_user!.mbtiType})',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textS(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: widget.detectedEmotion.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textP(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }

    // Fallback tanpa MBTI
    return SuggestionCard(
      title: _title,
      suggestions: _suggestions,
      icon: Icons.lightbulb_outline_rounded,
      color: widget.detectedEmotion.color,
      isCollapsible: false,
    );
  }
}

