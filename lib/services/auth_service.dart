import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';
import '../models/usuario.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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