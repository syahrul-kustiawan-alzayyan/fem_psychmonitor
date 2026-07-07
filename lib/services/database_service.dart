import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion_model.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DatabaseService — Cloud Firestore persistence
//
// Koleksi Firestore:
//   • users/{uid}                                    — Data user + hasil MBTI
//   • users/{uid}/recordings/{id}                    — Data recording lengkap
//   • users/{uid}/recordings/{id}/snapshots/{id}     — Snapshot emosi per 3 detik
// ─────────────────────────────────────────────────────────────────────────────
class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper: dapatkan UID user yang sedang login
  static String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Reference ke dokumen user saat ini
  static DocumentReference? get _userDoc {
    final uid = _currentUid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // ═══════════════════════════════════════════════════════════════
  // USER CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Simpan user baru ke Firestore, return user id (UID string → int hash)
  static Future<int> insertUser(AppUser user) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    final data = {
      'name': user.name,
      'email': email,
      'mbti_type': user.mbtiType,
      'mbti_scores': user.mbtiScores,
      'bigfive_scores': user.bigFiveScores.map((k, v) => MapEntry(k, v)),
      'psych_score': user.psychologicalScore,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));

    // Return uid hashCode sebagai "int id" agar kompatibel dengan UI lama
    return uid.hashCode;
  }

  /// Ambil data user saat ini
  static Future<AppUser?> getUser() async {
    final docRef = _userDoc;
    if (docRef == null) return null;

    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) return null;

      final data = snapshot.data() as Map<String, dynamic>;
      return AppUser(
        id: _currentUid.hashCode,
        name: data['name'] as String? ?? 'User',
        mbtiType: data['mbti_type'] as String? ?? '',
        mbtiScores: Map<String, int>.from(
          (data['mbti_scores'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ?? {},
        ),
        bigFiveScores: Map<String, double>.from(
          (data['bigfive_scores'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ) ?? {},
        ),
        psychologicalScore: data['psych_score'] != null
            ? (data['psych_score'] as num).toInt()
            : null,
        createdAt: data['created_at'] != null
            ? (data['created_at'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user data
  static Future<void> updateUser(AppUser user) async {
    final docRef = _userDoc;
    if (docRef == null) return;

    await docRef.update({
      'name': user.name,
      'mbti_type': user.mbtiType,
      'mbti_scores': user.mbtiScores,
      'bigfive_scores': user.bigFiveScores.map((k, v) => MapEntry(k, v)),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Update email user (tidak diperlukan di Firebase Auth, karena email
  /// sudah ada di auth profile — tapi kita sync ke Firestore juga)
  static Future<void> updateUserEmail(int id, String email) async {
    final docRef = _userDoc;
    if (docRef == null) return;

    await docRef.update({
      'email': email,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // RECORDING CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Simpan recording baru, return recording id (hashCode dari doc ID)
  static Future<int> insertRecording(RecordingData recording) async {
    final docRef = _userDoc;
    if (docRef == null) throw Exception('User not authenticated');

    final recordingsRef = docRef.collection('recordings');
    final newDoc = await recordingsRef.add({
      'date': Timestamp.fromDate(recording.date),
      'dominant_emotion': recording.dominantEmotion.name,
      'confidence': recording.confidence,
      'suggestion': recording.suggestion,
      'audio_emotions': recording.audioEmotions.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'transcript_emotions': recording.transcriptEmotions.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'transcript_text': recording.transcriptText,
      'duration_seconds': recording.durationSeconds,
      'trigger_tag': recording.triggerTag,
    });

    return newDoc.id.hashCode;
  }

  /// Ambil semua recordings untuk user saat ini
  static Future<List<RecordingData>> getRecordings({int? userId}) async {
    final docRef = _userDoc;
    if (docRef == null) return [];

    try {
      final querySnapshot = await docRef
          .collection('recordings')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return RecordingData.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting recordings: $e');
      return [];
    }
  }

  /// Ambil recording by id (Firestore doc ID hashCode)
  static Future<RecordingData?> getRecording(int id) async {
    final docRef = _userDoc;
    if (docRef == null) return null;

    try {
      // Karena kita menyimpan hashCode sebagai id, kita perlu scan
      final querySnapshot = await docRef.collection('recordings').get();

      for (final doc in querySnapshot.docs) {
        if (doc.id.hashCode == id) {
          return RecordingData.fromFirestore(doc.id, doc.data());
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting recording: $e');
      return null;
    }
  }

  /// Update trigger tag untuk recording tertentu
  static Future<void> updateRecordingTrigger(int recordingId, String triggerTag) async {
    final docRef = _userDoc;
    if (docRef == null) return;

    try {
      final querySnapshot = await docRef.collection('recordings').get();
      for (final doc in querySnapshot.docs) {
        if (doc.id.hashCode == recordingId) {
          await doc.reference.update({'trigger_tag': triggerTag});
          return;
        }
      }
    } catch (e) {
      debugPrint('Error updating recording trigger: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EMOTION SNAPSHOT CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Simpan batch snapshots untuk satu recording
  static Future<void> insertSnapshots(
    int recordingId,
    List<EmotionSnapshot> snapshots,
  ) async {
    final docRef = _userDoc;
    if (docRef == null) return;

    try {
      // Cari recording doc yang sesuai hashCode
      final querySnapshot = await docRef.collection('recordings').get();
      String? recordingDocId;

      for (final doc in querySnapshot.docs) {
        if (doc.id.hashCode == recordingId) {
          recordingDocId = doc.id;
          break;
        }
      }

      if (recordingDocId == null) {
        debugPrint('Recording not found for id: $recordingId');
        return;
      }

      final batch = _firestore.batch();
      final snapshotsRef = docRef
          .collection('recordings')
          .doc(recordingDocId)
          .collection('snapshots');

      for (final snap in snapshots) {
        final snapDoc = snapshotsRef.doc();
        batch.set(snapDoc, {
          'emotion': snap.emotion.name,
          'confidence': snap.confidence,
          'source': snap.source,
          'timestamp': Timestamp.fromDate(snap.timestamp),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error inserting snapshots: $e');
    }
  }

  /// Ambil snapshots untuk recording tertentu
  static Future<List<EmotionSnapshot>> getSnapshots(int recordingId) async {
    final docRef = _userDoc;
    if (docRef == null) return [];

    try {
      // Cari recording doc yang sesuai hashCode
      final querySnapshot = await docRef.collection('recordings').get();
      String? recordingDocId;

      for (final doc in querySnapshot.docs) {
        if (doc.id.hashCode == recordingId) {
          recordingDocId = doc.id;
          break;
        }
      }

      if (recordingDocId == null) return [];

      final snapshotsQuery = await docRef
          .collection('recordings')
          .doc(recordingDocId)
          .collection('snapshots')
          .orderBy('timestamp')
          .get();

      return snapshotsQuery.docs.map((doc) {
        final data = doc.data();
        return EmotionSnapshot.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting snapshots: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PREMIUM STATUS
  // ═══════════════════════════════════════════════════════════════

  /// Simpan status premium ke Firestore user document
  static Future<void> updatePremiumStatus(bool isPremium, DateTime? expiry) async {
    final docRef = _userDoc;
    if (docRef == null) return;

    try {
      await docRef.set({
        'is_premium': isPremium,
        'premium_expiry': expiry != null ? Timestamp.fromDate(expiry) : null,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating premium status: $e');
    }
  }

  /// Load premium status dari Firestore
  /// Returns (isPremium, expiryDate)
  static Future<({bool isPremium, DateTime? expiry})> loadPremiumStatus() async {
    final docRef = _userDoc;
    if (docRef == null) return (isPremium: false, expiry: null);

    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) return (isPremium: false, expiry: null);

      final data = snapshot.data() as Map<String, dynamic>;
      final isPremium = data['is_premium'] as bool? ?? false;
      DateTime? expiry;
      if (data['premium_expiry'] != null) {
        expiry = (data['premium_expiry'] as Timestamp).toDate();
      }
      return (isPremium: isPremium, expiry: expiry);
    } catch (e) {
      debugPrint('Error loading premium status: $e');
      return (isPremium: false, expiry: null);
    }
  }

  /// Reset instance (untuk logout - dipanggil oleh AuthProvider)
  static void resetInstance() {
    // Tidak perlu apa-apa di Firestore, cukup sign out Firebase Auth
    debugPrint('DatabaseService reset (no-op for Firestore)');
  }

  /// Hapus semua data user dari Firestore (pengganti deleteDatabase SQLite)
  static Future<void> deleteDatabase() async {
    try {
      final docRef = _userDoc;
      if (docRef == null) return;

      // Hapus semua recordings beserta snapshots
      final recordings = await docRef.collection('recordings').get();
      for (final rec in recordings.docs) {
        // Hapus snapshots di bawah recording
        final snapshots = await rec.reference.collection('snapshots').get();
        for (final snap in snapshots.docs) {
          await snap.reference.delete();
        }
        await rec.reference.delete();
      }

      // Hapus dokumen user itu sendiri
      await docRef.delete();

      debugPrint('Firestore user data deleted successfully');
    } catch (e) {
      debugPrint('Error deleting Firestore data: $e');
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
  });

  /// Factory dari Firestore document
  factory RecordingData.fromFirestore(String docId, Map<String, dynamic> data) {
    final audioMap = data['audio_emotions'] as Map<String, dynamic>? ?? {};
    final textMap = data['transcript_emotions'] as Map<String, dynamic>? ?? {};

    // Handle date — bisa Timestamp atau String
    DateTime dateValue;
    if (data['date'] is Timestamp) {
      dateValue = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      dateValue = DateTime.parse(data['date'] as String);
    } else {
      dateValue = DateTime.now();
    }

    return RecordingData(
      id: docId.hashCode,
      userId: 0, // userId tidak relevan di Firestore (sudah implicit dari path)
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
            (e) => e.name == k,
            orElse: () => EmotionType.neutral,
          ),
          (v as num).toDouble(),
        ),
      ),
      transcriptEmotions: textMap.map(
        (k, v) => MapEntry(
          EmotionType.values.firstWhere(
            (e) => e.name == k,
            orElse: () => EmotionType.neutral,
          ),
          (v as num).toDouble(),
        ),
      ),
      transcriptText: data['transcript_text'] as String? ?? '',
      durationSeconds: (data['duration_seconds'] as num?)?.toInt() ?? 0,
      triggerTag: data['trigger_tag'] as String? ?? '',
    );
  }

  /// Backward compat: fromMap (untuk kode lama yang mungkin masih memanggilnya)
  factory RecordingData.fromMap(Map<String, dynamic> map) {
    return RecordingData.fromFirestore(
      map['id']?.toString() ?? '',
      map,
    );
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

  /// Factory dari Firestore document
  factory EmotionSnapshot.fromFirestore(String docId, Map<String, dynamic> data) {
    DateTime timestampValue;
    if (data['timestamp'] is Timestamp) {
      timestampValue = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      timestampValue = DateTime.parse(data['timestamp'] as String);
    } else {
      timestampValue = DateTime.now();
    }

    return EmotionSnapshot(
      id: docId.hashCode,
      emotion: EmotionType.values.firstWhere(
        (e) => e.name == data['emotion'],
        orElse: () => EmotionType.neutral,
      ),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      source: data['source'] as String? ?? 'combined',
      timestamp: timestampValue,
    );
  }

  /// Backward compat: fromMap
  factory EmotionSnapshot.fromMap(Map<String, dynamic> map) {
    return EmotionSnapshot.fromFirestore(
      map['id']?.toString() ?? '',
      map,
    );
  }
}
