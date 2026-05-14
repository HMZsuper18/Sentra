import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'core/constants.dart';
import 'models/particle.dart';
import 'services/firebase_service.dart';
import 'services/ble_service.dart';
import 'widgets/glass_card.dart';
import 'widgets/robot_map_widget.dart';
import 'widgets/manual_controls.dart';
import 'widgets/wifi_sidebar.dart';
import 'widgets/background_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const SentraApp());
}

class SentraApp extends StatelessWidget {
  const SentraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sentra',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Tajawal'),
    home: const SentraHome(),
  );
}

class SentraHome extends StatefulWidget {
  const SentraHome({super.key});
  @override
  State<SentraHome> createState() => _SentraHomeState();
}

class _SentraHomeState extends State<SentraHome> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _bleService = BLEService();

  BluetoothDevice? get _connectedDevice => _bleService.connectedDevice;
  bool get _bleScanning => _bleService.scanning;
  List<BluetoothDevice> get _foundDevices => _bleService.foundDevices;

  String _debugInfo = '';
  String boardName = 'ESP32';
  Set<String> _activeErrors = {};
  bool _debugExpanded = false;
  final List<String> _debugLogs = [];

  String _lastCommand = '...';
  List<String> _motorStates = ['idle', 'idle', 'idle', 'idle'];

  StreamSubscription<String>? _fbSub;

  late AnimationController _popCtrl;
  late List<AnimationController> _orbCtrl;
  late List<AnimationController> _particleCtrl;
  late List<Particle> _particles;
  late AnimationController _lcdBlinkCtrl;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startFirebaseStream();
    _initBLE();
  }

  Future<void> _initBLE() async {
    await _bleService.init((device) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startBLEScan() async {
    await _bleService.startScan((device) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _bleService.connect(
      device,
      onBoardName: (name) {
        if (mounted) setState(() => boardName = name);
      },
      onErrors: (errors) {
        if (mounted) setState(() => _activeErrors = errors);
      },
      onDebug: (info) {
        if (mounted) setState(() => _debugInfo = info);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _sendWifiCredentials() async {
    await _bleService.sendWifiCredentials('still_undefined', 'still_undefined');
  }

  void _startFirebaseStream() {
    _fbSub = firebaseStream().listen((raw) {
      try {
        final decoded = jsonDecode(raw);
        String? word;
        if (decoded is Map) {
          word = decoded['word']?.toString();
        } else if (decoded is String) {
          final inner = jsonDecode(decoded);
          word = inner is Map ? inner['word']?.toString() : null;
        }
        if (word != null && mounted) {
          final cmd = word;
          setState(() {
            _lastCommand = cmd;
          });
        }
      } catch (_) {}
    });
  }

  void _initAnimations() {
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _popCtrl.value = 1.0;

    _orbCtrl = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: [8000, 10500, 12000, 9200][i]),
      )..repeat(reverse: true),
    );

    _lcdBlinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    final rng = Random();
    _particles = List.generate(20, (_) => Particle(rng));
    _particleCtrl = List.generate(20, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 4000 + rng.nextInt(5000)),
      )..repeat(reverse: true);
      Future.delayed(Duration(milliseconds: rng.nextInt(3000)), () {
        if (mounted) c.forward();
      });
      return c;
    });
  }

  @override
  void dispose() {
    _fbSub?.cancel();
    _popCtrl.dispose();
    _lcdBlinkCtrl.dispose();
    for (final c in _orbCtrl) {
      c.dispose();
    }
    for (final c in _particleCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: primaryBg,
      drawer: WifiSidebar(
        connectedDevice: _connectedDevice,
        foundDevices: _foundDevices,
        scanning: _bleScanning,
        boardName: boardName,
        activeErrors: _activeErrors,
        debugInfo: _debugInfo,
        debugExpanded: _debugExpanded,
        debugLogs: _debugLogs,
        wifiName: 'still_undefined',
        wifiPassword: 'still_undefined',
        onClose: () => Navigator.pop(context),
        onScan: _startBLEScan,
        onConnect: _connectToDevice,
        onSendWifi: _sendWifiCredentials,
        onDebugToggle: (expanded) => setState(() => _debugExpanded = expanded),
        onDebugLog: _addDebugLog,
        onClearLogs: () => setState(() => _debugLogs.clear()),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundWidget(orbCtrl: _orbCtrl),
          ..._buildParticles(context),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: landscape ? 40 : 24,
                      vertical: 24,
                    ),
                    child: landscape
                        ? _buildLandscapeLayout()
                        : _buildPortraitLayout(),
                  ),
                ),
                Positioned(top: 16, right: 16, child: _buildWifiButton()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiButton() => GestureDetector(
    onTap: () => _scaffoldKey.currentState?.openDrawer(),
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: _connectedDevice != null
              ? c4.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Icon(
        Icons.wifi,
        color: _connectedDevice != null
            ? c4
            : Colors.white.withValues(alpha: 0.4),
        size: 22,
      ),
    ),
  );

  Widget _buildPortraitLayout() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCommandBadge(),
            const SizedBox(height: 16),
            ManualControlsWidget(onCommand: _sendCommand),
          ],
        ),
      ),
      const SizedBox(height: 16),
      RobotMapWidget(
        lastCommand: _lastCommand,
        motorStates: _motorStates,
        lcdCtrl: _lcdBlinkCtrl,
      ),
      const SizedBox(height: 12),
      _buildLegend(),
    ],
  );

  Widget _buildLandscapeLayout() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCommandBadge(),
                  const SizedBox(height: 16),
                  ManualControlsWidget(onCommand: _sendCommand),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RobotMapWidget(
              lastCommand: _lastCommand,
              motorStates: _motorStates,
              lcdCtrl: _lcdBlinkCtrl,
            ),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    ],
  );

  Widget _buildCommandBadge() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sensors, color: c2.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Text(
          _lastCommand,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(color: c1.withValues(alpha: 0.8), blurRadius: 20),
              Shadow(color: c2.withValues(alpha: 0.4), blurRadius: 40),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildLegend() => Wrap(
    spacing: 12,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      _legendItem('قدام', const Color(0xFF22c55e), 'للأمام'),
      _legendItem('ورا', const Color(0xFFef4444), 'للخلف'),
    ],
  );

  Widget _legendItem(String cmd, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
          ],
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 11,
        ),
      ),
    ],
  );

  List<Widget> _buildParticles(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return List.generate(_particles.length, (i) {
      final p = _particles[i];
      return AnimatedBuilder(
        animation: _particleCtrl[i],
        builder: (_, _) {
          final t = _particleCtrl[i].value;
          final y = p.startY * size.height - t * p.speed * size.height * 0.3;
          final x = p.startX * size.width + sin(t * pi * 2) * 20 * p.drift;
          return Positioned(
            left: x,
            top: y,
            child: Opacity(
              opacity: (sin(t * pi) * p.opacity).clamp(0.0, 1.0),
              child: Container(
                width: p.size,
                height: p.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.color,
                  boxShadow: [
                    BoxShadow(color: p.color, blurRadius: p.size * 2),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _sendCommand(String command) {
    sendToFirebase(command);
    setState(() {
      _lastCommand = command;
      _updateLocalMotorState(command);
    });
  }

  void _updateLocalMotorState(String command) {
    switch (command) {
      case 'قدام':
        _motorStates = ['forward', 'forward', 'forward', 'forward'];
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted)
            setState(() => _motorStates = ['idle', 'idle', 'idle', 'idle']);
        });
        break;
      case 'ورا':
        _motorStates = ['backward', 'backward', 'backward', 'backward'];
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted)
            setState(() => _motorStates = ['idle', 'idle', 'idle', 'idle']);
        });
        break;
      case 'يمين':
        _motorStates = ['forward', 'forward', 'backward', 'backward'];
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted)
            setState(() => _motorStates = ['idle', 'idle', 'idle', 'idle']);
        });
        break;
      case 'شمال':
        _motorStates = ['backward', 'backward', 'forward', 'forward'];
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted)
            setState(() => _motorStates = ['idle', 'idle', 'idle', 'idle']);
        });
        break;
      case 'وقف':
        _motorStates = ['idle', 'idle', 'idle', 'idle'];
        break;
    }
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _debugLogs.add('[$timestamp] $message');
      if (_debugLogs.length > 50) _debugLogs.removeAt(0);
    });
  }
}
