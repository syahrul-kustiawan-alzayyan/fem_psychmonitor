import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:http/http.dart' as http;

import 'config_service.dart';

/// Error yang dilempar saat request API gagal.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Klien HTTP untuk backend cPanel (API PHP + MySQL).
///
/// Semua request menyertakan header:
///   X-Api-Key  → shared secret (dari .env, harus sama dengan config.php)
///   X-Uid      → Firebase UID user yang sedang login
class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  static const Duration _timeout = Duration(seconds: 20);

  static String get _baseUrl => ConfigService.apiBaseUrl;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Api-Key': ConfigService.apiKey,
        if (_uid != null && _uid!.isNotEmpty) 'X-Uid': _uid!,
      };

  /// Parse & validasi respons JSON. Selalu mengembalikan map body.
  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }
    if (res.statusCode >= 200 && res.statusCode < 300 && body['ok'] == true) {
      return body;
    }
    throw ApiException(
      (body['error'] as String?) ?? 'HTTP ${res.statusCode}',
      statusCode: res.statusCode,
    );
  }

  static Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Waktu koneksi habis. Periksa koneksi internet.');
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// GET request → body JSON.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) {
    return _guard(() async {
      final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
      final res = await http.get(uri, headers: _headers()).timeout(_timeout);
      return _handle(res);
    });
  }

  /// POST request → body JSON.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _guard(() async {
      final uri = Uri.parse('$_baseUrl$path');
      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(res);
    });
  }

  /// PUT request → body JSON.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) {
    return _guard(() async {
      final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
      final res = await http
          .put(uri, headers: _headers(), body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(res);
    });
  }

  /// DELETE request → body JSON.
  Future<Map<String, dynamic>> delete(String path) {
    return _guard(() async {
      final uri = Uri.parse('$_baseUrl$path');
      final res = await http.delete(uri, headers: _headers()).timeout(_timeout);
      return _handle(res);
    });
  }

  /// Upload file audio ke backend cPanel → mengembalikan URL publik.
  Future<String> uploadAudio(String filePath) {
    return _guard(() async {
      final uri = Uri.parse('$_baseUrl/upload.php');
      final request = http.MultipartRequest('POST', uri)
        ..headers['X-Api-Key'] = ConfigService.apiKey
        ..headers['X-Uid'] = _uid ?? ''
        ..files.add(await http.MultipartFile.fromPath('audio', filePath));

      final streamed = await request.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      final body = await _handle(res);
      return body['url'] as String? ?? '';
    });
  }
}
