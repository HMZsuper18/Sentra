import 'package:flutter/material.dart';
import '../core/constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      color: Colors.white.withValues(alpha: 0.07),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40),
        BoxShadow(color: c1.withValues(alpha: 0.09), blurRadius: 60, spreadRadius: 10),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.13),
          Colors.white.withValues(alpha: 0.03),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.04),
        ],
        stops: const [0.0, 0.35, 0.6, 1.0],
      ),
    ),
    child: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}