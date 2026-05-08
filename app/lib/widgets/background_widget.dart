import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class BackgroundWidget extends StatelessWidget {
  final List<AnimationController> orbCtrl;

  const BackgroundWidget({super.key, required this.orbCtrl});

  @override
  Widget build(BuildContext context) {
    final orbs = [
      (c1.withValues(alpha: 0.45), 500.0, -150.0, -150.0, false, false),
      (c2.withValues(alpha: 0.40), 420.0, -100.0, -100.0, true, false),
      (c3.withValues(alpha: 0.35), 320.0, 40.0, 0.0, false, true),
      (c4.withValues(alpha: 0.28), 260.0, 80.0, 80.0, true, true),
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.4,
              colors: [cardBg, primaryBg],
            ),
          ),
        ),
        for (int i = 0; i < 4; i++)
          AnimatedBuilder(
            animation: orbCtrl[i],
            builder: (_, _) {
              final t = orbCtrl[i].value;
              final dx = sin(t * pi) * 35;
              final dy = cos(t * pi * 0.7) * 25;
              final o = orbs[i];
              return Positioned(
                left: o.$5 ? null : (o.$3 + dx),
                right: o.$5 ? (o.$3 + dx.abs()) : null,
                top: o.$6 ? null : (o.$4 + dy),
                bottom: o.$6 ? (o.$4 + dy.abs()) : null,
                child: Container(
                  width: o.$2,
                  height: o.$2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [o.$1, Colors.transparent], stops: const [0.0, 0.7]),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}