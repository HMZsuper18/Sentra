import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

const String _dbUrl =
    'https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/command/word.json';
const String _dbStreamUrl =
    'https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/command/word.json?auth=zuUhC4VNiO0quwQ3JlmtH6hLf2Lx8YvODFCCuZVC';

const Map<String, List<String>> _keywordMap = {
  'يمين': [
    'يمين',
    'يميناً',
    'اتجه يمين',
    'دور يمين',
    'لف يمين',
    'خش يمين',
    'ناحية اليمين',
    'جهة اليمين',
    'اميل يمين',
    'انعطف يمين',
    'توجه يمين',
    'يمين',
    'روّح يمين',
    'حي اليمين',
    'اتجه لليمين',
    'دوار يمين',
    'لف得太',
    'خشّ يمين',
  ],
  'شمال': [
    'شمال',
    'يسار',
    'اتجه شمال',
    'دور شمال',
    'لف شمال',
    'يسار',
    'اتجه يساراً',
    'خش شمال',
    'ناحية الشمال',
    'جهة اليسار',
    'اميل يسار',
    'انعطف شمال',
    'توجه شمال',
    'شمالاً',
    'روّح شمال',
    'حي للشمال',
    'اتجه لليسار',
    'دوار شمال',
  ],
  'قدام': [
    'قدام',
    'امام',
    'الأمام',
    'تقدم',
    'للأمام',
    'امشي',
    'تحرك',
    'كمل',
    'دغري',
    'على طول',
    'اطلع قدام',
    'توجه قدام',
    'اماماً',
    'روّح قدام',
    'للأمام',
    'قدماً',
    'امامي',
    'تقدم向前',
    'امشي قدام',
  ],
  'ورا': [
    'ورا',
    'الخلف',
    'للخلف',
    'تراجع',
    'ارجع',
    'ارجع ورا',
    'لورا',
    'عشيري',
    'ارجع تاني',
    'تراجع للخلف',
    'إرجع',
    'رجع',
    'رجع ورا',
    'للخلف',
    'خلف',
    'ورّ',
    'إحイド',
  ],
  'وقف': [
    'وقف',
    'توقف',
    'قف',
    'استنى',
    'اوقف',
    'بس',
    'خلاص',
    'اثبت',
    'فرمل',
    'هدئ',
    'كفاية',
    'توق',
    'توقّف',
    'إوقف',
    'ثبت',
    'إنتظر',
    'إنتظر.',
    'إهدأ',
    'تكفّى',
  ],
};

const _ignoredErrors = {
  'error_speech_timeout',
  'error_no_match',
  'error_client',
  'error_recognizer_busy',
};

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

// ── Color constants ──────────────────────────────────────────────────────────
const Color _c1 = Color(0xFFa78bfa);
const Color _c2 = Color(0xFF38bdf8);
const Color _c3 = Color(0xFFf472b6);
const Color _c4 = Color(0xFF34d399);

Color _wheelColor(String cmd) {
  switch (cmd) {
    case 'قدام':
      return const Color(0xFF22c55e);
    case 'ورا':
      return const Color(0xFFef4444);
    case 'يمين':
    case 'شمال':
      return const Color(0xFFf97316);
    default:
      return const Color(0xFF6b7280);
  }
}

