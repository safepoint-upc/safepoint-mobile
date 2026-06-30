import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../models/usuario.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.data}');
      
      final token = response.data['access_token'];
      await _storage.write(key: 'token', value: token);
      final usuario = await getMe();
      return {'success': true, 'usuario': usuario};
    } catch (e) {
      debugPrint('ERROR LOGIN: $e');
      if (e is DioException) {
        debugPrint('ERROR STATUS: ${e.response?.statusCode}');
        debugPrint('ERROR DATA: ${e.response?.data}');
      }
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
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
