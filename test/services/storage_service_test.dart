import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fem_physicsmonitor/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageService — onboarding flags', () {
    test('first launch default true', () async {
      expect(await StorageService.isFirstLaunch(), isTrue);
    });

    test('setOnboardingComplete menandai selesai & menyimpan nama', () async {
      await StorageService.setOnboardingComplete('Budi');
      expect(await StorageService.isFirstLaunch(), isFalse);
      expect(await StorageService.getUserName(), 'Budi');
    });

    test('getUserName default "User"', () async {
      expect(await StorageService.getUserName(), 'User');
    });

    test('resetOnboarding mengembalikan first launch', () async {
      await StorageService.setOnboardingComplete('Budi');
      await StorageService.resetOnboarding();
      expect(await StorageService.isFirstLaunch(), isTrue);
    });
  });

  group('StorageService — daily detection limit', () {
    const uid = 'test-user-123';

    test('awal hari sisa 5', () async {
      expect(await StorageService.getRemainingDetections(uid), 5);
    });

    test('increment menurunkan sisa', () async {
      for (var i = 0; i < 3; i++) {
        await StorageService.incrementDetectionCount(uid);
      }
      expect(await StorageService.getRemainingDetections(uid), 2);
    });

    test('limit tidak pernah di bawah 0', () async {
      for (var i = 0; i < 10; i++) {
        await StorageService.incrementDetectionCount(uid);
      }
      expect(await StorageService.getRemainingDetections(uid), 0);
    });

    test('perhitungan terpisah per akun (uid)', () async {
      await StorageService.incrementDetectionCount(uid);
      await StorageService.incrementDetectionCount(uid);
      expect(await StorageService.getRemainingDetections('uid-lain'), 5);
      expect(await StorageService.getRemainingDetections(uid), 3);
    });
  });
}
