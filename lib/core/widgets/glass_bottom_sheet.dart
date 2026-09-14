import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassBottomSheet(child: builder(context)),
  );
}

class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1322).withValues(alpha: 0.88),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: AppColors.borderGlassHighlight, width: 1.2),
            left: BorderSide(color: AppColors.borderGlass),
            right: BorderSide(color: AppColors.borderGlass),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
