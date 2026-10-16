import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DatabaseService — Backend cPanel (API PHP + MySQL)
//
// Semua operasi diteruskan ke ApiService (endpoint di cpanel_api/api/):
//   • /user.php       — CRUD user (upsert, get, delete, admin_exists)
//   • /recording.php  — CRUD recording
//   • /snapshot.php   — snapshot emosi per 3 detik
//   • /premium.php    — status premium
//   • /admin/users.php, /admin/user.php — dashboard admin
//   • /upload.php     — upload audio (.wav) → URL publik
//
// Identity user = Firebase UID (header X-Uid). Wajib login Firebase Auth.
// ─────────────────────────────────────────────────────────────────────────────
class DatabaseService {
  /// Helper: dapatkan UID user yang sedang login
  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Email dari Firebase Auth (untuk disinkronkan ke backend)
  static String? get currentEmail =>
      FirebaseAuth.instance.currentUser?.email;

  // ═══════════════════════════════════════════════════════════════
  // USER
  // ═══════════════════════════════════════════════════════════════

  /// Upsert user ke backend, return uid hashCode sebagai "int id"
  /// agar kompatibel dengan UI lama.
  static Future<int> insertUser(AppUser user) async {
    final uid = currentUid;
    if (uid == null) throw Exception('User not authenticated');

    await upsertUser(
      uid: uid,
      name: user.name,
      email: currentEmail ?? '',
      bigFiveScores: user.bigFiveScores,
      psychScore: user.psychologicalScore,
    );

    return uid.hashCode;
  }

  /// Upsert user ke backend (publik, dipakai juga untuk seed admin).
  static Future<void> upsertUser({
    required String uid,
    String name = 'User',
    String email = '',
    Map<String, double> bigFiveScores = const {},
    int? psychScore,
    bool isAdmin = false,
  }) async {
    await ApiService().post('/user.php', body: {
      'uid': uid,
      'name': name,
      'email': email,
      'bigfive_scores': bigFiveScores.map((k, v) => MapEntry(k, v)),
      'psych_score': psychScore,
      'is_admin': isAdmin,
    });
  }

  /// Ambil data user saat ini dari backend
  static Future<AppUser?> getUser() async {
    final uid = currentUid;
    if (uid == null) return null;

    try {
      final res = await ApiService().get('/user.php');
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return _userFromJson(data);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user data (upsert ke backend)
  static Future<void> updateUser(AppUser user) async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      await upsertUser(
        uid: uid,
        name: user.name,
        email: currentEmail ?? '',
        bigFiveScores: user.bigFiveScores,
        psychScore: user.psychologicalScore,
      );
    } catch (e) {
      debugPrint('Error updating user: $e');
    }
  }

