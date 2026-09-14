import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'glass_card.dart';

class GlassStatCard extends StatelessWidget {
  const GlassStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trend,
    this.isPositiveTrend = true,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? trend;
  final bool isPositiveTrend;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primaryLight;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: effectiveIconColor),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend ? AppColors.accentGreen : AppColors.accentRose)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPositiveTrend ? AppColors.accentGreen : AppColors.accentRose,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
