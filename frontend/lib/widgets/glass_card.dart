import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SAMsTheme.border),
      ),
      child: child,
    );
  }
}
