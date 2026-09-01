import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../models/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BleService _bleService;
  late SttService _sttService;
  late TtsService _ttsService;
  late AppState _appState;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _bleService = context.read<BleService>();
    _sttService = context.read<SttService>();
    _ttsService = context.read<TtsService>();
    _appState = context.read<AppState>();
    _initializeServices();
    _listenToBle();
  }

  Future<void> _initializeServices() async {
    await _sttService.initialize();
    await _ttsService.initialize();
    await _bleService.initialize();
  }

  void _listenToBle() {
    _subscriptions.add(_bleService.connectionStateStream.listen((state) {
      _appState.setBleConnected(state == BluetoothConnectionState.connected);
    }));

    _subscriptions.add(_bleService.voiceResponseStream.listen((response) {
      final reply = response['reply'] as String?;
      final oled = response['oled'] as String?;
      if (reply != null && reply.isNotEmpty) {
        _appState.setLastReply(reply);
        _ttsService.speak(reply);
      }
      if (oled != null) {
        _appState.setOledStatus(oled);
      }
    }));

    _subscriptions.add(_bleService.errorStream.listen((error) {
      _appState.addError(error);
    }));

    _subscriptions.add(_bleService.debugDataStream.listen((debug) {
      _appState.setDebugInfo(debug);
    }));
  }

  Future<void> _onVoiceCommandPressed() async {
    if (_appState.isProcessing) return;
    if (!_bleService.isConnected) {
      _appState.addError('Not connected to ESP32');
      return;
    }

    _appState.setProcessing(true);
    _appState.clearError();

    await _sttService.startListening(
      onResult: (text) {
        _appState.setRecognizedText(text);
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );

    await Future.delayed(const Duration(seconds: 3));
    await _sttService.stopListening();

    if (_sttService.lastWords.isNotEmpty) {
      _appState.setRecognizedText(_sttService.lastWords);
      await _bleService.sendVoiceCommand(_sttService.lastWords);
    } else {
      _appState.addError('No speech detected');
    }

    _appState.setProcessing(false);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _sttService.dispose();
    _ttsService.dispose();
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentra Robot Control'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AppState>(
            builder: (context, appState, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      appState.isBleConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: appState.isBleConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConnectionCard(appState),
                const SizedBox(height: 16),
                _buildVoiceCommandCard(appState),
                const SizedBox(height: 16),
                _buildStatusCard(appState),
                const SizedBox(height: 16),
                _buildDebugCard(appState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ESP32 Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appState.isBleConnected ? null : _scanAndConnect,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Scan & Connect'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appState.isBleConnected ? _bleService.disconnect : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
            if (appState.isBleConnected) ...[
              const SizedBox(height: 8),
              Text('Connected to ESP32', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _scanAndConnect() async {
    _appState.setScanning(true);
    _appState.clearError();

    try {
      final devices = await _bleService.scanForDevices();
      if (devices.isEmpty) {
        _appState.addError('No Sentra devices found');
      } else {
        await _bleService.connect(devices.first);
      }
    } catch (e) {
      _appState.addError('Scan failed: $e');
    } finally {
      _appState.setScanning(false);
    }
  }

  Widget _buildVoiceCommandCard(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voice Command (Egyptian Arabic)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (appState.recognizedText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  'Recognized: "${appState.recognizedText}"',
                  style: TextStyle(color: Colors.blue[800], fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: (appState.isProcessing || appState.isScanning || !appState.isBleConnected) ? null : _onVoiceCommandPressed,
                icon: appState.isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.mic, size: 32),
                label: Text(
                  appState.isProcessing ? 'Listening...' : 'Tap & Speak',
                  style: const TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appState.isProcessing ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (appState.lastReply.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Robot Reply:', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(appState.lastReply, style: TextStyle(color: Colors.green[800], fontSize: 16)),
                  ],
                ),
              ),
            ],
            if (appState.error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  appState.error,
                  style: TextStyle(color: Colors.red[800], fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Robot Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (appState.oledStatus.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  appState.oledStatus,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ] else ...[
              Text('No status yet', style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Debug Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (appState.debugInfo.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  appState.debugInfo,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ] else ...[
              Text('No debug info', style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }
}
