import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  final double startX, startY, size, speed, drift, opacity;
  final Color color;
  static const palette = [
    Color(0xFFa78bfa),
    Color(0xFF38bdf8),
    Color(0xFFf472b6),
    Color(0xFF34d399),
    Color(0xFFfbbf24),
  ];
  Particle(Random rng)
      : startX = rng.nextDouble(),
        startY = rng.nextDouble(),
        size = 1.5 + rng.nextDouble() * 3.0,
        speed = 0.06 + rng.nextDouble() * 0.12,
        drift = rng.nextDouble() * 2 - 1,
        opacity = 0.3 + rng.nextDouble() * 0.5,
        color = palette[rng.nextInt(palette.length)];
}