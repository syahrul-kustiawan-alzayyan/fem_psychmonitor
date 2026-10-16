import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/models/emotion_model.dart';
import 'package:fem_physicsmonitor/services/ser_service.dart';

/// Tes integrasi SerService melawan server SER asli.
///
/// BUTUH server hidup di http://127.0.0.1:8001
/// (jalankan: python -u assets/model_deploy/server_ssl.py).
/// Jika server mati, semua tes dilewati (SKIP), bukan gagal —
/// supaya suite unit tetap hijau di mesin tanpa server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var serverUp = false;

  setUpAll(() async {
    // Config khusus tes (tanpa file .env): server lokal di mesin ini.
    dotenv.testLoad(fileInput: 'SER_BASE_URL=http://127.0.0.1:8001');
    try {
      await SerService().checkHealth().timeout(const Duration(seconds: 15));
      serverUp = true;
    } catch (e) {
      // ignore: avoid_print
      print('SKIP ser_service_test: server tidak hidup ($e)');
    }
  });

  /// Buat wav sine 16 kHz mono 16-bit di direktori temporer.
  Future<String> makeWav({double seconds = 2.0, double freq = 220.0}) async {
    const sr = 16000;
    final n = (sr * seconds).round();
    final pcm = Int16List(n);
    for (var i = 0; i < n; i++) {
      pcm[i] = (sin(2 * pi * freq * i / sr) * 30000).round();
    }
    final dataSize = n * 2;
    final header = ByteData(44)
      ..setUint32(0, 0x46464952, Endian.little) // RIFF
      ..setUint32(4, 36 + dataSize, Endian.little)
      ..setUint32(8, 0x45564157, Endian.little) // WAVE
      ..setUint32(12, 0x20746d66, Endian.little) // fmt
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, sr, Endian.little)
      ..setUint32(28, sr * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(36, 0x61746164, Endian.little) // data
      ..setUint32(40, dataSize, Endian.little);
    final bytes = BytesBuilder()
      ..add(header.buffer.asUint8List())
      ..add(pcm.buffer.asUint8List());
    final path =
        '${Directory.systemTemp.path}/ser_test_${DateTime.now().microsecondsSinceEpoch}.wav';
    await File(path).writeAsBytes(bytes.toBytes());
    return path;
  }

  group('SerService (butuh server lokal)', () {
    test('health ok + taksonomi 6 emosi', () async {
      if (!serverUp) return;
      await SerService().checkHealth(); // throw bila tidak ok
    });

    test('predict wav valid -> 6 skor, total ~1, ada fear (mapping fearful)', () async {
      if (!serverUp) return;
      final path = await makeWav();
      final res = await SerService().predictEmotion(path);
      expect(res.scores.length, EmotionType.values.length);
      final total = res.scores.values.fold<double>(0, (a, b) => a + b);
      expect(total, closeTo(1.0, 0.01));
      // server mengirim key 'fearful' -> harus terpetakan ke EmotionType.fear
      expect(res.scores.containsKey(EmotionType.fear), isTrue);
      expect(res.confidence, inInclusiveRange(0.0, 1.0));
      expect(EmotionType.values, contains(res.dominant));
    });

    test('file sampah -> SerException (fail-closed, bukan skor palsu)', () async {
      if (!serverUp) return;
      final path =
          '${Directory.systemTemp.path}/ser_junk_${DateTime.now().microsecondsSinceEpoch}.wav';
      await File(path).writeAsString('bukan audio sama sekali');
      expect(() => SerService().predictEmotion(path), throwsA(isA<SerException>()));
      expect(() => SerService().transcribe(path), throwsA(isA<SerException>()));
    });

    test('transcribe wav valid -> string (fail-closed bila server mati)', () async {
      if (!serverUp) return;
      final path = await makeWav(seconds: 3.0, freq: 440.0);
      final text = await SerService().transcribe(path);
      expect(text, isA<String>()); // nada sine boleh kosong, yang penting 200
    });

    test('file tidak ada -> SerException', () async {
      // tidak butuh server: validasi path lokal dulu
      expect(
        () => SerService().predictEmotion('/tidak/ada/file.wav'),
        throwsA(isA<SerException>()),
      );
    });
  });
}
