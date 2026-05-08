import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants.dart';
import '../models/error_codes.dart';

class WifiSidebar extends StatelessWidget {
  final BluetoothDevice? connectedDevice;
  final List<BluetoothDevice> foundDevices;
  final bool scanning;
  final String boardName;
  final Set<String> activeErrors;
  final String debugInfo;
  final bool debugExpanded;
  final List<String> debugLogs;
  final String wifiName;
  final String wifiPassword;
  final VoidCallback onClose;
  final VoidCallback onScan;
  final void Function(BluetoothDevice) onConnect;
  final VoidCallback onSendWifi;
  final void Function(bool) onDebugToggle;
  final void Function(String) onDebugLog;
  final VoidCallback onClearLogs;

  const WifiSidebar({
    super.key,
    required this.connectedDevice,
    required this.foundDevices,
    required this.scanning,
    required this.boardName,
    required this.activeErrors,
    required this.debugInfo,
    required this.debugExpanded,
    required this.debugLogs,
    required this.wifiName,
    required this.wifiPassword,
    required this.onClose,
    required this.onScan,
    required this.onConnect,
    required this.onSendWifi,
    required this.onDebugToggle,
    required this.onDebugLog,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [const Color(0xFF1a1a2e), const Color(0xFF0a0a1a)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildConnectionStatus(),
              const SizedBox(height: 20),
              _buildBLESection(),
              const SizedBox(height: 28),
              _buildInfoField('اسم الشبكة', wifiName, Icons.wifi),
              const SizedBox(height: 16),
              _buildInfoField('كلمة المرور', wifiPassword, Icons.lock),
              const SizedBox(height: 16),
              _buildSendButton(),
              const SizedBox(height: 28),
              _buildErrorSection(),
              if (connectedDevice != null) ...[
                const SizedBox(height: 28),
                _buildDebugSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إعدادات اللوحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.bluetooth, color: c2, size: 12),
            const SizedBox(width: 4),
            Text('عبر البلوتوث', style: TextStyle(fontSize: 11, color: c2.withValues(alpha: 0.7))),
          ]),
        ],
      ),
      GestureDetector(
        onTap: onClose,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white.withValues(alpha: 0.1)),
          child: const Icon(Icons.close, color: Colors.white70, size: 20),
        ),
      ),
    ],
  );

  Widget _buildConnectionStatus() {
    final isConnected = connectedDevice != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isConnected ? c4.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: isConnected ? c4.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? c4 : Colors.red,
              boxShadow: [BoxShadow(color: (isConnected ? c4 : Colors.red).withValues(alpha: 0.6), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 12),
          Text(isConnected ? 'متصل بالبلوتوث' : 'غير متصل', style: TextStyle(color: isConnected ? c4 : Colors.red, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBLESection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الاتصال بالبلوتوث', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          GestureDetector(
            onTap: scanning ? null : onScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: c2.withValues(alpha: 0.2)),
              child: Text(scanning ? 'جاري البحث...' : 'بحث', style: TextStyle(color: c2, fontSize: 12)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (foundDevices.isEmpty && !scanning)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withValues(alpha: 0.04)),
          child: Row(children: [
            Icon(Icons.bluetooth_searching, color: Colors.white.withValues(alpha: 0.4), size: 18),
            const SizedBox(width: 10),
            Text('لم يتم العثور على أجهزة', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          ]),
        )
      else
        ...foundDevices.map((device) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onConnect(device),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(children: [
                Icon(Icons.bluetooth, color: c2, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(device.platformName.isNotEmpty ? device.platformName : 'Sentra Device', style: const TextStyle(color: Colors.white, fontSize: 13))),
                if (connectedDevice?.remoteId == device.remoteId) Icon(Icons.check_circle, color: c4, size: 18),
              ]),
            ),
          ),
        )),
      if (debugInfo.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('معلومات اللوحة', style: TextStyle(color: c2, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(debugInfo, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _buildInfoField(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withValues(alpha: 0.04),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: c2, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w300)),
        ]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ],
    ),
  );

  Widget _buildSendButton() {
    final canSend = connectedDevice != null;
    return GestureDetector(
      onTap: canSend ? onSendWifi : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: canSend ? c4.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: canSend ? c4.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send, color: canSend ? c4 : Colors.white.withValues(alpha: 0.3), size: 18),
              const SizedBox(width: 8),
              Text('إرسال إعدادات الواي فاي', style: TextStyle(color: canSend ? c4 : Colors.white.withValues(alpha: 0.3), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('أخطاء النظام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white.withValues(alpha: 0.08)),
            child: Text('محاكاة', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (activeErrors.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: c4.withValues(alpha: 0.08), border: Border.all(color: c4.withValues(alpha: 0.2))),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: c4, size: 18),
            const SizedBox(width: 10),
            Text('لا توجد أخطاء', style: TextStyle(color: c4, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        )
      else
        ...activeErrors.map((code) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.red.withValues(alpha: 0.1), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.red.withValues(alpha: 0.2)),
                child: Text(code, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(errorCodes[code] ?? 'Unknown', style: TextStyle(color: Colors.red.withValues(alpha: 0.9), fontSize: 12))),
            ]),
          ),
        )),
    ],
  );

  Widget _buildDebugSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () => onDebugToggle(!debugExpanded),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: c1.withValues(alpha: 0.1), border: Border.all(color: c1.withValues(alpha: 0.3))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.bug_report, color: c1, size: 18),
                const SizedBox(width: 10),
                Text('وضع التصحيح', style: TextStyle(color: c1, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
              Icon(debugExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: c1),
            ],
          ),
        ),
      ),
      if (debugExpanded) ...[
        const SizedBox(height: 16),
        Text('اختبار المحركات', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w300)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in ['M1+','M1-','M2+','M2-','M3+','M3-','M4+','M4-'])
            _buildDebugBtn(m, () => onDebugLog('$m clicked')),
        ]),
        const SizedBox(height: 16),
        Text('سجل التصحيح', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w300)),
        const SizedBox(height: 8),
        Container(
          height: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black.withValues(alpha: 0.3), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: debugLogs.isEmpty
              ? Center(child: Text('لا يوجد سجل', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)))
              : ListView.builder(
                  reverse: true,
                  itemCount: debugLogs.length,
                  itemBuilder: (_, i) => Text('> ${debugLogs[debugLogs.length - 1 - i]}', style: TextStyle(color: c4.withValues(alpha: 0.8), fontSize: 11, fontFamily: 'monospace')),
                ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: onClearLogs,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withValues(alpha: 0.08)),
              child: Center(child: Text('مسح السجل', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12))),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () => onDebugLog('Ping sent to board'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: c2.withValues(alpha: 0.2)),
              child: Center(child: Text('اختبار الاتصال', style: TextStyle(color: c2, fontSize: 12, fontWeight: FontWeight.w500))),
            ),
          )),
        ]),
      ],
    ],
  );

  Widget _buildDebugBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white.withValues(alpha: 0.06), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
    ),
  );
}