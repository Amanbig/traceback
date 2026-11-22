import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/threat_report.dart';

class PdfDossierService {
  /// Generates and initiates printing / downloading of the Forensic Dossier PDF
  static Future<void> exportReportDossier(ThreatReport report) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss UTC');
    final formattedDate = dateFormat.format(report.createdAt.toUtc());

    // Generate SHA-256 Chain of Custody Checksum
    final evidenceBytes = utf8.encode(report.originalSnippet);
    final sha256Hash = sha256.convert(evidenceBytes).toString();
    final dossierId =
        'TRC-${report.createdAt.year}-${report.id.length >= 8 ? report.id.substring(0, 8).toUpperCase() : report.id.toUpperCase()}';

    final riskColor = report.riskScore >= 75
        ? PdfColors.red900
        : report.riskScore >= 40
            ? PdfColors.orange800
            : PdfColors.green800;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Official Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E293B),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TRACEBACK FORENSIC INCIDENT DOSSIER',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'DIGITAL FRAUD & SOCIAL ENGINEERING INVESTIGATION',
                        style: const pw.TextStyle(
                          color: PdfColors.grey400,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: riskColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      '${report.threatLevel.name.toUpperCase()} RISK (${report.riskScore}%)',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 2. Metadata Grid
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildMetaRow('Dossier Reference ID:', dossierId),
                      ),
                      pw.Expanded(
                        child: _buildMetaRow('Audit Timestamp:', formattedDate),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildMetaRow('Inference Engine:',
                            report.isLocalInference ? 'Gemini Nano (On-Device)' : 'Gemini 1.5 Flash (Cloud AI)'),
                      ),
                      pw.Expanded(
                        child: _buildMetaRow('PII Protection:', 'Zero-Leakage Local Scrubbing Active'),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  _buildMetaRow('Chain of Custody SHA-256:', sha256Hash),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 3. Executive Threat Summary
            pw.Text(
              'EXECUTIVE FRAUD ANALYSIS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                report.summary,
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.3),
              ),
            ),
            pw.SizedBox(height: 14),

            // 4. Scrubbed Forensic Evidence Transcript
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'INTERCEPTED EVIDENCE (PII SCRUBBED)',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
                pw.Text(
                  '[CONFIDENTIAL - ALL PII REDACTED ON-DEVICE]',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                color: const PdfColor.fromInt(0xFFF1F5F9),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                report.maskedSnippet,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  font: pw.Font.courier(),
                  lineSpacing: 1.2,
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // 5. Red Flags & Psychological Traps
            pw.Text(
              'FORENSIC ATTACK MARKERS & PSYCHOLOGICAL TRAPS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 6),
            ...report.redFlags.map((flag) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 10,
                        height: 10,
                        margin: const pw.EdgeInsets.only(top: 2, right: 6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.red800,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          flag,
                          style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 14),

            // 6. Actionable Safe Next Steps
            pw.Text(
              'STATUTORY MITIGATION & CONTAINMENT CHECKLIST',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 6),
            ...report.safeNextSteps.map((step) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 10,
                        height: 10,
                        margin: const pw.EdgeInsets.only(top: 2, right: 6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.green800,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          step,
                          style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 16),

            // 7. Police / Bank Dispute Formal Declaration Block
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ANNEXURE: STATUTORY FRAUD COMPLAINT & CHARGEBACK FILING',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'This document serves as technical evidence of an attempted or executed cyber fraud incident for submission to:\n'
                    '• National Cyber Crime Reporting Portal (Dial 1930 / https://cybercrime.gov.in)\n'
                    '• Bank Fraud Dispute & Chargeback Department (Under RBI/Regulatory Zero-Liability Policy)\n'
                    '• Local Cyber Crime Police Station for First Information Report (FIR) registration.',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800, lineSpacing: 1.2),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Complainant Signature: _______________________',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Investigating Officer / Bank Stamp: _______________________',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Footer
            pw.Center(
              child: pw.Text(
                'Generated automatically by Traceback Hybrid AI Forensic Shield • https://gem-app-2adf0.web.app',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    // Launch print / download dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Traceback_Forensic_Dossier_$dossierId.pdf',
    );
  }

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label ',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }
}
