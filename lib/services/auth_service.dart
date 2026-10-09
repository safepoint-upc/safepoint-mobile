import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';
import '../models/usuario.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Lee el token guardado localmente y decodifica el payload del JWT
  /// SIN hacer ninguna llamada a red. Retorna null si no hay token o es inválido.
  Future<Usuario?> getUserFromToken() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) return null;

      // Un JWT tiene 3 partes separadas por '.': header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // El payload está en Base64Url — normalizamos a Base64 estándar
      String payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final decoded =
          json.decode(utf8.decode(base64Decode(payload))) as Map<String, dynamic>;
      final email = decoded['sub'] as String? ?? '';
      final rol = decoded['rol'] as String? ?? 'ciudadano';

      if (email.isEmpty) return null;

      // Construimos el Usuario con los datos del token (id=0 porque es lectura local)
      return Usuario(
        id: 0,
        nombre: email.split('@').first,
        email: email,
        rol: rol,
      );
    } catch (e) {
      debugPrint('ERROR getUserFromToken: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login-mobile',
        data: {'email': email, 'password': password},
      );
      final token = response.data['access_token'];
      await _storage.write(key: 'token', value: token);
      final usuario = await getMe();
      return {'success': true, 'usuario': usuario};
    } catch (e) {
      debugPrint('ERROR LOGIN: $e');
      return {'success': false, 'message': 'Credenciales inválidas'};
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Usuario?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return Usuario.fromJson(response.data);
    } catch (e) {
      debugPrint('ERROR getMe: $e');
      return null;
    }
  }
}