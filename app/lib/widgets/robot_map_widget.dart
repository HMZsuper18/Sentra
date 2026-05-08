import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/keywords.dart';

class RobotMapWidget extends StatelessWidget {
  final String lastCommand;
  final List<String> motorStates;
  final AnimationController lcdCtrl;

  const RobotMapWidget({
    super.key,
    required this.lastCommand,
    required this.motorStates,
    required this.lcdCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final wc = wheelColor(lastCommand);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: wc.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 4)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLabel('خريطة الروبوت'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _buildWheel(wc, motorStates[0]),
                    const SizedBox(height: 40),
                    _buildWheel(wc, motorStates[1]),
                  ],
                ),
                Container(
                  width: 90,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: c1.withValues(alpha: 0.1), blurRadius: 20)],
                  ),
                  child: Icon(Icons.smart_toy_rounded, color: c1.withValues(alpha: 0.8), size: 34),
                ),
                Column(
                  children: [
                    _buildWheel(wc, motorStates[2]),
                    const SizedBox(height: 40),
                    _buildWheel(wc, motorStates[3]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildVirtualLCD(wc),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel(Color color, String motorState) {
    final stateColor = switch (motorState) {
      'forward' => const Color(0xFF22c55e),
      'backward' => const Color(0xFFef4444),
      _ => const Color(0xFF6b7280),
    };
    final isActive = motorState != 'idle';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 20,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: stateColor,
        boxShadow: isActive
            ? [BoxShadow(color: stateColor.withValues(alpha: 0.7), blurRadius: 14, spreadRadius: 2)]
            : [],
        border: Border.all(color: stateColor.withValues(alpha: 0.5), width: 1.5),
      ),
    );
  }

  Widget _buildVirtualLCD(Color wc) {
    final lcdText = 'Sentra OK';
    return AnimatedBuilder(
      animation: lcdCtrl,
      builder: (_, _) {
        final glow = 0.4 + lcdCtrl.value * 0.3;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: lcdBg,
            border: Border.all(color: c2.withValues(alpha: 0.6)),
            boxShadow: [BoxShadow(color: c2.withValues(alpha: glow), blurRadius: 18, spreadRadius: 2)],
          ),
          child: Row(
            children: [
              Icon(Icons.display_settings, color: c2.withValues(alpha: 0.6), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lcdText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w300,
      letterSpacing: 2,
      color: Colors.white.withValues(alpha: 0.45),
    ),
    textAlign: TextAlign.center,
  );
}