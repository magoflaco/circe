import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_biomedico/config.dart';
void main() {
  test('La configuración deriva la URL del WebSocket desde la API', () {
    expect(AppConfig.wsBase.startsWith('ws'), isTrue);
    expect(AppConfig.appName, 'Monitor Biomédico');
  });
}