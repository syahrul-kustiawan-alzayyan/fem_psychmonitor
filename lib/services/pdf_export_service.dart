import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'database_service.dart';

class PdfExportService {
  static Future<Uint8List> generateAllUsersReport(
    List<Map<String, dynamic>> users,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Laporan Pengguna - Fem Psych Monitor',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Pengguna: ${users.length}',
              style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Text('Tanggal: ${DateTime.now().toString().split('.')[0]}',
              style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          ...users.map((user) => _buildUserSection(user)),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateUserReport(
    Map<String, dynamic> userData,
    List<RecordingData> recordings,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Laporan Pengguna - Fem Psych Monitor',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          _buildUserHeader(userData),
          pw.SizedBox(height: 20),
          if (userData['psych_score'] != null) ...[
            pw.Header(level: 1, child: pw.Text('Kesehatan Mental')),
            pw.Text('Skor Psikologis: ${userData['psych_score']}'),
            pw.Text('Kategori: ${_getCategory(userData['psych_score'] as int?)}'),
            pw.SizedBox(height: 10),
          ],
          if (recordings.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('Riwayat Rekaman (${recordings.length})')),
            ...recordings.map((rec) => _buildRecordingItem(rec)),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildUserHeader(Map<String, dynamic> user) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Nama: ${user['name'] ?? '-'}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text('Email: ${user['email'] ?? '-'}',
            style: pw.TextStyle(fontSize: 13)),
        pw.Text('MBTI: ${user['mbti_type'] ?? '-'}',
            style: pw.TextStyle(fontSize: 13)),
        pw.SizedBox(height: 8),
        if (user['created_at'] != null)
          pw.Text('Bergabung: ${_formatDate(user['created_at'])}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildUserSection(Map<String, dynamic> user) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildUserHeader(user),
          pw.SizedBox(height: 12),
          pw.Text('Skor Mental: ${user['psych_score'] ?? 'Belum dinilai'}',
              style: pw.TextStyle(fontSize: 13)),
          pw.Divider(),
        ],
      ),
    );
  }

  static pw.Widget _buildRecordingItem(RecordingData rec) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8, left: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Emosi: ${rec.dominantEmotion.name}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('${rec.durationSeconds}s',
                  style: pw.TextStyle(fontSize: 11)),
            ],
          ),
          pw.Text('${rec.date.day}/${rec.date.month}/${rec.date.year} ${rec.date.hour}:${rec.date.minute.toString().padLeft(2, '0')}',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          if (rec.transcriptText.isNotEmpty)
            pw.Text(rec.transcriptText,
                style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static String _getCategory(int? score) {
    if (score == null) return 'Belum Dinilai';
    if (score >= 76) return 'Sehat Optimal';
    if (score >= 51) return 'Cukup';
    if (score >= 26) return 'Rentan';
    return 'Butuh Perhatian Klinis';
  }

  static String _formatDate(dynamic ts) {
    if (ts == null) return '-';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else {
      dt = DateTime.now();
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
