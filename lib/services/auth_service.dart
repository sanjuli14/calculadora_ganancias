import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // CAMBIA ESTA URL por la "raw" de tu Gist (te explico cómo obtenerla al final)
  static const String _licensesUrl =
      'https://gist.githubusercontent.com/sanjuli14/f97f96cbd48c14e27ff5f5debd03b8b4/raw/clients.json';

  static const String _salt = 'CC-SALT-2026';
  static const String _boxName = 'licenses';
  static const String _deviceKey = 'device_id';
  static const String _cacheKey = 'clients_cache';
  static const String _loggedKey = 'logged_in';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    if (_box.get(_deviceKey) == null) {
      await _box.put(_deviceKey, _generateDeviceId());
    }
  }

  String get deviceId => _box.get(_deviceKey) as String;

  // La sesión queda guardada en el teléfono: si Android reinicia la app
  // (por ejemplo al volver del selector de archivos), no se vuelve a pedir login.
  // El box "licenses" se abre como Box<String>, así que la sesión se guarda
  // como texto ("true"/"false") para respetar el tipo del box.
  bool get isLoggedIn => _box.get(_loggedKey, defaultValue: '') == 'true';

  Future<void> markLoggedIn() async {
    await _box.put(_loggedKey, 'true');
  }

  Future<void> markLoggedOut() async {
    await _box.put(_loggedKey, 'false');
  }

  List<String> _cachedClients() {
    final cached = _box.get(_cacheKey);
    if (cached == null) return const [];
    try {
      return (jsonDecode(cached) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> refreshClients() async {
    try {
      final response = await http
          .get(Uri.parse(_licensesUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawClients = data['clients'] as List;
        final clients = rawClients.map((c) {
          // El Gist puede guardar cada cliente como:
          //   - un objeto: {"name": "Panadería", "hash": "..."}  (formato nuevo)
          //   - un string: el hash directamente                  (formato anterior)
          if (c is Map) return c['hash'] as String;
          return c as String;
        }).toList();
        if (clients.isEmpty) return false;
        await _box.put(_cacheKey, jsonEncode(clients));
        return true;
      }
      return false;
    } on FormatException {
      // El Gist no devolvió un JSON válido (puede estar roto o con formato incorrecto).
      return false;
    } catch (_) {
      // Sin conexión o error de red: se usa la lista guardada en el teléfono.
      return false;
    }
  }

  bool validateCode(String code) {
    final hash = _hash(code);
    return _cachedClients().any((c) => _constantTimeEquals(c, hash));
  }

  String _hash(String code) {
    final bytes = utf8.encode('$_salt:$deviceId:$code');
    return sha256.convert(bytes).toString();
  }

  String _generateDeviceId() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final part = () => List.generate(4, (_) => alphabet[random.nextInt(alphabet.length)]).join();
    return '${part()}-${part()}';
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
