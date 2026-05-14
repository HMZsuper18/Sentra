import 'package:flutter/material.dart';

class ManualControlsWidget extends StatelessWidget {
  final void Function(String) onCommand;

  const ManualControlsWidget({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withValues(alpha: 0.03),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(
      children: [
        _buildLabel('التحكم اليدوي'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButton('يمين', '→'),
            _buildButton('شمال', '←'),
            _buildButton('قدام', '↑'),
            _buildButton('ورا', '↓'),
          ],
        ),
        const SizedBox(height: 10),
        Center(child: _buildStopButton()),
      ],
    ),
  );

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: () => onCommand('وقف'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFef4444).withValues(alpha: 0.2),
          border: Border.all(
            color: const Color(0xFFef4444).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFef4444).withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stop, color: Color(0xFFef4444), size: 22),
            SizedBox(height: 2),
            Text(
              'وقف',
              style: TextStyle(
                color: Color(0xFFef4444),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, String icon) {
    return GestureDetector(
      onTap: () => onCommand(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
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
