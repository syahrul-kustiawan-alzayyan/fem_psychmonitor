import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/emotion_model.dart';
import 'config_service.dart';

/// Error fail-closed dari server SER (tidak ada fallback diam-diam).
class SerException implements Exception {
  final String message;
  final int? statusCode;

  const SerException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Hasil inferensi dari `POST /predict-ssl`.
class SerResult {
  final String label;
  final double confidence;
  final Map<EmotionType, double> scores;
  final double inferSeconds;

  const SerResult({
    required this.label,
    required this.confidence,
    required this.scores,
    this.inferSeconds = 0,
  });

  EmotionType get dominant {
    var best = EmotionType.neutral;
    var bestScore = -1.0;
    for (final e in EmotionType.values) {
      final s = scores[e] ?? 0;
      if (s > bestScore) {
        bestScore = s;
        best = e;
      }
    }
    return best;
  }
}

/// Klien HTTP untuk server inferensi SSL lokal (`assets/model_deploy/server_ssl.py`).
///
/// Kontrak server: GET /health, POST /predict-ssl (emosi, multipart `file`
/// .wav/.flac maks 10MB), POST /transcribe (teks Bahasa Indonesia).
///
/// Fail-closed: setiap kegagalan throw [SerException], tidak ada skor mock.
class SerService {
  SerService._();
  static final SerService _instance = SerService._();
  factory SerService() => _instance;

  static const Duration _healthTimeout = Duration(seconds: 10);
  static const Duration _predictTimeout = Duration(seconds: 90);
  static const int _maxBytes = 10 * 1024 * 1024;

  static String get _baseUrl {
    final raw = ConfigService.serBaseUrl.trim();
    if (raw.isEmpty) return 'http://127.0.0.1:8001';
    return raw.endsWith('/')
        ? raw.substring(0, raw.length - 1)
        : raw;
  }

  static String get baseUrl => _baseUrl;

  /// Cek server hidup + kontrak emosi sesuai harapan.
  Future<void> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/health');
    try {
      final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(_healthTimeout);
      if (res.statusCode != 200) {
        throw SerException('Server SER tidak sehat (HTTP ${res.statusCode}). Pastikan `python server_ssl.py` berjalan di $baseUrl.', statusCode: res.statusCode);
      }
      Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw const SerException('Respons /health bukan JSON valid.');
      }
      if (body['status'] != 'ok') {
        throw SerException('Respons /health tidak ok: ${res.body}');
      }
    } on SerException {
      rethrow;
    } on TimeoutException {
      throw SerException('Timeout menghubungi server SER di $baseUrl. Pastikan `python server_ssl.py` sudah jalan.');
    } on SocketException {
      throw SerException('Tidak dapat terhubung ke server SER di $baseUrl. Pastikan `python server_ssl.py` sudah jalan dan firewall mengizinkan.');
    } on http.ClientException {
      throw SerException('Tidak dapat terhubung ke server SER di $baseUrl.');
    } catch (e) {
      throw SerException('Gagal cek /health: $e');
    }
  }

  static const Duration _transcribeTimeout = Duration(seconds: 180);

  /// Kirim file wav ke satu endpoint server, kembalikan body JSON yang
  /// sudah divalidasi HTTP-nya. Validasi isi diserahkan ke pemanggil.
  Future<Map<String, dynamic>> _postAudio(
      String endpoint, String wavPath, Duration timeout) async {
    final file = File(wavPath);
    if (!file.existsSync()) {
      throw SerException('File audio tidak ditemukan: $wavPath');
    }
    final length = await file.length();
    if (length == 0) {
      throw const SerException('File audio kosong (0 bytes). Rekam ulang dengan durasi lebih lama.');
    }
    if (length > _maxBytes) {
      throw const SerException('File audio >10MB, ditolak server. Rekam lebih pendek.');
    }

    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', wavPath));

      debugPrint('📤 SER POST $uri (${(length / 1024).toStringAsFixed(1)} KB)');
      final streamed = await request.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);
      debugPrint('📥 SER ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 300))}');

      Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        body = {};
      }

      if (res.statusCode != 200) {
        final detail = (body['detail'] as String?)?.trim();
        throw SerException(
          detail != null && detail.isNotEmpty
              ? 'Server SER menolak (HTTP ${res.statusCode}): $detail'
              : 'Server SER error (HTTP ${res.statusCode}). Cek log server_ssl.py.',
          statusCode: res.statusCode,
        );
      }
      return body;
    } on SerException {
      rethrow;
    } on TimeoutException {
      throw SerException('Timeout $endpoint (> ${timeout.inSeconds} dtk). Server CPU bisa lambat di awal (cold start). Coba lagi.');
    } on SocketException {
      throw SerException('Terputus dari server SER di $baseUrl saat $endpoint.');
    } on http.ClientException catch (e) {
      throw SerException('Gagal HTTP ke server SER: $e');
    } catch (e) {
      if (e is SerException) rethrow;
      throw SerException('Gagal $endpoint: $e');
    }
  }

  /// Kirim file wav ke server, kembalikan skor 6 emosi.
  ///
  /// Mapping label server ke EmotionType:
  /// `fearful` menjadi `EmotionType.fear`, sisanya sama persis.
  Future<SerResult> predictEmotion(String wavPath) async {
    final body = await _postAudio('/predict-ssl', wavPath, _predictTimeout);
    final probs = body['class_probs'] as Map?;
    final label = (body['label'] as String?) ?? '';
    final confidence = (body['confidence'] as num?)?.toDouble() ?? double.nan;
    if (probs == null || label.isEmpty || confidence.isNaN) {
      throw SerException('Respons server tidak lengkap: $body');
    }
    return SerResult(
      label: label,
      confidence: confidence,
      scores: _mapProbs(probs),
      inferSeconds: (body['infer_s'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Transkripsi via server (faster-whisper, bahasa Indonesia).
  /// Kembalikan teks (bisa kosong bila tidak ada ucapan terdeteksi).
  /// Throw [SerException] bila server menolak/gagal — pemanggil yang
  /// memutuskan fallback (mis. Whisper on-device).
  Future<String> transcribe(String wavPath) async {
    final body = await _postAudio('/transcribe', wavPath, _transcribeTimeout);
    if (!body.containsKey('text')) {
      throw SerException('Respons transkripsi tidak lengkap: $body');
    }
    return (body['text'] as String? ?? '').trim();
  }

  /// Ubah `class_probs` server menjadi skor emosi + normalisasi.
  Map<EmotionType, double> _mapProbs(Map probs) {
    EmotionType? parse(String key) {
      switch (key.toLowerCase()) {
        case 'happy':
          return EmotionType.happy;
        case 'sad':
          return EmotionType.sad;
        case 'angry':
          return EmotionType.angry;
        case 'fearful':
        case 'fear':
          return EmotionType.fear;
        case 'disgust':
          return EmotionType.disgust;
        case 'neutral':
          return EmotionType.neutral;
        default:
          return null;
      }
    }

    final scores = <EmotionType, double>{};
    probs.forEach((k, v) {
      final e = parse(k.toString());
      if (e != null) scores[e] = (v as num).toDouble();
    });

    // Kontrak: harus 6 emosi lengkap.
    if (scores.length != EmotionType.values.length) {
      throw SerException('class_probs tidak lengkap (dapat ${scores.length}/6): $probs');
    }
    final total = scores.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) {
      throw const SerException('class_probs total 0, tidak valid.');
    }
    // Normalisasi ringan agar total = 1 (server sudah softmax+mean ensemble).
    scores.updateAll((_, v) => v / total);
    return scores;
  }
}