// ── Firebase SSE Stream ──────────────────────────────────────────────────────
Stream<String> firebaseStream() async* {
  while (true) {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_dbStreamUrl));
      request.headers['Accept'] = 'text/event-stream';
      final response = await client.send(request);
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data:')) {
            final raw = line.substring(5).trim();
            if (raw.isNotEmpty && raw != 'null') yield raw;
          }
        }
      }
      client.close();
    } catch (_) {
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class SentraHome extends StatefulWidget {
  const SentraHome({super.key});
  @override
  State<SentraHome> createState() => _SentraHomeState();
}

class _SentraHomeState extends State<SentraHome> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bluetooth
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _wifiNameChar;
  BluetoothCharacteristic? _wifiPassChar;
  bool _bleScanning = false;
  final List<BluetoothDevice> _foundDevices = [];
  String _debugInfo = '';

  // WiFi Info
  final String _wifiName = 'still_undefined';
  final String _wifiPassword = 'still_undefined';
  String boardName = 'ESP32';

  // Error codes
  final Map<String, String> _errorCodes = {
    'E001': 'Motor 1 Overcurrent',
    'E002': 'Motor 2 Overcurrent',
    'E003': 'Motor 3 Overcurrent',
    'E004': 'Motor 4 Overcurrent',
    'E005': 'Battery Low',
    'E006': 'WiFi Disconnected',
    'E007': 'Bluetooth Timeout',
    'E008': 'Sensor Error',
    'E009': 'Firmware Crash',
  };
  Set<String> _activeErrors = {};

  // Debug mode
  bool _debugExpanded = false;
  final List<String> _debugLogs = [];

  // Speech
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isSpeaking = false;
  bool _speechRestarting = false;
  DateTime _lastRestartTime = DateTime.now();
  String _transcript = '...';
  String _keyword = 'تحدث';
  bool _denied = false;
  String _lastCommand = 'وقف';
  String _lcdText = 'Sentra OK';
  List<String> _motorStates = ['idle', 'idle', 'idle', 'idle'];

  // Firebase stream
  StreamSubscription<String>? _fbSub;

  // Animations
  late AnimationController _popCtrl;
  late Animation<double> _popScale, _popOpacity;
  late List<AnimationController> _orbCtrl;
  late List<AnimationController> _waveCtrl;
  late List<AnimationController> _rippleCtrl;
  late List<Animation<double>> _rippleScale, _rippleOpacity;
  late AnimationController _speakPulseCtrl;
  late Animation<double> _speakPulse;
  late List<AnimationController> _particleCtrl;
  late List<_Particle> _particles;
  late AnimationController _lcdBlinkCtrl;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSpeech();
    _startFirebaseStream();
    _initBLE();
  }

  Future<void> _initBLE() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
      _startBLEScan();
    }
  }

  Future<void> _startBLEScan() async {
    _bleScanning = true;
    _foundDevices.clear();
    FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (result.device.name.startsWith('Sentra') &&
            !_foundDevices.any((d) => d.remoteId == result.device.remoteId)) {
          setState(() {
            _foundDevices.add(result.device);
          });
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    _bleScanning = false;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      await _discoverServices();
      setState(() {});
    } catch (e) {
      debugPrint('Connection failed: $e');
    }
  }

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;
    final services = await _connectedDevice!.discoverServices();
    for (final service in services) {
      for (final char in service.characteristics) {
        switch (char.uuid.toString()) {
          case '12345678-1234-1234-1234-123456789001':
            _wifiNameChar = char;
            break;
          case '12345678-1234-1234-1234-123456789002':
            _wifiPassChar = char;
            break;
          case '12345678-1234-1234-1234-123456789003':
            char.lastValueStream.listen((value) {
              if (mounted) {
                setState(() {
                  boardName = String.fromCharCodes(value);
                });
              }
            });
            break;
          case '12345678-1234-1234-1234-123456789004':
            char.lastValueStream.listen((value) {
              if (mounted) {
                final errors = String.fromCharCodes(value);
                setState(() {
                  _activeErrors = errors == 'OK' || errors.isEmpty
                      ? {}
                      : errors.split(',').toSet();
                });
              }
            });
            break;
          case '12345678-1234-1234-1234-123456789005':
            char.lastValueStream.listen((value) {
              if (mounted) {
                setState(() {
                  _debugInfo = String.fromCharCodes(value);
                });
              }
            });
            break;
        }
      }
    }
  }

  Future<void> _sendWifiCredentials() async {
    if (_wifiNameChar != null) {
      await _wifiNameChar!.write(_wifiName.codeUnits);
    }
    if (_wifiPassChar != null) {
      await _wifiPassChar!.write(_wifiPassword.codeUnits);
    }
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
          setState(() {
            _lastCommand = word!;
            _lcdText = word == 'وقف' ? 'Stopped' : 'CMD: $word';
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
    _popScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.elasticOut));
    _popOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut));
    _popCtrl.value = 1.0;

    _orbCtrl = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: [8000, 10500, 12000, 9200][i]),
      )..repeat(reverse: true),
    );

    _waveCtrl = List.generate(10, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 900 + i * 70),
      )..repeat(reverse: true);
      Future.delayed(Duration(milliseconds: i * 90), () {
        if (mounted) c.forward();
      });
      return c;
    });

    _rippleCtrl = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat();
      Future.delayed(Duration(milliseconds: i * 700), () {
        if (mounted) c.forward();
      });
      return c;
    });
    _rippleScale = _rippleCtrl
        .map(
          (c) => Tween<double>(
            begin: 1.0,
            end: 2.8,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();
    _rippleOpacity = _rippleCtrl
        .map(
          (c) => Tween<double>(
            begin: 0.8,
            end: 0.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();

    _speakPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _speakPulse = Tween<double>(begin: 1.0, end: 1.38).animate(
      CurvedAnimation(parent: _speakPulseCtrl, curve: Curves.easeInOut),
    );

    _lcdBlinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    final rng = Random();
    _particles = List.generate(20, (_) => _Particle(rng));
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

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          _speechRestarting = false;
          Future.delayed(const Duration(milliseconds: 250), _startListening);
        }
      },
      onError: (e) {
        if (!mounted) return;
        if (_ignoredErrors.contains(e.errorMsg)) {
          _speechRestarting = false;
          Future.delayed(const Duration(milliseconds: 350), _startListening);
          return;
        }
        _speechRestarting = false;
        setState(() {
          _denied = true;
          _isSpeaking = false;
        });
        _speakPulseCtrl.stop();
        _speakPulseCtrl.reset();
      },
    );
    if (_speechAvailable) {
      _startListening();
    } else if (mounted) {
      setState(() => _denied = true);
    }
  }

  void _startListening() {
    if (!mounted || !_speechAvailable || _speech.isListening) return;
    final now = DateTime.now();
    if (_speechRestarting ||
        now.difference(_lastRestartTime).inMilliseconds < 2000) {
      return;
    }
    _speechRestarting = true;
    _speech
        .listen(
          localeId: 'ar_EG',
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          onResult: (result) {
            if (!mounted) return;
            final words = result.recognizedWords.trim();
            final speaking = words.isNotEmpty && !result.finalResult;
            if (speaking != _isSpeaking) {
              setState(() => _isSpeaking = speaking);
              speaking
                  ? _speakPulseCtrl.repeat(reverse: true)
                  : (_speakPulseCtrl
                      ..stop()
                      ..reset());
            }
            if (!result.finalResult) return;
            _speechRestarting = false;
            _lastRestartTime = DateTime.now();
            setState(() => _isSpeaking = false);
            _speakPulseCtrl
              ..stop()
              ..reset();
            if (words.isEmpty) return;
            final keyword = _extractKeyword(words);
            setState(() {
              _transcript = words;
              _keyword = keyword ?? '؟';
            });
            _popCtrl.forward(from: 0);
            _sendToFirebase(keyword ?? '');
          },
        )
        .then((_) {
          _speechRestarting = false;
          _lastRestartTime = DateTime.now();
        })
        .catchError((_) {
          _speechRestarting = false;
          _lastRestartTime = DateTime.now();
        });
  }

  String? _extractKeyword(String text) {
    for (final entry in _keywordMap.entries) {
      for (final phrase in entry.value) {
        if (text.contains(phrase)) return entry.key;
      }
    }
    return null;
  }

  Future<void> _sendToFirebase(String keyword) async {
    try {
      await http.put(
        Uri.parse(_dbUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': keyword}),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _fbSub?.cancel();
    _popCtrl.dispose();
    _speakPulseCtrl.dispose();
    _lcdBlinkCtrl.dispose();
    for (final c in _orbCtrl) {
      c.dispose();
    }
    for (final c in _waveCtrl) {
      c.dispose();
    }
    for (final c in _rippleCtrl) {
      c.dispose();
    }
    for (final c in _particleCtrl) {
      c.dispose();
    }
    _speech.stop();
    super.dispose();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0a0a1a),
      drawer: _buildWifiSidebar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
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
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: (_connectedDevice != null)
              ? _c4.withOpacity(0.5)
              : Colors.white.withOpacity(0.15),
        ),
      ),
      child: Icon(
        Icons.wifi,
        color: (_connectedDevice != null) ? _c4 : Colors.white.withOpacity(0.4),
        size: 22,
      ),
    ),
  );

  Widget _buildWifiSidebar() => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إعدادات اللوحة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.bluetooth, color: _c2, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'عبر البلوتوث',
                          style: TextStyle(
                            fontSize: 11,
                            color: _c2.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildConnectionStatus(),
            const SizedBox(height: 20),
            _buildBLESection(),
            const SizedBox(height: 28),
            _buildWifiInfoField('اسم الشبكة', _wifiName, Icons.wifi),
            const SizedBox(height: 16),
            _buildWifiInfoField('كلمة المرور', _wifiPassword, Icons.lock),
            const SizedBox(height: 16),
            _buildSendWifiButton(),
            const SizedBox(height: 28),
            _buildErrorCodesSection(),
            if (_connectedDevice != null) ...[
              const SizedBox(height: 28),
              _buildDebugSection(),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _buildConnectionStatus() {
    final isConnected = _connectedDevice != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isConnected ? _c4.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        border: Border.all(
          color: isConnected
              ? _c4.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? _c4 : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? _c4 : Colors.red).withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isConnected ? 'متصل بالبلوتوث' : 'غير متصل',
            style: TextStyle(
              color: isConnected ? _c4 : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBLESection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الاتصال بالبلوتوث',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: _bleScanning ? null : () => _startBLEScan(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _c2.withOpacity(0.2),
                ),
                child: Text(
                  _bleScanning ? 'جاري البحث...' : 'بحث',
                  style: TextStyle(color: _c2, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_foundDevices.isEmpty && !_bleScanning)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.04),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bluetooth_searching,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'لم يتم العثور على أجهزة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_foundDevices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _connectToDevice(device),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth, color: _c2, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          device.name.isNotEmpty
                              ? device.name
                              : 'Sentra Device',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_connectedDevice?.remoteId == device.remoteId)
                        Icon(Icons.check_circle, color: _c4, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          )),
        if (_debugInfo.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withOpacity(0.3),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات اللوحة',
                  style: TextStyle(
                    color: _c2,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _debugInfo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSendWifiButton() {
    final canSend = _connectedDevice != null;
    return GestureDetector(
      onTap: canSend ? _sendWifiCredentials : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: canSend
              ? _c4.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: canSend
                ? _c4.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.send,
                color: canSend ? _c4 : Colors.white.withOpacity(0.3),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'إرسال إعدادات الواي فاي',
                style: TextStyle(
                  color: canSend ? _c4 : Colors.white.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWifiInfoField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _c2, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أخطاء النظام',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_activeErrors.isEmpty) {
                    _activeErrors = {'E005', 'E006'};
                  } else {
                    _activeErrors.clear();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.08),
                ),
                child: Text(
                  'محاكاة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activeErrors.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _c4.withOpacity(0.08),
              border: Border.all(color: _c4.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: _c4, size: 18),
                const SizedBox(width: 10),
                Text(
                  'لا توجد أخطاء',
                  style: TextStyle(
                    color: _c4,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ..._activeErrors.map(
            (code) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.red.withOpacity(0.2),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorCodes[code] ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebugSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _debugExpanded = !_debugExpanded),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _c1.withOpacity(0.1),
              border: Border.all(color: _c1.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, color: _c1, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'وضع التصحيح',
                      style: TextStyle(
                        color: _c1,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _debugExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _c1,
                ),
              ],
            ),
          ),
        ),
        if (_debugExpanded) ...[
          const SizedBox(height: 16),
          Text(
            'اختبار المحركات',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDebugButton('M1+', () => _addDebugLog('Motor 1 Forward')),
              _buildDebugButton('M1-', () => _addDebugLog('Motor 1 Backward')),
              _buildDebugButton('M2+', () => _addDebugLog('Motor 2 Forward')),
              _buildDebugButton('M2-', () => _addDebugLog('Motor 2 Backward')),
              _buildDebugButton('M3+', () => _addDebugLog('Motor 3 Forward')),
              _buildDebugButton('M3-', () => _addDebugLog('Motor 3 Backward')),
              _buildDebugButton('M4+', () => _addDebugLog('Motor 4 Forward')),
              _buildDebugButton('M4-', () => _addDebugLog('Motor 4 Backward')),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'سجل التصحيح',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withOpacity(0.3),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: _debugLogs.isEmpty
                ? Center(
                    child: Text(
                      'لا يوجد سجل',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _debugLogs.length,
                    itemBuilder: (_, i) => Text(
                      '> ${_debugLogs[_debugLogs.length - 1 - i]}',
                      style: TextStyle(
                        color: _c4.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _debugLogs.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: Center(
                      child: Text(
                        'مسح السجل',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _addDebugLog('Ping sent to board'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _c2.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        'اختبار الاتصال',
                        style: TextStyle(
                          color: _c2,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDebugButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _debugLogs.add('[$timestamp] $message');
      if (_debugLogs.length > 50) _debugLogs.removeAt(0);
    });
  }

  Widget _buildPortraitLayout() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _glassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMic(),
            const SizedBox(height: 22),
            _buildLabel('تعرف على الكلام'),
            const SizedBox(height: 8),
            _buildTranscriptBox(),
            const SizedBox(height: 10),
            _buildWordBox(),
            const SizedBox(height: 14),
            _buildWaveform(),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildManualControls(),
      const SizedBox(height: 20),
      _buildRobotMap(),
      const SizedBox(height: 12),
      _buildLegend(),
    ],
  );

  Widget _buildLandscapeLayout() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _glassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMic(),
              const SizedBox(height: 14),
              _buildWaveform(),
              const SizedBox(height: 10),
              _buildLabel('تعرف على الكلام'),
              const SizedBox(height: 8),
              _buildTranscriptBox(),
              const SizedBox(height: 10),
              _buildWordBox(),
            ],
          ),
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRobotMap(),
            const SizedBox(height: 12),
            _buildManualControls(),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    ],
  );

  // ── Robot Map ─────────────────────────────────────────────────────────────
  Widget _buildRobotMap() {
    final wc = _wheelColor(_lastCommand);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: wc.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLabel('خريطة الروبوت'),
            const SizedBox(height: 16),
            // Wheel layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _buildWheel(wc, isLeft: true, isFront: true, motorIndex: 0),
                    const SizedBox(height: 40),
                    _buildWheel(
                      wc,
                      isLeft: true,
                      isFront: false,
                      motorIndex: 1,
                    ),
                  ],
                ),
                // Robot body
                Container(
                  width: 90,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.07),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(color: _c1.withOpacity(0.1), blurRadius: 20),
                    ],
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: _c1.withOpacity(0.8),
                    size: 34,
                  ),
                ),

                Column(
                  children: [
                    _buildWheel(
                      wc,
                      isLeft: false,
                      isFront: true,
                      motorIndex: 2,
                    ),
                    const SizedBox(height: 40),
                    _buildWheel(
                      wc,
                      isLeft: false,
                      isFront: false,
                      motorIndex: 3,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildVirtualLCD(),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel(
    Color color, {
    required bool isLeft,
    required bool isFront,
    required int motorIndex,
  }) {
    final motorState = _motorStates[motorIndex];
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
            ? [
                BoxShadow(
                  color: stateColor.withOpacity(0.7),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : [],
        border: Border.all(color: stateColor.withOpacity(0.5), width: 1.5),
      ),
    );
  }

  Widget _buildVirtualLCD() {
    final isCmd = _lcdText.startsWith('CMD:');
    final wc = _wheelColor(_lastCommand);
    final lcdColor = isCmd ? wc : Colors.white;
    return AnimatedBuilder(
      animation: _lcdBlinkCtrl,
      builder: (_, _) {
        final glow = 0.4 + _lcdBlinkCtrl.value * 0.3;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF001a33),
            border: Border.all(
              color: isCmd ? wc.withOpacity(0.6) : _c2.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: isCmd ? wc.withOpacity(glow) : _c2.withOpacity(glow),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.display_settings,
                color: isCmd ? wc.withOpacity(0.6) : _c2.withOpacity(0.6),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lcdText,
                  style: TextStyle(
                    color: lcdColor,
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

  // ── Manual Controls ──────────────────────────────────────────────────────────────
  Widget _buildManualControls() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withOpacity(0.03),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Column(
      children: [
        _buildLabel('التحكم اليدوي'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton('يمين', '→'),
            _buildControlButton('شمال', '←'),
            _buildControlButton('قدام', '↑'),
            _buildControlButton('ورا', '↓'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _buildControlButton('وقف', '■', isFullWidth: true),
        ),
      ],
    ),
  );

  Widget _buildControlButton(
    String label,
    String icon, {
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: () => _sendCommand(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isFullWidth ? double.infinity : 68,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendCommand(String command) {
    _sendToFirebase(command);
    setState(() {
      _keyword = command;
      _transcript = '[$command]';
      _lcdText = command == 'وقف' ? 'Stopped' : 'CMD: $command';
      _updateLocalMotorState(command);
    });
    _popCtrl.forward(from: 0);
  }

  void _updateLocalMotorState(String command) {
    switch (command) {
      case 'قدام':
        _motorStates = ['forward', 'forward', 'forward', 'forward'];
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _motorStates = ['idle', 'idle', 'idle', 'idle'];
              _lcdText = 'متوقف';
            });
          }
        });
        break;
      case 'ورا':
        _motorStates = ['backward', 'backward', 'backward', 'backward'];
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _motorStates = ['idle', 'idle', 'idle', 'idle'];
              _lcdText = 'متوقف';
            });
          }
        });
        break;
      case 'يمين':
        _motorStates = ['forward', 'forward', 'backward', 'backward'];
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _motorStates = ['idle', 'idle', 'idle', 'idle'];
              _lcdText = 'متوقف';
            });
          }
        });
        break;
      case 'شمال':
        _motorStates = ['backward', 'backward', 'forward', 'forward'];
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _motorStates = ['idle', 'idle', 'idle', 'idle'];
              _lcdText = 'متوقف';
            });
          }
        });
        break;
      case 'وقف':
        _motorStates = ['idle', 'idle', 'idle', 'idle'];
        break;
    }
  }

  // ── Legend ────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    final items = [
      ('قدام', const Color(0xFF22c55e), 'للأمام'),
      ('ورا', const Color(0xFFef4444), 'للخلف'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items
          .map(
            (e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: e.$2,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(color: e.$2.withOpacity(0.5), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  e.$3,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    final orbs = [
      (_c1.withOpacity(0.45), 500.0, -150.0, -150.0, false, false),
      (_c2.withOpacity(0.40), 420.0, -100.0, -100.0, true, false),
      (_c3.withOpacity(0.35), 320.0, 40.0, 0.0, false, true),
      (_c4.withOpacity(0.28), 260.0, 80.0, 80.0, true, true),
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.4,
              colors: [Color(0xFF0f0f2e), Color(0xFF0a0a1a)],
            ),
          ),
        ),
        for (int i = 0; i < 4; i++)
          AnimatedBuilder(
            animation: _orbCtrl[i],
            builder: (_, _) {
              final t = _orbCtrl[i].value;
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
                    gradient: RadialGradient(
                      colors: [o.$1, Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

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

  // ── Glass card ────────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child}) => Container(
    padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      color: Colors.white.withOpacity(0.07),
      border: Border.all(color: Colors.white.withOpacity(0.22)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 40),
        BoxShadow(
          color: _c1.withOpacity(0.09),
          blurRadius: 60,
          spreadRadius: 10,
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.13),
          Colors.white.withOpacity(0.03),
          Colors.transparent,
          Colors.white.withOpacity(0.04),
        ],
        stops: const [0.0, 0.35, 0.6, 1.0],
      ),
    ),
    child: Directionality(textDirection: TextDirection.rtl, child: child),
  );

  // ── Mic ───────────────────────────────────────────────────────────────────
  Widget _buildMic() {
    final rippleColors = [
      _c1.withOpacity(0.55),
      _c2.withOpacity(0.42),
      _c3.withOpacity(0.30),
    ];
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _rippleCtrl[i],
              builder: (_, _) => Transform.scale(
                scale: _rippleScale[i].value,
                child: Opacity(
                  opacity: _rippleOpacity[i].value,
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
            animation: _speakPulse,
            builder: (_, _) {
              if (!_isSpeaking) return const SizedBox.shrink();
              return Transform.scale(
                scale: _speakPulse.value,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _c2.withOpacity(0.9), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _c2.withOpacity(0.55),
                        blurRadius: 22,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _speakPulseCtrl,
            builder: (_, _) {
              final t = _speakPulseCtrl.value;
              final glowColor = _isSpeaking
                  ? _c2.withOpacity(0.65 + t * 0.30)
                  : _c1.withOpacity(0.40);
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isSpeaking
                        ? [_c2.withOpacity(0.55), _c1.withOpacity(0.40)]
                        : [_c1.withOpacity(0.35), _c2.withOpacity(0.25)],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: _isSpeaking ? 28.0 + t * 16 : 20.0,
                    ),
                  ],
                ),
                child: Icon(
                  _isSpeaking ? Icons.graphic_eq : Icons.mic,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w300,
      letterSpacing: 2,
      color: Colors.white.withOpacity(0.45),
    ),
    textAlign: TextAlign.center,
  );

  Widget _buildTranscriptBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withOpacity(0.03),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Text(
      _transcript,
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withOpacity(0.38),
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildWordBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    constraints: const BoxConstraints(minHeight: 72),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withOpacity(0.05),
      border: Border.all(color: Colors.white.withOpacity(0.12)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: AnimatedBuilder(
      animation: _popCtrl,
      builder: (_, _) => Transform.scale(
        scale: _popScale.value,
        child: Opacity(
          opacity: _popOpacity.value,
          child: Text(
            _denied ? 'تم الرفض' : _keyword,
            style: TextStyle(
              fontSize: _denied ? 18 : 28,
              fontWeight: FontWeight.bold,
              color: _denied ? _c3.withOpacity(0.9) : Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(color: _c1.withOpacity(0.8), blurRadius: 20),
                Shadow(color: _c2.withOpacity(0.4), blurRadius: 40),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  Widget _buildWaveform() {
    const base = [14.0, 22, 18, 26, 20, 28, 16, 24, 18, 12];
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          10,
          (i) => AnimatedBuilder(
            animation: _waveCtrl[i],
            builder: (_, _) {
              final floor = _isSpeaking ? 0.7 : 0.3;
              final h = base[i] * (floor + _waveCtrl[i].value * (1.0 - floor));
              return Container(
                width: 3.5,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: _isSpeaking ? [_c2, _c3] : [_c2, _c1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSpeaking ? _c3 : _c1).withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Particle ─────────────────────────────────────────────────────────────────
class _Particle {
  final double startX, startY, size, speed, drift, opacity;
  final Color color;
  static const _palette = [
    Color(0xFFa78bfa),
    Color(0xFF38bdf8),
    Color(0xFFf472b6),
    Color(0xFF34d399),
    Color(0xFFfbbf24),
  ];
  _Particle(Random rng)
    : startX = rng.nextDouble(),
      startY = rng.nextDouble(),
      size = 1.5 + rng.nextDouble() * 3.0,
      speed = 0.06 + rng.nextDouble() * 0.12,
      drift = rng.nextDouble() * 2 - 1,
      opacity = 0.3 + rng.nextDouble() * 0.5,
      color = _palette[rng.nextInt(_palette.length)];
}
