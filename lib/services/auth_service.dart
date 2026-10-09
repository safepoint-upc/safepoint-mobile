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

      final parts = token.split('.');
      if (parts.length != 3) return null;

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
      if (token == null) return {'success': false, 'message': 'Token no recibido'};
      await _storage.write(key: 'token', value: token);

      // Decodificación de respaldo inmediata del JWT
      Usuario? usuario = await getUserFromToken();

      // Intentar obtener perfil completo de getMe() sin romper si falla
      try {
        final me = await getMe();
        if (me != null) usuario = me;
      } catch (e) {
        debugPrint('WARN getMe tras login: $e');
      }

      if (usuario == null) return {'success': false, 'message': 'No se pudo leer el usuario'};

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