  /// Update email user di backend (email diambil dari Firebase Auth)
  static Future<void> updateUserEmail(int id, String email) async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      await upsertUser(uid: uid, email: email);
    } catch (e) {
      debugPrint('Error updating user email: $e');
    }
  }

  static AppUser _userFromJson(Map<String, dynamic> data) {
    return AppUser(
      id: data['uid']?.toString().hashCode,
      name: data['name'] as String? ?? 'User',
      bigFiveScores: Map<String, double>.from(
        (data['bigfive_scores'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ) ?? {},
      ),
      psychologicalScore: data['psych_score'] != null
          ? (data['psych_score'] as num).toInt()
          : null,
      createdAt:
          DateTime.tryParse(data['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RECORDING
  // ═══════════════════════════════════════════════════════════════

  /// Simpan recording baru, return recording id (id MySQL AUTO_INCREMENT)
  static Future<int> insertRecording(RecordingData recording) async {
    final uid = currentUid;
    if (uid == null) throw Exception('User not authenticated');

    final res = await ApiService().post('/recording.php', body: {
      'date': recording.date.toIso8601String(),
      'dominant_emotion': recording.dominantEmotion.name,
      'confidence': recording.confidence,
      'suggestion': recording.suggestion,
      'audio_emotions': recording.audioEmotions
          .map((k, v) => MapEntry(k.name, v)),
      'transcript_emotions': recording.transcriptEmotions
          .map((k, v) => MapEntry(k.name, v)),
      'transcript_text': recording.transcriptText,
      'duration_seconds': recording.durationSeconds,
      'trigger_tag': recording.triggerTag,
      'audio_url': recording.audioUrl,
    });

    return (res['id'] as num).toInt();
  }

  /// Ambil semua recordings untuk user saat ini (diurutkan tanggal terbaru)
  static Future<List<RecordingData>> getRecordings({int? userId}) async {
    if (currentUid == null) return [];

    try {
      final res = await ApiService().get('/recording.php');
      final list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map(RecordingData.fromJson).toList();
    } catch (e) {
      debugPrint('Error getting recordings: $e');
      return [];
    }
  }

  /// Ambil recording by id (id MySQL)
  static Future<RecordingData?> getRecording(int id) async {
    if (currentUid == null) return null;

    try {
      final res = await ApiService().get('/recording.php', query: {'id': '$id'});
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return RecordingData.fromJson(data);
    } catch (e) {
      debugPrint('Error getting recording: $e');
      return null;
    }
  }

  /// Update trigger tag untuk recording tertentu
  static Future<void> updateRecordingTrigger(int recordingId, String triggerTag) async {
    try {
      await ApiService().put(
        '/recording.php',
        query: {'action': 'trigger', 'id': '$recordingId'},
        body: {'trigger_tag': triggerTag},
      );
    } catch (e) {
      debugPrint('Error updating recording trigger: $e');
    }
  }

  /// Update audio URL untuk recording tertentu
  static Future<void> updateRecordingAudioUrl(int recordingId, String audioUrl) async {
    try {
      await ApiService().put(
        '/recording.php',
        query: {'action': 'audio_url', 'id': '$recordingId'},
        body: {'audio_url': audioUrl},
      );
    } catch (e) {
      debugPrint('Error updating recording audio URL: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADMIN
  // ═══════════════════════════════════════════════════════════════

  /// Get ALL users dari backend (admin only). Setiap map berisi:
  /// uid, name, email, psych_score, created_at, is_admin, recording_count
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final res = await ApiService().get('/admin/users.php');
      return (res['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  /// Dashboard admin: daftar user + distribusi emosi (untuk chart).
  static Future<
      ({List<Map<String, dynamic>> users, Map<EmotionType, int> emotionDistribution})
  > getAdminDashboard() async {
    final users = <Map<String, dynamic>>[];
    final emotionDistribution = <EmotionType, int>{};
    try {
      final res = await ApiService().get('/admin/users.php');
      users.addAll((res['users'] as List?)?.cast<Map<String, dynamic>>() ?? []);
      final dist = (res['emotion_distribution'] as Map?) ?? {};
      dist.forEach((k, v) {
        final e = EmotionType.values.firstWhere(
          (x) => x.name == k.toString(),
          orElse: () => EmotionType.neutral,
        );
        emotionDistribution[e] = (v as num).toInt();
      });
    } catch (e) {
      debugPrint('Error getting admin dashboard: $e');
    }
    return (users: users, emotionDistribution: emotionDistribution);
  }

  /// Get a specific user by UID (admin)
  static Future<AppUser?> getUserByUid(String uid) async {
    try {
      final res = await ApiService().get('/admin/user.php', query: {'uid': uid});
      final data = res['user'] as Map<String, dynamic>?;
      if (data == null) return null;
      return _userFromJson(data);
    } catch (e) {
      debugPrint('Error getting user by UID: $e');
      return null;
    }
  }

  /// Get raw user map (admin) — berisi uid, name, email, psych_score,
  /// created_at, is_admin. Dipakai layar detail untuk menampilkan & PDF.
  static Future<Map<String, dynamic>?> getUserDataByUid(String uid) async {
    try {
      final res = await ApiService().get('/admin/user.php', query: {'uid': uid});
      return res['user'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting user data by UID: $e');
      return null;
    }
  }

  /// Get recordings untuk user tertentu (admin)
  static Future<List<RecordingData>> getUserRecordings(String uid) async {
    try {
      final res = await ApiService().get('/admin/user.php', query: {'uid': uid});
      final list =
          (res['recordings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map(RecordingData.fromJson).toList();
    } catch (e) {
      debugPrint('Error getting user recordings: $e');
      return [];
    }
  }

  /// Cek apakah admin sudah ada (untuk seed admin di main.dart)
  static Future<bool> adminExists() async {
    try {
      final res = await ApiService().get('/user.php', query: {'action': 'admin_exists'});
      return res['exists'] == true;
    } catch (e) {
      debugPrint('Error checking admin: $e');
      return false;
    }
  }

  /// Cek apakah user yang sedang login adalah admin
  static Future<bool> isCurrentUserAdmin() async {
    final uid = currentUid;
    if (uid == null) return false;

    try {
      final res = await ApiService().get('/user.php');
      final data = res['data'] as Map<String, dynamic>?;
      return data?['is_admin'] == true;
    } catch (e) {
      debugPrint('Error checking current user admin: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EMOTION SNAPSHOT
  // ═══════════════════════════════════════════════════════════════

  /// Simpan batch snapshots untuk satu recording
  static Future<void> insertSnapshots(
    int recordingId,
    List<EmotionSnapshot> snapshots,
  ) async {
    if (snapshots.isEmpty) return;

    try {
      await ApiService().post('/snapshot.php', body: {
        'recording_id': recordingId,
        'snapshots': snapshots.map((s) {
          return {
            'emotion': s.emotion.name,
            'confidence': s.confidence,
            'source': s.source,
            'timestamp': s.timestamp.toIso8601String(),
          };
        }).toList(),
      });
    } catch (e) {
      debugPrint('Error inserting snapshots: $e');
    }
  }

  /// Ambil snapshots untuk recording tertentu (diurutkan timestamp)
  static Future<List<EmotionSnapshot>> getSnapshots(int recordingId) async {
    try {
      final res = await ApiService().get('/snapshot.php', query: {'recording_id': '$recordingId'});
      final list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final snapshots = list.map(EmotionSnapshot.fromJson).toList();
      snapshots.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return snapshots;
    } catch (e) {
      debugPrint('Error getting snapshots: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PREMIUM STATUS
  // ═══════════════════════════════════════════════════════════════

  /// Verifikasi purchase token ke server (Play Developer API).
  /// Server menulis status premium sendiri — klien tidak pernah menulis.
  /// Returns (isPremium, expiryDate) hasil verifikasi server.
  static Future<({bool isPremium, DateTime? expiry})> verifyPremium(
    String productId,
    String purchaseToken,
  ) async {
    try {
      final res = await ApiService().post('/premium.php', body: {
        'product_id': productId,
        'purchase_token': purchaseToken,
      });
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final isPremium = data['is_premium'] == true;
      DateTime? expiry =
          DateTime.tryParse(data['premium_expiry'] as String? ?? '');
      return (isPremium: isPremium, expiry: expiry);
    } catch (e) {
      debugPrint('Error verifying premium purchase: $e');
      rethrow;
    }
  }

  /// Load premium status dari backend
  /// Returns (isPremium, expiryDate)
  static Future<({bool isPremium, DateTime? expiry})> loadPremiumStatus() async {
    try {
      final res = await ApiService().get('/premium.php');
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final isPremium = data['is_premium'] == true;
      DateTime? expiry =
          DateTime.tryParse(data['premium_expiry'] as String? ?? '');
      return (isPremium: isPremium, expiry: expiry);
    } catch (e) {
      debugPrint('Error loading premium status: $e');
      return (isPremium: false, expiry: null);
    }
  }

  /// Batalkan langganan premium langsung dari server (Play Developer API).
  /// Server memvalidasi token tersimpan lalu mencabut status premium.
  ///
  /// DELETE adalah jalur utama; bila hosting memblokir/proxy-kan DELETE
  /// (umumnya terlihat sebagai 405/502 non-JSON di shared hosting),
  /// otomatis fallback ke POST /premium.php?action=cancel.
  static Future<({bool ok, String? error})> cancelPremium() async {
    try {
      final res = await ApiService().delete('/premium.php');
      return (ok: res['ok'] == true, error: null);
    } on ApiException catch (e) {
      // Fallback untuk hosting yang memblokir method DELETE.
      final shouldRetry =
          e.statusCode == 405 || e.statusCode == 501 || e.statusCode == 502;
      if (shouldRetry) {
        debugPrint('DELETE /premium.php gagal ($e), coba POST ?action=cancel');
        try {
          final res = await ApiService().post(
            '/premium.php',
            query: {'action': 'cancel'},
          );
          return (ok: res['ok'] == true, error: null);
        } on ApiException catch (e2) {
          debugPrint('Error canceling premium (fallback): $e2');
          return (ok: false, error: e2.toString());
        }
      }
      debugPrint('Error canceling premium: $e');
      return (ok: false, error: e.toString());
    } catch (e) {
      debugPrint('Error canceling premium: $e');
      return (ok: false, error: e.toString());
    }
  }

  /// Reset instance (untuk logout - dipanggil oleh AuthProvider)
  static void resetInstance() {
    debugPrint('DatabaseService reset (no-op for server API)');
  }

  /// Hapus akun user + semua datanya dari backend (pengganti deleteDatabase)
  static Future<void> deleteDatabase() async {
    try {
      await ApiService().delete('/user.php');
      debugPrint('Server user data deleted successfully');
    } catch (e) {
      debugPrint('Error deleting server data: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// MODEL: RecordingData — Satu sesi rekaman lengkap
// ═══════════════════════════════════════════════════════════════
class RecordingData {
  final int? id;
  final int userId;
  final DateTime date;
  final EmotionType dominantEmotion;
  final double confidence;
  final String suggestion;
  final Map<EmotionType, double> audioEmotions;
  final Map<EmotionType, double> transcriptEmotions;
  final String transcriptText;
  final int durationSeconds;
  final String triggerTag;
  final String audioUrl;

  const RecordingData({
    this.id,
    required this.userId,
    required this.date,
    required this.dominantEmotion,
    required this.confidence,
    required this.suggestion,
    required this.audioEmotions,
    required this.transcriptEmotions,
    this.transcriptText = '',
    this.durationSeconds = 0,
    this.triggerTag = '',
    this.audioUrl = '',
  });

  /// Factory dari respons JSON backend (API PHP + MySQL)
  factory RecordingData.fromJson(Map<String, dynamic> data) {
    final audioMap = (data['audio_emotions'] as Map?) ?? {};
    final textMap = (data['transcript_emotions'] as Map?) ?? {};

    DateTime dateValue = DateTime.tryParse(data['date'] as String? ?? '') ??
        DateTime.now();

    return RecordingData(
      id: data['id'] != null ? (data['id'] as num).toInt() : null,
      userId: data['user_id'] != null ? (data['user_id'] as num).toInt() : 0,
      date: dateValue,
      dominantEmotion: EmotionType.values.firstWhere(
        (e) => e.name == data['dominant_emotion'],
        orElse: () => EmotionType.neutral,
      ),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      suggestion: data['suggestion'] as String? ?? '',
      audioEmotions: audioMap.map(
        (k, v) => MapEntry(
          EmotionType.values.firstWhere(
            (e) => e.name == k.toString(),
            orElse: () => EmotionType.neutral,
          ),
          (v as num).toDouble(),
        ),
      ),
      transcriptEmotions: textMap.map(
        (k, v) => MapEntry(
          EmotionType.values.firstWhere(
            (e) => e.name == k.toString(),
            orElse: () => EmotionType.neutral,
          ),
          (v as num).toDouble(),
        ),
      ),
      transcriptText: data['transcript_text'] as String? ?? '',
      durationSeconds: (data['duration_seconds'] as num?)?.toInt() ?? 0,
      triggerTag: data['trigger_tag'] as String? ?? '',
      audioUrl: data['audio_url'] as String? ?? '',
    );
  }

  /// Backward compat dari Firestore (docId hanya untuk id fallback)
  factory RecordingData.fromFirestore(String docId, Map<String, dynamic> data) {
    return RecordingData.fromJson(data);
  }

  /// Backward compat: fromMap
  factory RecordingData.fromMap(Map<String, dynamic> map) {
    return RecordingData.fromJson(map);
  }

  /// Convert ke EmotionRecord untuk kompatibilitas UI
  EmotionRecord toEmotionRecord() {
    return EmotionRecord(
      emotion: dominantEmotion,
      confidence: confidence,
      timestamp: date,
      recordingId: id,
      triggerTag: triggerTag,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODEL: EmotionSnapshot — Satu snapshot tiap 3 detik
// ═══════════════════════════════════════════════════════════════
class EmotionSnapshot {
  final int? id;
  final int? recordingId;
  final EmotionType emotion;
  final double confidence;
  final String source; // 'audio', 'transcript', 'combined'
  final DateTime timestamp;

  const EmotionSnapshot({
    this.id,
    this.recordingId,
    required this.emotion,
    required this.confidence,
    required this.source,
    required this.timestamp,
  });

  /// Factory dari respons JSON backend (API PHP + MySQL)
  factory EmotionSnapshot.fromJson(Map<String, dynamic> data) {
    return EmotionSnapshot(
      id: data['id'] != null ? (data['id'] as num).toInt() : null,
      recordingId: data['recording_id'] != null
          ? (data['recording_id'] as num).toInt()
          : null,
      emotion: EmotionType.values.firstWhere(
        (e) => e.name == data['emotion'],
        orElse: () => EmotionType.neutral,
      ),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      source: data['source'] as String? ?? 'combined',
      timestamp:
          DateTime.tryParse(data['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Backward compat dari Firestore
  factory EmotionSnapshot.fromFirestore(String docId, Map<String, dynamic> data) {
    return EmotionSnapshot.fromJson(data);
  }

  /// Backward compat: fromMap
  factory EmotionSnapshot.fromMap(Map<String, dynamic> map) {
    return EmotionSnapshot.fromJson(map);
  }
}
