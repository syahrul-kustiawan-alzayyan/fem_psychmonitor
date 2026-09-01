import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';

class TextEmotionService {
  TextEmotionService._();
  static final instance = TextEmotionService._();

  Map<EmotionType, List<String>> _keywords = {};
  bool _loaded = false;
  String _loadedLocale = '';

  Future<void> loadAll() async {
    final currentLocale = AppLocalizations.currentLocale;
    // Reload if locale changed or not loaded yet.
    if (_loaded && _loadedLocale == currentLocale) return;
    _keywords = {};
    _loadedLocale = currentLocale;

    final file = currentLocale == 'en'
        ? 'assets/emotion_en.json'
        : 'assets/emotion.json';
    final jsonStr = await rootBundle.loadString(file);
    final Map<String, dynamic> data = json.decode(jsonStr);

    for (final entry in data.entries) {
      final emotion = _parseEmotion(entry.key);
      if (emotion == null) continue;
      final words = List<String>.from(entry.value);
      _keywords[emotion] = (_keywords[emotion] ?? [])..addAll(words);
    }

    _loaded = true;
  }

  EmotionType? _parseEmotion(String key) {
    switch (key) {
      case 'happy':   return EmotionType.happy;
      case 'sad':     return EmotionType.sad;
      case 'angry':   return EmotionType.angry;
      case 'disgust': return EmotionType.disgust;
      case 'neutral': return EmotionType.neutral;
      case 'fear':    return EmotionType.fear;
      default:        return null;
    }
  }

  Map<EmotionType, double> analyze(String text) {
    if (text.trim().isEmpty || !_loaded) {
      return {
        EmotionType.happy:   0.1,
        EmotionType.sad:     0.1,
        EmotionType.angry:   0.1,
        EmotionType.disgust: 0.1,
        EmotionType.neutral: 0.5,
        EmotionType.fear:    0.1,
      };
    }

    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'[\s,.!?;:()\-]+'));

    Map<EmotionType, double> scores = {};
    int totalMatches = 0;

    for (final entry in _keywords.entries) {
      final emotion = entry.key;
      final kws = entry.value;
      int count = 0;

      for (final kw in kws) {
        if (kw.contains(' ')) {
          if (lower.contains(kw)) {
            count += 2;
          }
        } else {
          count += words.where((w) => w == kw).length;
        }
      }

      scores[emotion] = count.toDouble();
      totalMatches += count;
    }

    if (totalMatches == 0) {
      return {
        EmotionType.happy:   0.1,
        EmotionType.sad:     0.1,
        EmotionType.angry:   0.1,
        EmotionType.disgust: 0.1,
        EmotionType.neutral: 0.5,
        EmotionType.fear:    0.1,
      };
    }

    for (final e in EmotionType.values) {
      scores[e] = (scores[e] ?? 0) / totalMatches;
    }

    return scores;
  }
}
