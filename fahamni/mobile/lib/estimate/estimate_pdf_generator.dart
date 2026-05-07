import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'estimate_model.dart';

class EstimatePdfGenerator {
  // ── Colors matching the template ──────────────────────────────────────────
  static final _navy = PdfColor.fromHex('#000080');
  static final _sectionHeaderBg = PdfColor.fromHex('#0F1F6E');
  static final _colHeaderBg = PdfColor.fromHex('#1E3A8A');
  static final _totalRowBg = PdfColor.fromHex('#070D33');
  static final _borderColor = PdfColor.fromHex('#D1D5DB');
  static final _bodyText = PdfColor.fromHex('#1F2937');
  static final _labelText = PdfColor.fromHex('#6B7280');
  static final _rowAlt = PdfColor.fromHex('#F9FAFB');

  static Future<Uint8List> generate(EstimateData data) async {
    final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final bold = pw.Font.helveticaBold();
    final normal = pw.Font.helvetica();

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(logo, data, bold, normal),
            pw.SizedBox(height: 6),
            _infoBar(data, bold, normal),
            pw.SizedBox(height: 14),
            _parties(data, bold, normal),
            pw.SizedBox(height: 14),
            _serviceDetails(data, bold, normal),
            pw.SizedBox(height: 14),
            _pricing(data, bold, normal),
            pw.Spacer(),
            _footer(data, normal),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  static pw.Widget _header(
    pw.MemoryImage logo,
    EstimateData data,
    pw.Font bold,
    pw.Font normal,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(logo, width: 48, height: 48),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Fahamni',
              style: pw.TextStyle(
                font: bold,
                fontSize: 22,
                color: _navy,
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'ESTIMATE',
              style: pw.TextStyle(
                font: bold,
                fontSize: 28,
                color: _bodyText,
                letterSpacing: 1.5,
              ),
            ),
            pw.Text(
              'No. ${data.invoiceNumber}',
              style: pw.TextStyle(
                font: normal,
                fontSize: 11,
                color: _labelText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Info bar (platform name + date) ────────────────────────────────────────
  static pw.Widget _infoBar(
    EstimateData data,
    pw.Font bold,
    pw.Font normal,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _borderColor, width: 0.5),
          bottom: pw.BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Student–Teacher Tutoring Platform',
            style: pw.TextStyle(font: normal, fontSize: 10, color: _labelText),
          ),
          pw.Text(
            'Date: ${DateFormat('MMMM d, y').format(data.date)}',
            style: pw.TextStyle(font: normal, fontSize: 10, color: _labelText),
          ),
        ],
      ),
    );
  }

  // ── Parties section (Student | Teacher) ────────────────────────────────────
  static pw.Widget _parties(
    EstimateData data,
    pw.Font bold,
    pw.Font normal,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _partyBox(
            title: 'STUDENT (Sender)',
            rows: [
              ['Full name', data.studentName],
              ['Email', data.studentEmail],
              ['Phone', data.studentPhone.isNotEmpty ? data.studentPhone : '—'],
              ['Level', data.studentLevel.isNotEmpty ? data.studentLevel : '—'],
            ],
            bold: bold,
            normal: normal,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _partyBox(
            title: 'TEACHER (Recipient)',
            rows: [
              ['Full name', data.teacherName],
              ['Email', data.teacherEmail],
              ['Phone', data.teacherPhone.isNotEmpty ? data.teacherPhone : '—'],
              ['Subject', data.subject],
            ],
            bold: bold,
            normal: normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _partyBox({
    required String title,
    required List<List<String>> rows,
    required pw.Font bold,
    required pw.Font normal,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: _sectionHeaderBg,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
            ),
          ),
          ...rows.map(
            (row) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _borderColor, width: 0.3),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 68,
                    child: pw.Text(
                      '${row[0]} :',
                      style: pw.TextStyle(
                        font: normal,
                        fontSize: 9,
                        color: _labelText,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      row[1],
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 9,
                        color: _bodyText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Service Details table ──────────────────────────────────────────────────
  static pw.Widget _serviceDetails(
    EstimateData data,
    pw.Font bold,
    pw.Font normal,
  ) {
    final columns = [
      _ColDef('Description', 3),
      _ColDef('Subject', 2),
      _ColDef('Teaching Mode', 2),
      _ColDef('Sessions', 1),
      _ColDef('Duration /\nSession', 1),
    ];

    final values = [
      data.description.isNotEmpty ? data.description : 'Private tutoring — ${data.subject}',
      data.subject,
      data.teachingMode,
      data.sessionsCount.toString(),
      data.sessionDuration,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('SERVICE DETAILS', bold),
        pw.Table(
          border: pw.TableBorder.all(color: _borderColor, width: 0.4),
          columnWidths: {
            for (int i = 0; i < columns.length; i++)
              i: pw.FlexColumnWidth(columns[i].flex.toDouble()),
          },
          children: [
            _tableHeaderRow(columns.map((c) => c.label).toList(), bold),
            pw.TableRow(
              children: values
                  .map(
                    (v) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: pw.Text(
                        v,
                        style: pw.TextStyle(
                          font: normal,
                          fontSize: 9,
                          color: _bodyText,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  // ── Pricing table ──────────────────────────────────────────────────────────
  static pw.Widget _pricing(
    EstimateData data,
    pw.Font bold,
    pw.Font normal,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('PRICING', bold),
        pw.Table(
          border: pw.TableBorder.all(color: _borderColor, width: 0.4),
          children: [
            _tableHeaderRow(
              ['Sessions', 'Duration', 'Price / Session', 'Total Price'],
              bold,
            ),
            pw.TableRow(
              children: [
                data.sessionsCount.toString(),
                data.sessionDuration,
                data.formattedPrice,
                data.formattedTotal,
              ]
                  .map(
                    (v) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: pw.Text(
                        v,
                        style: pw.TextStyle(
                          font: normal,
                          fontSize: 9,
                          color: _bodyText,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        // Total amount row
        pw.Container(
          color: _totalRowBg,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL AMOUNT :',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 12,
                  color: PdfColors.white,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Text(
                data.formattedTotal,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 16,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  static pw.Widget _footer(EstimateData data, pw.Font normal) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(color: _borderColor, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Fahamni — Mobile Tutoring Application',
              style: pw.TextStyle(
                font: normal,
                fontSize: 8,
                color: _labelText,
              ),
            ),
            pw.Text(
              'www.fahamni.app | contact@fahamni.app',
              style: pw.TextStyle(
                font: normal,
                fontSize: 8,
                color: _labelText,
              ),
            ),
            pw.Text(
              data.invoiceNumber,
              style: pw.TextStyle(
                font: normal,
                fontSize: 8,
                color: _labelText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static pw.Widget _sectionHeader(String title, pw.Font bold) {
    return pw.Container(
      color: _sectionHeaderBg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: bold,
          fontSize: 10,
          color: PdfColors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> labels, pw.Font bold) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _colHeaderBg),
      children: labels
          .map(
            (l) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              child: pw.Text(
                l,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ColDef {
  const _ColDef(this.label, this.flex);
  final String label;
  final int flex;
}
