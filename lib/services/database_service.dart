import 'dart:convert';
import 'dart:io' show Platform;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/emotion_model.dart';
import '../models/user_model.dart';

// Initialize FFI for desktop platforms - only once
bool _isFfiInitialized = false;
void _initDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    if (!_isFfiInitialized) {
      sqfliteFfiInit();
      _isFfiInitialized = true;
    }
    // Use factoryFfi directly without changing global databaseFactory
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DatabaseService — SQLite local persistence
//
// Tabel:
//   • users            — Data user + hasil MBTI
//   • recordings       — Data recording lengkap
//   • emotion_snapshots — Snapshot emosi per 3 detik
// ─────────────────────────────────────────────────────────────────────────────
class DatabaseService {
  static Database? _db;
  static const String _dbName = 'fem_physics.db';
  static const int _dbVersion = 2; // Naik ke versi 2 untuk migrasi psych_score

  /// Singleton database instance
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    _initDatabaseFactory();

    // Use appropriate factory for getting database path
    final dbPath = (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        ? await databaseFactoryFfi.getDatabasesPath()
        : await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Use databaseFactoryFfi for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ── Tabel users ──
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mbti_type TEXT NOT NULL DEFAULT '',
        mbti_scores TEXT NOT NULL DEFAULT '{}',
        psych_score INTEGER DEFAULT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // ── Tabel recordings ──
    await db.execute('''
      CREATE TABLE recordings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        dominant_emotion TEXT NOT NULL,
        confidence REAL NOT NULL DEFAULT 0.0,
        suggestion TEXT NOT NULL DEFAULT '',
        audio_emotions TEXT NOT NULL DEFAULT '{}',
        transcript_emotions TEXT NOT NULL DEFAULT '{}',
        transcript_text TEXT NOT NULL DEFAULT '',
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // ── Tabel emotion_snapshots ──
    await db.execute('''
      CREATE TABLE emotion_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recording_id INTEGER NOT NULL,
        emotion TEXT NOT NULL,
        confidence REAL NOT NULL DEFAULT 0.0,
        source TEXT NOT NULL DEFAULT 'combined',
        timestamp TEXT NOT NULL,
        FOREIGN KEY (recording_id) REFERENCES recordings (id) ON DELETE CASCADE
      )
    ''');
  }

  // Migration handler untuk database yang sudah ada
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Jika oldVersion < 2, tambahkan kolom psych_score
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN psych_score INTEGER DEFAULT NULL',
        );
      } catch (e) {
        // Abaikan error jika kolom sudah ada
        print('Migration warning: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Simpan user baru, return user id
  static Future<int> insertUser(AppUser user) async {
    final db = await database;
    return db.insert('users', {
      'name': user.name,
      'mbti_type': user.mbtiType,
      'mbti_scores': jsonEncode(user.mbtiScores),
      'psych_score': user.psychologicalScore,
      'created_at': user.createdAt.toIso8601String(),
    });
  }

  /// Ambil user pertama (single-user app)
  static Future<AppUser?> getUser() async {
    final db = await database;
    final result = await db.query('users', limit: 1, orderBy: 'id DESC');
    if (result.isEmpty) return null;

    final row = result.first;
    return AppUser(
      id: row['id'] as int?,
      name: row['name'] as String,
      mbtiType: row['mbti_type'] as String,
      mbtiScores: Map<String, int>.from(
        jsonDecode(row['mbti_scores'] as String) as Map,
      ),
      psychologicalScore: row['psych_score'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Update user data
  static Future<void> updateUser(AppUser user) async {
    final db = await database;
    await db.update('users', {
      'name': user.name,
      'mbti_type': user.mbtiType,
      'mbti_scores': jsonEncode(user.mbtiScores),
    }, where: 'id = (SELECT MAX(id) FROM users)');
  }

  // ═══════════════════════════════════════════════════════════════
  // RECORDING CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Simpan recording baru, return recording id
  static Future<int> insertRecording(RecordingData recording) async {
    final db = await database;
    return db.insert('recordings', {
      'user_id': recording.userId,
      'date': recording.date.toIso8601String(),
      'dominant_emotion': recording.dominantEmotion.name,
      'confidence': recording.confidence,
      'suggestion': recording.suggestion,
      'audio_emotions': jsonEncode(
        recording.audioEmotions.map((k, v) => MapEntry(k.name, v)),
      ),
      'transcript_emotions': jsonEncode(
        recording.transcriptEmotions.map((k, v) => MapEntry(k.name, v)),
      ),
      'transcript_text': recording.transcriptText,
      'duration_seconds': recording.durationSeconds,
    });
  }

  /// Ambil semua recordings
  static Future<List<RecordingData>> getRecordings({int? userId}) async {
    final db = await database;
    final result = await db.query(
      'recordings',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'date DESC',
    );

    return result.map((row) => RecordingData.fromMap(row)).toList();
  }

  /// Ambil recording by id
  static Future<RecordingData?> getRecording(int id) async {
    final db = await database;
    final result = await db.query(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return RecordingData.fromMap(result.first);
  }

  // ═══════════════════════════════════════════════════════════════
  // EMOTION SNAPSHOT CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Simpan batch snapshots untuk satu recording
  static Future<void> insertSnapshots(
    int recordingId,
    List<EmotionSnapshot> snapshots,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final snap in snapshots) {
      batch.insert('emotion_snapshots', {
        'recording_id': recordingId,
        'emotion': snap.emotion.name,
        'confidence': snap.confidence,
        'source': snap.source,
        'timestamp': snap.timestamp.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  /// Ambil snapshots untuk recording tertentu
  static Future<List<EmotionSnapshot>> getSnapshots(int recordingId) async {
    final db = await database;
    final result = await db.query(
      'emotion_snapshots',
      where: 'recording_id = ?',
      whereArgs: [recordingId],
      orderBy: 'timestamp ASC',
    );

    return result.map((row) => EmotionSnapshot.fromMap(row)).toList();
  }

  /// Hapus database (untuk reset/testing)
  static Future<void> deleteDatabase() async {
    // Use appropriate factory for getting database path
    final dbPath = (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        ? await databaseFactoryFfi.getDatabasesPath()
        : await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Use appropriate factory for deletion
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await databaseFactoryFfi.deleteDatabase(path);
    } else {
      await databaseFactory.deleteDatabase(path);
    }
    _db = null;
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
  });

  factory RecordingData.fromMap(Map<String, dynamic> map) {
    final audioMap = jsonDecode(map['audio_emotions'] as String) as Map;
    final textMap = jsonDecode(map['transcript_emotions'] as String) as Map;

    return RecordingData(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      date: DateTime.parse(map['date'] as String),
      dominantEmotion: EmotionType.values.firstWhere(
        (e) => e.name == map['dominant_emotion'],
        orElse: () => EmotionType.neutral,
      ),
      confidence: (map['confidence'] as num).toDouble(),
      suggestion: map['suggestion'] as String,
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
      transcriptText: map['transcript_text'] as String,
      durationSeconds: map['duration_seconds'] as int,
    );
  }

  /// Convert ke EmotionRecord untuk kompatibilitas UI
  EmotionRecord toEmotionRecord() {
    return EmotionRecord(
      emotion: dominantEmotion,
      confidence: confidence,
      timestamp: date,
      recordingId: id,
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

  factory EmotionSnapshot.fromMap(Map<String, dynamic> map) {
    return EmotionSnapshot(
      id: map['id'] as int?,
      recordingId: map['recording_id'] as int?,
      emotion: EmotionType.values.firstWhere(
        (e) => e.name == map['emotion'],
        orElse: () => EmotionType.neutral,
      ),
      confidence: (map['confidence'] as num).toDouble(),
      source: map['source'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
