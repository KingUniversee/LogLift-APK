import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/app_providers.dart';
import '../../services/report_service.dart';

class ShareReportModal extends ConsumerWidget {
  const ShareReportModal({required this.report, super.key});

  final ReportData report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = ref.watch(pdfExportServiceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Report Preview Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.assessment_rounded, color: AppColors.primaryLight, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.dateRangeLabel,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Export as PDF Button
          GlassButton(
            label: 'Export as PDF',
            icon: Icons.picture_as_pdf_rounded,
            onPressed: () async {
              Navigator.pop(context);
              await pdfService.printOrSavePdf(report);
            },
          ),
          const SizedBox(height: 12),

          // Share via Native iOS Share Sheet
          GlassButton(
            label: 'Share via iOS Share Sheet',
            icon: Icons.ios_share_rounded,
            variant: GlassButtonVariant.secondary,
            onPressed: () async {
              Navigator.pop(context);
              await pdfService.shareReportPdf(report);
            },
          ),
          const SizedBox(height: 12),

          // Save to Files
          GlassButton(
            label: 'Save to Files',
            icon: Icons.folder_open_rounded,
            variant: GlassButtonVariant.secondary,
            onPressed: () async {
              Navigator.pop(context);
              await pdfService.printOrSavePdf(report);
            },
          ),
          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
