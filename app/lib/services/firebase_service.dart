import 'dart:convert';
import 'package:http/http.dart' as http;

const String _dbUrl =
    'https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/command/word.json';
const String _dbStreamUrl =
    'https://sentra-3ca66-default-rtdb.europe-west1.firebasedatabase.app/command/word.json?auth=zuUhC4VNiO0quwQ3JlmtH6hLf2Lx8YvODFCCuZVC';

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

Future<void> sendToFirebase(String keyword) async {
  try {
    await http.put(
      Uri.parse(_dbUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'word': keyword}),
    );
  } catch (_) {}
}