import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({required this.child, this.padding = const EdgeInsets.all(18), this.onTap, super.key});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
    return onTap == null ? content : InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: content);
  }
}

class GlassStat extends StatelessWidget {
  const GlassStat({required this.label, required this.value, required this.icon, super.key});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white60)),
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, super.key});

  final String title;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (action != null) TextButton(onPressed: action, child: const Text('See all')),
      ]);
}
