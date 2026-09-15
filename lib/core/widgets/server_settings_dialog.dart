import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../network/api_config.dart';

Future<void> showServerSettingsDialog(
  BuildContext context, {
  VoidCallback? onSaved,
}) async {
  final controller = TextEditingController(text: ApiConfig.baseUrl);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderGlassHighlight),
      ),
      title: const Text(
        'Backend Server URL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configure the REST API endpoint (e.g. http://192.168.1.X:5000/api for physical devices or http://localhost:5000/api for simulator):',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'http://localhost:5000/api',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderGlass),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () async {
            final newUrl = controller.text.trim();
            if (newUrl.isNotEmpty) {
              await ApiConfig.setCustomBaseUrl(newUrl);
            }
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server URL updated to: ${ApiConfig.baseUrl}'),
                  backgroundColor: AppColors.surfaceGlass,
                ),
              );
            }
            onSaved?.call();
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
