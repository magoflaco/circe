import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';
import '../models.dart';
class RealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _ping;
  void connect(String token, void Function(Measurement) onMeasurement) {
    disconnect();
    final url = '${AppConfig.wsBase}/api/v1/ws/measurements?token=$token';
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _sub = _channel!.stream.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String);
          if (msg['type'] == 'measurement') {
            onMeasurement(Measurement.fromJson(msg['data']));
          }
        } catch (_) {}
      },
      onError: (_) {},
      onDone: () {},
    );
    _ping = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add('ping');
      } catch (_) {}
    });
  }
  void disconnect() {
    _ping?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}