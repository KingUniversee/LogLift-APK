import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'glass_button.dart';
import 'glass_card.dart';

class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.fitness_center_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(compact ? 20 : 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 52 : 72,
              height: compact ? 52 : 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 34,
                color: AppColors.primaryLight,
              ),
            ),
            SizedBox(height: compact ? 14 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 16 : 24),
              GlassButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.add_rounded,
                variant: GlassButtonVariant.primary,
                height: 46,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
