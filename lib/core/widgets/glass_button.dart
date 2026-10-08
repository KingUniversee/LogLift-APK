import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'glass_card.dart';

enum GlassButtonVariant { primary, secondary, destructive, ghost }

class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.primary,
    this.isLoading = false,
    this.height = 52,
    this.width,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlassButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    Gradient? gradient;
    Color? backgroundColor;
    Color textColor = Colors.white;
    Color? borderColor;

    switch (variant) {
      case GlassButtonVariant.primary:
        gradient = enabled ? AppColors.buttonGradient : null;
        backgroundColor = enabled ? null : Colors.white.withValues(alpha: 0.1);
        textColor = enabled ? Colors.white : AppColors.textMuted;
        borderColor = AppColors.borderGlassHighlight;
        break;
      case GlassButtonVariant.secondary:
        backgroundColor = AppColors.surfaceGlass;
        textColor = AppColors.textPrimary;
        borderColor = AppColors.borderGlass;
        break;
      case GlassButtonVariant.destructive:
        backgroundColor = AppColors.accentRose.withValues(alpha: 0.15);
        textColor = AppColors.accentRose;
        borderColor = AppColors.accentRose.withValues(alpha: 0.3);
        break;
      case GlassButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primaryLight;
        borderColor = Colors.transparent;
        break;
    }

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        gradient: gradient,
        tintColor: backgroundColor,
        borderColor: borderColor,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
