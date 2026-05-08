import 'package:flutter/material.dart';
import '../core/constants.dart';

class WaveformWidget extends StatelessWidget {
  final List<AnimationController> waveCtrl;
  final bool isSpeaking;

  const WaveformWidget({
    super.key,
    required this.waveCtrl,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    const base = [14.0, 22.0, 18.0, 26.0, 20.0, 28.0, 16.0, 24.0, 18.0, 12.0];
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(10, (i) => AnimatedBuilder(
          animation: waveCtrl[i],
          builder: (_, _) {
            final floor = isSpeaking ? 0.7 : 0.3;
            final h = base[i] * (floor + waveCtrl[i].value * (1.0 - floor));
            return Container(
              width: 3.5,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: isSpeaking ? [c2, c3] : [c2, c1],
                ),
                boxShadow: [
                  BoxShadow(color: (isSpeaking ? c3 : c1).withValues(alpha: 0.5), blurRadius: 6),
                ],
              ),
            );
          },
        )),
      ),
    );
  }
}