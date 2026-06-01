import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keySession = 'user_session';

  static Future<void> saveSession(String nome, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'nome': nome,
      'email': email,
    };
    await prefs.setString(_keySession, json.encode(data));
  }

  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_keySession);
    if (dataStr == null) return null;
    try {
      final decoded = json.decode(dataStr) as Map<String, dynamic>;
      return {
        'nome': decoded['nome']?.toString() ?? '',
        'email': decoded['email']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
  }
}
