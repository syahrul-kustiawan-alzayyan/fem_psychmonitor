import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart'; // To get MBTIQuestion, PsyQuestion, calculateMBTI

class OnboardingState extends ChangeNotifier {
  bool isLoading = true;

  List<MBTIQuestion> mbtiQuestions = [];
  List<PsyQuestion> psyQuestions = [];

  List<int?> mbtiAnswers = [];
  List<int?> psyAnswers = [];

  bool mbtiSkipped = false;
  bool showManualMbti = false;
  String mbtiType = '';
  Map<String, int> mbtiScores = {};

  int psyScore = 0;
  bool isSaving = false;

  String? _loadedLocale;

  Future<void> loadQuestions() async {
    try {
      final locale = AppLocalizations.locale;

      // Skip reload jika locale sama dan sudah dimuat
      if (_loadedLocale == locale && !isLoading && mbtiQuestions.isNotEmpty) {
        return;
      }

      isLoading = true;
      notifyListeners();

      final mbtiFile = locale.startsWith('en') ? 'assets/MBTI_en.json' : 'assets/MBTI.json';
      final psyFile = locale.startsWith('en') ? 'assets/psych_en.json' : 'assets/psych.json';

      final mbtiString = await rootBundle.loadString(mbtiFile);
      final mbtiJson = jsonDecode(mbtiString);
      final mbtiList = (mbtiJson['mbti_questionnaire'] as List)
          .map((q) => MBTIQuestion.fromJson(q))
          .toList();

      final psyString = await rootBundle.loadString(psyFile);
      final psyJson = jsonDecode(psyString);
      final psyList = (psyJson['womens_mental_health_assessment']['questions'] as List)
          .map((q) => PsyQuestion.fromJson(q))
          .toList();

      mbtiQuestions = mbtiList;
      psyQuestions = psyList;
      mbtiAnswers = List.filled(mbtiQuestions.length, null);
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

  void setPsyAnswer(int index, int rating) {
    psyAnswers[index] = rating;
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
