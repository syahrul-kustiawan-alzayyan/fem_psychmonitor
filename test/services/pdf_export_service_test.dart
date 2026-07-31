import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/models/emotion_model.dart';
import 'package:fem_physicsmonitor/services/database_service.dart';
import 'package:fem_physicsmonitor/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfExportService', () {
    test('generateUserReport menghasilkan bytes PDF valid', () async {
      final user = {
        'name': 'Budi',
        'email': 'budi@example.com',
        'mbti_type': 'INFJ',
        'psych_score': 80,
      };
      final recordings = <RecordingData>[
        RecordingData(
          userId: 1,
          date: DateTime(2024, 5, 1, 10, 30),
          dominantEmotion: EmotionType.happy,
          confidence: 0.9,
          suggestion: 'Saran',
          audioEmotions: const {},
          transcriptEmotions: const {},
          transcriptText: 'Hari yang baik',
          durationSeconds: 12,
        ),
      ];

      final bytes = await PdfExportService.generateUserReport(user, recordings);
      expect(bytes, isA<Uint8List>());
      expect(bytes, isNotEmpty);
      // Header PDF: %PDF
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('generateAllUsersReport menghasilkan bytes PDF valid', () async {
      final users = [
        {'name': 'A', 'email': 'a@x.com', 'psych_score': 55},
        {'name': 'B', 'email': 'b@x.com', 'psych_score': null},
      ];
      final bytes = await PdfExportService.generateAllUsersReport(users);
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
