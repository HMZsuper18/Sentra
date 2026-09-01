import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static const String _serviceUuid = '12345678-1234-1234-1234-123456789abc';
  static const String _ssidUuid = '12345678-1234-1234-1234-123456789001';
  static const String _passwordUuid = '12345678-1234-1234-1234-123456789002';
  static const String _boardNameUuid = '12345678-1234-1234-1234-123456789003';
  static const String _errorsUuid = '12345678-1234-1234-1234-123456789004';
  static const String _debugUuid = '12345678-1234-1234-1234-123456789005';
  static const String _voiceCmdUuid = '12345678-1234-1234-1234-123456789006';
  static const String _voiceRespUuid = '12345678-1234-1234-1234-123456789007';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _ssidChar;
  BluetoothCharacteristic? _passwordChar;
  BluetoothCharacteristic? _boardNameChar;
  BluetoothCharacteristic? _errorsChar;
  BluetoothCharacteristic? _debugChar;
  BluetoothCharacteristic? _voiceCmdChar;
  BluetoothCharacteristic? _voiceRespChar;
  StreamSubscription<List<int>>? _debugSubscription;
  StreamSubscription<List<int>>? _voiceRespSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  final _debugDataController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _voiceResponseController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<String> get debugDataStream => _debugDataController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Map<String, dynamic>> get voiceResponseStream =>
      _voiceResponseController.stream;

  bool get isConnected => _connectedDevice != null;

  Future<void> initialize() async {
    try {
      FlutterBluePlus.setLogLevel(LogLevel.info, color: true);
    } catch (e) {
      debugPrint('BLE init failed (unsupported platform?): $e');
    }
  }

  Future<List<BluetoothDevice>> scanForDevices(
      {Duration timeout = const Duration(seconds: 10)}) async {
    final List<BluetoothDevice> foundDevices = [];

    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (result.device.platformName.contains('Sentra') ||
            result.device.platformName.contains('ESP32') ||
            result.advertisementData.serviceUuids.any((uuid) =>
                uuid.toString().toLowerCase() == _serviceUuid.toLowerCase())) {
          if (!foundDevices.any((d) => d.remoteId == result.device.remoteId)) {
            foundDevices.add(result.device);
          }
        }
      }
    });

    await FlutterBluePlus.startScan(
      withServices: [Guid(_serviceUuid)],
      timeout: timeout,
    );

    await Future.delayed(timeout);
    await subscription.cancel();
    await FlutterBluePlus.stopScan();

    return foundDevices;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(
          autoConnect: false, timeout: const Duration(seconds: 15));

      _connectionStateSubscription = device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected) {
          _cleanup();
        }
      });

      await _discoverServices(device);
      _connectedDevice = device;
      return true;
    } catch (e) {
      _errorController.add('Connection failed: $e');
      return false;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase()) {
        for (final characteristic in service.characteristics) {
          final uuidStr = characteristic.uuid.toString().toLowerCase();
          if (uuidStr == _ssidUuid.toLowerCase()) {
            _ssidChar = characteristic;
          } else if (uuidStr == _passwordUuid.toLowerCase()) {
            _passwordChar = characteristic;
          } else if (uuidStr == _boardNameUuid.toLowerCase()) {
            _boardNameChar = characteristic;
          } else if (uuidStr == _errorsUuid.toLowerCase()) {
            _errorsChar = characteristic;
          } else if (uuidStr == _debugUuid.toLowerCase()) {
            _debugChar = characteristic;
          } else if (uuidStr == _voiceCmdUuid.toLowerCase()) {
            _voiceCmdChar = characteristic;
          } else if (uuidStr == _voiceRespUuid.toLowerCase()) {
            _voiceRespChar = characteristic;
          }
        }
      }
    }

    if (_debugChar != null) {
      await _debugChar!.setNotifyValue(true);
      _debugSubscription = _debugChar!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          final debugStr = utf8.decode(value);
          _debugDataController.add(debugStr);
        }
      });
    }

    if (_voiceRespChar != null) {
      await _voiceRespChar!.setNotifyValue(true);
      _voiceRespSubscription = _voiceRespChar!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          try {
            final respStr = utf8.decode(value);
            final respMap = jsonDecode(respStr) as Map<String, dynamic>;
            _voiceResponseController.add(respMap);
          } catch (e) {
            _errorController.add('Failed to parse voice response: $e');
          }
        }
      });
    }

    if (_errorsChar != null) {
      final errorValue = await _errorsChar!.read();
      if (errorValue.isNotEmpty) {
        _errorController.add(utf8.decode(errorValue));
      }
    }
  }

  Future<bool> sendWiFiCredentials(String ssid, String password) async {
    if (_ssidChar == null || _passwordChar == null) {
      _errorController.add('BLE characteristics not found');
      return false;
    }

    try {
      await _ssidChar!.write(utf8.encode(ssid), withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 100));
      await _passwordChar!.write(utf8.encode(password), withoutResponse: false);
      return true;
    } catch (e) {
      _errorController.add('Failed to send WiFi credentials: $e');
      return false;
    }
  }

  Future<bool> sendVoiceCommand(String command) async {
    if (_voiceCmdChar == null) {
      _errorController.add('Voice command characteristic not found');
      return false;
    }

    try {
      await _voiceCmdChar!.write(utf8.encode(command), withoutResponse: false);
      return true;
    } catch (e) {
      _errorController.add('Failed to send voice command: $e');
      return false;
    }
  }

  Future<String?> readBoardName() async {
    if (_boardNameChar == null) return null;
    try {
      final value = await _boardNameChar!.read();
      return utf8.decode(value);
    } catch (e) {
      _errorController.add('Failed to read board name: $e');
      return null;
    }
  }

  Future<bool> writeBoardName(String name) async {
    if (_boardNameChar == null) return false;
    try {
      await _boardNameChar!.write(utf8.encode(name), withoutResponse: false);
      return true;
    } catch (e) {
      _errorController.add('Failed to write board name: $e');
      return false;
    }
  }

  Future<String?> readErrors() async {
    if (_errorsChar == null) return null;
    try {
      final value = await _errorsChar!.read();
      return utf8.decode(value);
    } catch (e) {
      _errorController.add('Failed to read errors: $e');
      return null;
    }
  }

  void _cleanup() {
    _debugSubscription?.cancel();
    _debugSubscription = null;
    _voiceRespSubscription?.cancel();
    _voiceRespSubscription = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _connectedDevice = null;
    _ssidChar = null;
    _passwordChar = null;
    _boardNameChar = null;
    _errorsChar = null;
    _debugChar = null;
    _voiceCmdChar = null;
    _voiceRespChar = null;
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _cleanup();
    }
  }

  Future<void> dispose() async {
    await disconnect();
    _connectionStateController.close();
    _debugDataController.close();
    _errorController.close();
    _voiceResponseController.close();
  }
}
