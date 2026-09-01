import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'models/app_state.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const SentraApp());
}

class SentraApp extends StatelessWidget {
  const SentraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider<BleService>(create: (_) => BleService()),
        Provider<SttService>(create: (_) => SttService()),
        Provider<TtsService>(create: (_) => TtsService()),
      ],
      child: MaterialApp(
        title: 'Sentra Robot Control',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}