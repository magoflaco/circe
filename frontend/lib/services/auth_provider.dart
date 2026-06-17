import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
class AuthProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  bool _loading = true;
  bool get loading => _loading;
  String? _email;
  String? get email => _email;
  String? _name;
  String? get name => _name;
  String get displayName {
    final n = _name?.trim();
    if (n != null && n.isNotEmpty) {
      return n.split(RegExp(r'\s+')).first;
    }
    final e = _email;
    if (e != null && e.contains('@')) {
      final first = e.split('@').first.split(RegExp(r'[._-]')).first;
      if (first.isNotEmpty) {
        return first[0].toUpperCase() + first.substring(1);
      }
    }
    return 'Paciente';
  }
  bool _verified = false;
  bool get isVerified => _verified;
  bool get isAuthenticated => api.token != null;
  static const _kToken = 'auth_token';
  static const _kEmail = 'auth_email';
  static const _kName = 'auth_name';
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kToken);
    if (t != null) {
      api.token = t;
      _email = prefs.getString(_kEmail);
      _name = prefs.getString(_kName);
      try {
        final me = await api.me();
        _email = me['email'];
        _name = me['full_name'] as String?;
        _verified = me['is_verified'] == true;
        final p = await SharedPreferences.getInstance();
        if (_name != null) await p.setString(_kName, _name!);
      } catch (_) {
        await logout();
      }
    }
    _loading = false;
    notifyListeners();
  }
  Future<void> refreshMe() async {
    try {
      final me = await api.me();
      _email = me['email'];
      _name = me['full_name'] as String?;
      _verified = me['is_verified'] == true;
      final prefs = await SharedPreferences.getInstance();
      if (_name != null) await prefs.setString(_kName, _name!);
      notifyListeners();
    } catch (_) {}
  }
  Future<void> verifyOtp(String code) async {
    if (_email == null) return;
    await api.verifyOtp(_email!, code);
    _verified = true;
    notifyListeners();
  }
  Future<String> resendCode() async =>
      _email != null ? api.resendCode(_email!) : '';
  Future<String> forgotPassword(String email) => api.forgotPassword(email);
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final token = await api.resetPassword(email, code, newPassword);
    api.token = token;
    try {
      final me = await api.me();
      _verified = me['is_verified'] == true;
    } catch (_) {}
    await _save(token, email);
    notifyListeners();
  }
  Future<void> _save(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kEmail, email);
    if (_name != null) await prefs.setString(_kName, _name!);
    api.token = token;
    _email = email;
  }
  Future<void> login(String email, String password) async {
    final token = await api.login(email, password);
    api.token = token;
    try {
      final me = await api.me();
      _verified = me['is_verified'] == true;
      _name = me['full_name'] as String?;
    } catch (_) {
      _verified = false;
    }
    await _save(token, email);
    notifyListeners();
  }
  Future<void> register(String email, String password, String? name) async {
    final token = await api.register(email, password, name);
    _verified = false;
    _name = name;
    await _save(token, email);
    notifyListeners();
  }
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kEmail);
    await prefs.remove(_kName);
    api.token = null;
    _email = null;
    _name = null;
    _verified = false;
    notifyListeners();
  }
}