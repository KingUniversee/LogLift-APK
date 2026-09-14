import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'report_service.dart';

class PdfExportService {
  const PdfExportService();

  Future<Uint8List> generateReportPdf(ReportData report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Workout Log Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        report.title,
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        report.dateRangeLabel,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Generated: ${DateTime.now().toString().substring(0, 16)}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Summary Stats Table
              pw.Text(
                'Performance Summary',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _tableCell('Metric', isHeader: true),
                      _tableCell('Value', isHeader: true),
                      _tableCell('Metric', isHeader: true),
                      _tableCell('Value', isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Completed Workouts'),
                      _tableCell('${report.workoutCount}'),
                      _tableCell('Total Volume'),
                      _tableCell('${report.volume.toStringAsFixed(0)} kg'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Total Sets'),
                      _tableCell('${report.sets}'),
                      _tableCell('Total Reps'),
                      _tableCell('${report.reps}'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Total Duration'),
                      _tableCell('${report.durationMinutes} min'),
                      _tableCell('Personal Records'),
                      _tableCell('${report.prs.length}'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Muscle Distribution if available
              if (report.muscleDistribution.isNotEmpty) ...[
                pw.Text(
                  'Muscle Group Distribution',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: report.muscleDistribution.entries.map((e) {
                    return pw.Text(
                      '${e.key.displayName}: ${e.value.toStringAsFixed(1)}%',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 18),
              ],

              // Workouts in this period
              pw.Text(
                'Workouts Logged (${report.sessions.length})',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              if (report.sessions.isEmpty)
                pw.Text('No workouts recorded in this period.',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _tableCell('Date', isHeader: true),
                        _tableCell('Workout', isHeader: true),
                        _tableCell('Duration', isHeader: true),
                        _tableCell('Sets', isHeader: true),
                        _tableCell('Volume', isHeader: true),
                      ],
                    ),
                    ...report.sessions.map((s) {
                      final date = '${s.startedAt.month}/${s.startedAt.day}/${s.startedAt.year}';
                      return pw.TableRow(
                        children: [
                          _tableCell(date),
                          _tableCell(s.planName),
                          _tableCell('${s.durationMinutes} min'),
                          _tableCell('${s.completedSets}'),
                          _tableCell('${s.totalVolume.toStringAsFixed(0)} kg'),
                        ],
                      );
                    }),
                  ],
                ),

              // PRs Achieved if any
              if (report.prs.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Personal Records Achieved',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                ...report.prs.map((pr) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '• ${pr.exerciseName}: ${pr.recordType.displayName} - ${pr.value.toStringAsFixed(1)} ${pr.recordType.defaultUnit}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                  );
                }),
              ],

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Workout Log · Offline First', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> shareReportPdf(ReportData report) async {
    final pdfBytes = await generateReportPdf(report);
    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/Workout_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${report.title} - ${report.dateRangeLabel}',
    );
  }

  Future<void> printOrSavePdf(ReportData report) async {
    final pdfBytes = await generateReportPdf(report);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${report.title}_${report.dateRangeLabel}.pdf',
    );
  }
}
