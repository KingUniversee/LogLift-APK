import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 22,
    this.blur = 20,
    this.tintColor,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? tintColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor ?? (gradient == null ? AppColors.surfaceGlass : null),
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.borderGlass,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
