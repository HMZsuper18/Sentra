import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/keywords.dart';

class RobotMapWidget extends StatelessWidget {
  final String lastCommand;
  final List<String> motorStates;

  const RobotMapWidget({
    super.key,
    required this.lastCommand,
    required this.motorStates,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_rounded, color: c1.withValues(alpha: 0.8), size: 28),
                      const SizedBox(height: 6),
                      Text(
                        lastCommand,
                        style: TextStyle(
                          color: wc,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
