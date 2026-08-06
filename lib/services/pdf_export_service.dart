import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'database_service.dart';

class PdfExportService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<pw.Font> _getRegularFont() async {
    if (_regularFont == null) {
      final data = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      _regularFont = pw.Font.ttf(data);
    }
    return _regularFont!;
  }

  static Future<pw.Font> _getBoldFont() async {
    if (_boldFont == null) {
      final data = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
      _boldFont = pw.Font.ttf(data);
    }
    return _boldFont!;
  }

  static Future<pw.TextStyle> _style({
    double fontSize = 12,
    PdfColor? color,
    bool bold = false,
  }) async {
    return pw.TextStyle(
      font: bold ? await _getBoldFont() : await _getRegularFont(),
      fontSize: fontSize,
      color: color,
    );
  }

  static Future<Uint8List> generateAllUsersReport(
    List<Map<String, dynamic>> users,
  ) async {
    final pdf = pw.Document();
    final headerStyle = await _style(fontSize: 22, bold: true);
    final countStyle = await _style(fontSize: 14);
    final dateStyle = await _style(fontSize: 12);
    final sectionHeader = await _style(fontSize: 16, bold: true);
    final bodyStyle = await _style(fontSize: 13);
    final mutedStyle = await _style(fontSize: 12, color: PdfColors.grey600);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Laporan Pengguna - Fem Psych Monitor', style: headerStyle),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Pengguna: ${users.length}', style: countStyle),
          pw.SizedBox(height: 10),
          pw.Text('Tanggal: ${DateTime.now().toString().split('.')[0]}', style: dateStyle),
          pw.SizedBox(height: 20),
          ...users.map((user) => _buildUserSection(user, sectionHeader, bodyStyle, mutedStyle)),
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
    final headerStyle = await _style(fontSize: 22, bold: true);
    final sectionStyle = await _style(fontSize: 16, bold: true);
    final nameStyle = await _style(fontSize: 16, bold: true);
    final bodyStyle = await _style(fontSize: 13);
    final mutedStyle = await _style(fontSize: 12, color: PdfColors.grey600);
    final recLabelStyle = await _style(fontSize: 12, bold: true);
    final recBodyStyle = await _style(fontSize: 11);
    final recMutedStyle = await _style(fontSize: 11, color: PdfColors.grey600);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Laporan Pengguna - Fem Psych Monitor', style: headerStyle),
          ),
          pw.SizedBox(height: 20),
          _buildUserHeader(userData, nameStyle, bodyStyle, mutedStyle),
          pw.SizedBox(height: 20),
          if (userData['psych_score'] != null) ...[
            pw.Header(level: 1, child: pw.Text('Kesehatan Mental', style: sectionStyle)),
            pw.Text('Skor Psikologis: ${userData['psych_score']}', style: bodyStyle),
            pw.Text('Kategori: ${_getCategory(userData['psych_score'] as int?)}', style: bodyStyle),
            pw.SizedBox(height: 10),
          ],
          if (recordings.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('Riwayat Rekaman (${recordings.length})', style: sectionStyle)),
            ...recordings.map((rec) => _buildRecordingItem(rec, recLabelStyle, recBodyStyle, recMutedStyle)),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildUserHeader(
    Map<String, dynamic> user,
    pw.TextStyle nameStyle,
    pw.TextStyle bodyStyle,
    pw.TextStyle mutedStyle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Nama: ${user['name'] ?? '-'}', style: nameStyle),
        pw.Text('Email: ${user['email'] ?? '-'}', style: bodyStyle),
        pw.SizedBox(height: 8),
        if (user['created_at'] != null)
          pw.Text('Bergabung: ${_formatDate(user['created_at'])}', style: mutedStyle),
      ],
    );
  }

  static pw.Widget _buildUserSection(
    Map<String, dynamic> user,
    pw.TextStyle sectionHeader,
    pw.TextStyle bodyStyle,
    pw.TextStyle mutedStyle,
  ) {
    final nameStyle = sectionHeader;
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
          _buildUserHeader(user, nameStyle, bodyStyle, mutedStyle),
          pw.SizedBox(height: 12),
          pw.Text('Skor Mental: ${user['psych_score'] ?? 'Belum dinilai'}', style: bodyStyle),
          pw.Divider(),
        ],
      ),
    );
  }

  static pw.Widget _buildRecordingItem(
    RecordingData rec,
    pw.TextStyle labelStyle,
    pw.TextStyle bodyStyle,
    pw.TextStyle mutedStyle,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8, left: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Emosi: ${rec.dominantEmotion.name}', style: labelStyle),
              pw.Text('${rec.durationSeconds}s', style: bodyStyle),
            ],
          ),
          pw.Text(
            '${rec.date.day}/${rec.date.month}/${rec.date.year} ${rec.date.hour}:${rec.date.minute.toString().padLeft(2, '0')}',
            style: mutedStyle,
          ),
          if (rec.transcriptText.isNotEmpty)
            pw.Text(rec.transcriptText, style: bodyStyle),
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
