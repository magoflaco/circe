import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}
class ApiService {
  String? _token;
  set token(String? t) => _token = t;
  String? get token => _token;
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
  Uri _u(String path) => Uri.parse('${AppConfig.apiBase}$path');
  dynamic _decode(http.Response r) {
    final body = r.body.isNotEmpty ? jsonDecode(r.body) : null;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final detail = body is Map ? body['detail'] : null;
    throw ApiException(
      detail?.toString() ?? 'Error ${r.statusCode}',
      r.statusCode,
    );
  }
  Future<String> register(String email, String password, String? name) async {
    final r = await http.post(_u('/api/v1/auth/register'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password, 'full_name': name}));
    return _decode(r)['access_token'];
  }
  Future<String> login(String email, String password) async {
    final r = await http.post(_u('/api/v1/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}));
    return _decode(r)['access_token'];
  }
  Future<Map<String, dynamic>> me() async {
    final r = await http.get(_u('/api/v1/auth/me'), headers: _headers);
    return _decode(r);
  }
  Future<void> verifyOtp(String email, String code) async {
    final r = await http.post(_u('/api/v1/auth/verify'),
        headers: _headers, body: jsonEncode({'email': email, 'code': code}));
    _decode(r);
  }
  Future<String> resendCode(String email) async {
    final r = await http.post(_u('/api/v1/auth/resend-code'),
        headers: _headers, body: jsonEncode({'email': email}));
    return _decode(r)['message'];
  }
  Future<String> forgotPassword(String email) async {
    final r = await http.post(_u('/api/v1/auth/forgot-password'),
        headers: _headers, body: jsonEncode({'email': email}));
    return _decode(r)['message'];
  }
  Future<String> resetPassword(String email, String code, String newPassword) async {
    final r = await http.post(_u('/api/v1/auth/reset-password'),
        headers: _headers,
        body: jsonEncode(
            {'email': email, 'code': code, 'new_password': newPassword}));
    return _decode(r)['access_token'];
  }
  Future<HealthProfile> getProfile() async {
    final r = await http.get(_u('/api/v1/users/profile'), headers: _headers);
    return HealthProfile.fromJson(_decode(r));
  }
  Future<HealthProfile> updateProfile(HealthProfile p) async {
    final r = await http.put(_u('/api/v1/users/profile'),
        headers: _headers, body: jsonEncode(p.toJson()));
    return HealthProfile.fromJson(_decode(r));
  }
  Future<String> deleteMyData() async {
    final r = await http.post(_u('/api/v1/users/delete-data'), headers: _headers);
    return _decode(r)['message'];
  }
  Future<List<Measurement>> measurements({int limit = 50}) async {
    final r = await http.get(_u('/api/v1/measurements?limit=$limit'),
        headers: _headers);
    return (_decode(r) as List).map((e) => Measurement.fromJson(e)).toList();
  }
  Future<Measurement?> latest() async {
    final r = await http.get(_u('/api/v1/measurements/latest'), headers: _headers);
    final data = _decode(r);
    return data == null ? null : Measurement.fromJson(data);
  }
  Future<List<Alert>> alerts({int limit = 50}) async {
    final r = await http.get(_u('/api/v1/alerts?limit=$limit'), headers: _headers);
    return (_decode(r) as List).map((e) => Alert.fromJson(e)).toList();
  }
  Future<List<Device>> devices() async {
    final r = await http.get(_u('/api/v1/devices'), headers: _headers);
    return (_decode(r) as List).map((e) => Device.fromJson(e)).toList();
  }
  Future<Device> pairDevice(String code, {String? name}) async {
    final r = await http.post(_u('/api/v1/devices/pair'),
        headers: _headers,
        body: jsonEncode({'pairing_code': code, 'name': name}));
    return Device.fromJson(_decode(r));
  }
  Future<void> unpairDevice(int id) async {
    final r = await http.delete(_u('/api/v1/devices/$id'), headers: _headers);
    if (r.statusCode >= 300) _decode(r);
  }
  Future<Device> configureDevice(int id,
      {String? name, String? mode, List<String>? smsNumbers}) async {
    final r = await http.put(_u('/api/v1/devices/$id/config'),
        headers: _headers,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (mode != null) 'mode': mode,
          if (smsNumbers != null) 'sms_numbers': smsNumbers,
        }));
    return Device.fromJson(_decode(r));
  }
  Future<String> recommendation() async {
    final r = await http.get(_u('/api/v1/ai/recommendation'), headers: _headers);
    return _decode(r)['recommendation'];
  }
  Future<String> chat(String message) async {
    final r = await http.post(_u('/api/v1/ai/chat'),
        headers: _headers, body: jsonEncode({'message': message}));
    return _decode(r)['reply'];
  }
  Future<String> suggest(String message) async {
    final r = await http.post(_u('/api/v1/ai/suggest'),
        headers: _headers, body: jsonEncode({'message': message}));
    return _decode(r)['reply'];
  }
  Future<List<ChatMessage>> chatHistory() async {
    final r = await http.get(_u('/api/v1/ai/chat/history'), headers: _headers);
    return (_decode(r) as List)
        .map((e) => ChatMessage(e['role'], e['content']))
        .toList();
  }
}