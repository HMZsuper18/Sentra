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
        SizedBox(
          width: double.infinity,
          child: _buildButton('وقف', '■', fullWidth: true),
        ),
      ],
    ),
  );

  Widget _buildButton(String label, String icon, {bool fullWidth = false}) {
    return GestureDetector(
      onTap: () => onCommand(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: fullWidth ? double.infinity : 68,
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
