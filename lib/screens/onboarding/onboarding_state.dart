import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';

class OnboardingState extends ChangeNotifier {
  bool isLoading = true;

  // Big Five
  List<BigFiveQuestion> bigFiveQuestions = [];
  List<int?> bigFiveAnswers = [];

  // MBTI (legacy, kept for compatibility)
  List<MBTIQuestion> mbtiQuestions = [];
  List<int?> mbtiAnswers = [];

  List<PsyQuestion> psyQuestions = [];
  List<int?> psyAnswers = [];

  bool mbtiSkipped = false;
  bool showManualMbti = false;
  String mbtiType = '';
  Map<String, int> mbtiScores = {};

  // Big Five results
  Map<String, double> bigFiveScores = {};

  int psyScore = 0;
  bool isSaving = false;

  String? _loadedLocale;

  Future<void> loadQuestions() async {
    try {
      final locale = AppLocalizations.locale;

      if (_loadedLocale == locale && !isLoading && bigFiveQuestions.isNotEmpty) {
        return;
      }

      isLoading = true;
      notifyListeners();

      final bigFiveFile = locale.startsWith('en')
          ? 'assets/BigFive_MiniIPIP20_en.json'
          : 'assets/BigFive_MiniIPIP20.json';
      final psyFile = locale.startsWith('en') ? 'assets/psych_en.json' : 'assets/psych.json';

      final bigFiveString = await rootBundle.loadString(bigFiveFile);
      final bigFiveJson = jsonDecode(bigFiveString);
      final bigFiveList = (bigFiveJson['big_five_questionnaire'] as List)
          .map((q) => BigFiveQuestion.fromJson(q))
          .toList();

      final psyString = await rootBundle.loadString(psyFile);
      final psyJson = jsonDecode(psyString);
      final psyList = (psyJson['womens_mental_health_assessment']['questions'] as List)
          .map((q) => PsyQuestion.fromJson(q))
          .toList();

      bigFiveQuestions = bigFiveList;
      psyQuestions = psyList;
      bigFiveAnswers = List.filled(bigFiveQuestions.length, null);
      psyAnswers = List.filled(psyQuestions.length, null);
      _loadedLocale = locale;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading questions: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Big Five ──────────────────────────────────────────────
  bool get isBigFiveComplete => !bigFiveAnswers.contains(null);

  void setBigFiveAnswer(int index, int value) {
    bigFiveAnswers[index] = value;
    notifyListeners();
  }

  void calculateBigFiveResult() {
    bigFiveScores = calculateBigFive(
      bigFiveAnswers.map((e) => e ?? 3).toList(),
      bigFiveQuestions,
    );
    notifyListeners();
  }

  // ── MBTI (legacy) ──────────────────────────────────────────
  void skipMbti() {
    mbtiSkipped = true;
    showManualMbti = true;
    notifyListeners();
  }

  void doNotSkipMbti() {
    mbtiSkipped = false;
    showManualMbti = false;
    mbtiType = '';
    mbtiScores = {};
    notifyListeners();
  }

  void setManualMbtiType(String type) {
    mbtiType = type;
    notifyListeners();
  }

  void setMbtiAnswer(int index, int rating) {
    mbtiAnswers[index] = rating;
    notifyListeners();
  }

  void calculateMbtiResult() {
    if (!mbtiSkipped) {
      final result = calculateMBTI(mbtiAnswers.map((e) => e ?? 0).toList(), mbtiQuestions);
      mbtiType = result.type;
      mbtiScores = result.scores;
    } else {
      if (mbtiType.isEmpty) mbtiType = 'XXXX';
      mbtiScores = {
        'E': 0, 'I': 0, 'S': 0, 'N': 0, 'T': 0, 'F': 0, 'J': 0, 'P': 0,
      };
    }
    notifyListeners();
  }

  void setPsyAnswer(int index, int value) {
    psyAnswers[index] = value;
    notifyListeners();
  }

  void calculatePsyResult() {
    psyScore = psyAnswers.fold<int>(0, (sum, val) => sum + (val ?? 0));
    notifyListeners();
  }

  bool isMbtiComplete() {
    if (mbtiSkipped && mbtiType.isNotEmpty) return true;
    if (!mbtiSkipped && !mbtiAnswers.contains(null)) return true;
    return false;
  }

  bool isPsyComplete() {
    return !psyAnswers.contains(null);
  }

  void setSaving(bool saving) {
    isSaving = saving;
    notifyListeners();
  }
}
