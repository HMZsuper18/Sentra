import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BLEService {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? wifiNameChar;
  BluetoothCharacteristic? wifiPassChar;
  bool scanning = false;
  final List<BluetoothDevice> foundDevices = [];

  Future<void> init(void Function(BluetoothDevice) onFound) async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
      await startScan(onFound);
    }
  }

  Future<void> startScan(void Function(BluetoothDevice) onFound) async {
    scanning = true;
    foundDevices.clear();
    FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (result.device.platformName.startsWith('Sentra') &&
            !foundDevices.any((d) => d.remoteId == result.device.remoteId)) {
          foundDevices.add(result.device);
          onFound(result.device);
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    scanning = false;
  }

  Future<void> connect(BluetoothDevice device, {
    void Function(String)? onBoardName,
    void Function(Set<String>)? onErrors,
    void Function(String)? onDebug,
  }) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice = device;
      await discoverServices(onBoardName, onErrors, onDebug);
    } catch (e) {
      debugPrint('Connection failed: $e');
    }
  }

  Future<void> discoverServices(
    void Function(String)? onBoardName,
    void Function(Set<String>)? onErrors,
    void Function(String)? onDebug,
  ) async {
    if (connectedDevice == null) return;
    final services = await connectedDevice!.discoverServices();
    for (final service in services) {
      for (final char in service.characteristics) {
        switch (char.uuid.toString()) {
          case '12345678-1234-1234-1234-123456789001':
            wifiNameChar = char;
            break;
          case '12345678-1234-1234-1234-123456789002':
            wifiPassChar = char;
            break;
          case '12345678-1234-1234-1234-123456789003':
            char.lastValueStream.listen((value) {
              onBoardName?.call(String.fromCharCodes(value));
            });
            break;
          case '12345678-1234-1234-1234-123456789004':
            char.lastValueStream.listen((value) {
              final errors = String.fromCharCodes(value);
              onErrors?.call(errors == 'OK' || errors.isEmpty
                  ? {}
                  : errors.split(',').toSet());
            });
            break;
          case '12345678-1234-1234-1234-123456789005':
            char.lastValueStream.listen((value) {
              onDebug?.call(String.fromCharCodes(value));
            });
            break;
        }
      }
    }
  }

  Future<void> sendWifiCredentials(String name, String password) async {
    if (wifiNameChar != null) await wifiNameChar!.write(name.codeUnits);
    if (wifiPassChar != null) await wifiPassChar!.write(password.codeUnits);
  }
}