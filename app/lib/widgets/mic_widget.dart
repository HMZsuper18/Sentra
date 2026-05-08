import 'package:flutter/material.dart';
import '../core/constants.dart';

class MicWidget extends StatelessWidget {
  final AnimationController pulseCtrl;
  final Animation<double> pulseAnim;
  final AnimationController rippleCtrl;
  final List<Animation<double>> rippleScale;
  final List<Animation<double>> rippleOpacity;
  final bool isSpeaking;
  final AnimationController speakPulseCtrl;

  const MicWidget({
    super.key,
    required this.pulseCtrl,
    required this.pulseAnim,
    required this.rippleCtrl,
    required this.rippleScale,
    required this.rippleOpacity,
    required this.isSpeaking,
    required this.speakPulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final rippleColors = [
      c1.withValues(alpha: 0.55),
      c2.withValues(alpha: 0.42),
      c3.withValues(alpha: 0.30),
    ];
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: rippleCtrl,
              builder: (_, _) => Transform.scale(
                scale: rippleScale[i].value,
                child: Opacity(
                  opacity: rippleOpacity[i].value,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: rippleColors[i], width: 1.8),
                    ),
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, _) {
              if (!isSpeaking) return const SizedBox.shrink();
              return Transform.scale(
                scale: pulseAnim.value,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c2.withValues(alpha: 0.9), width: 2.5),
                    boxShadow: [
                      BoxShadow(color: c2.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: 5),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: speakPulseCtrl,
            builder: (_, _) {
              final t = speakPulseCtrl.value;
              final glowColor = isSpeaking
                  ? c2.withValues(alpha: 0.65 + t * 0.30)
                  : c1.withValues(alpha: 0.40);
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSpeaking
                        ? [c2.withValues(alpha: 0.55), c1.withValues(alpha: 0.40)]
                        : [c1.withValues(alpha: 0.35), c2.withValues(alpha: 0.25)],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: glowColor, blurRadius: isSpeaking ? 28.0 + t * 16 : 20.0),
                  ],
                ),
                child: Icon(isSpeaking ? Icons.graphic_eq : Icons.mic, color: Colors.white, size: 30),
              );
            },
          ),
        ],
      ),
    );
  }
}