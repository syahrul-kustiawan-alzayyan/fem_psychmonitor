import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_kit/whisper_kit.dart';

class WhisperInitService {
  WhisperInitService._();
  static final instance = WhisperInitService._();

  bool _ready = false;
  bool _initializing = false;

  bool get isReady => _ready;
  bool get isInitializing => _initializing;

  Future<void> warmUp() async {
    if (_ready || _initializing) return;
    _initializing = true;

    try {
      final whisper = Whisper(model: WhisperModel.base);

      final dir = await getTemporaryDirectory();
      final silentPath = '${dir.path}/_whisper_warmup.wav';
      _writeSilentWav(silentPath);

      await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: silentPath,
          language: 'id',
        ),
      );

      try {
        await File(silentPath).delete();
      } catch (_) {}

      _ready = true;
      debugPrint('✅ Whisper base model ready');
    } catch (e) {
      debugPrint('❌ Whisper warm-up error: $e');
    } finally {
      _initializing = false;
    }
  }

  void _writeSilentWav(String path) {
    const sampleRate = 16000;
    const bitsPerSample = 16;
    const numChannels = 1;
    const durationSec = 1;
    final numSamples = sampleRate * durationSec;
    final bytesPerSample = bitsPerSample ~/ 8;
    final dataSize = numSamples * numChannels * bytesPerSample;

    final result = ByteData(44 + dataSize);

    result.setUint32(0, 0x46464952, Endian.little);
    result.setUint32(4, 36 + dataSize, Endian.little);
    result.setUint32(8, 0x45564157, Endian.little);
    result.setUint32(12, 0x20746D66, Endian.little);
    result.setUint32(16, 16, Endian.little);
    result.setUint16(20, 1, Endian.little);
    result.setUint16(22, numChannels, Endian.little);
    result.setUint32(24, sampleRate, Endian.little);
    result.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little);
    result.setUint16(32, numChannels * bytesPerSample, Endian.little);
    result.setUint16(34, bitsPerSample, Endian.little);
    result.setUint32(36, 0x61746164, Endian.little);
    result.setUint32(40, dataSize, Endian.little);

    File(path).writeAsBytesSync(result.buffer.asUint8List());
  }
}
