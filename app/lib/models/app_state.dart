import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool _isBleConnected = false;
  bool _isProcessing = false;
  bool _isScanning = false;
  String _recognizedText = '';
  String _lastReply = '';
  String _oledStatus = '';
  String _debugInfo = '';
  String _error = '';

  bool get isBleConnected => _isBleConnected;
  bool get isProcessing => _isProcessing;
  bool get isScanning => _isScanning;
  String get recognizedText => _recognizedText;
  String get lastReply => _lastReply;
  String get oledStatus => _oledStatus;
  String get debugInfo => _debugInfo;
  String get error => _error;

  void setBleConnected(bool connected) {
    _isBleConnected = connected;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  void setRecognizedText(String text) {
    _recognizedText = text;
    notifyListeners();
  }

  void setLastReply(String reply) {
    _lastReply = reply;
    notifyListeners();
  }

  void setOledStatus(String status) {
    _oledStatus = status;
    notifyListeners();
  }

  void setDebugInfo(String info) {
    _debugInfo = info;
    notifyListeners();
  }

  void addError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearAll() {
    _recognizedText = '';
    _lastReply = '';
    _oledStatus = '';
    _debugInfo = '';
    _error = '';
    notifyListeners();
  }
}