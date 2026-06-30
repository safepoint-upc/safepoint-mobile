import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/alerta.dart';
import 'auth_service.dart';

class AlertasService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final AuthService _auth = AuthService();

  Future<List<Alerta>> getAlertasActivas({String? sector}) async {
    try {
      final token = await _auth.getToken();
      if (token == null) return [];
      final Map<String, dynamic> params = {};
      if (sector != null) params['sector'] = sector;
      final response = await _dio.get(
        '/alertas/activas',
        queryParameters: params.isNotEmpty ? params : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((i) => Alerta.fromJson(i))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR getAlertasActivas: $e');
      return [];
    }
  }

  Future<bool> desactivarAlerta(int id) async {
    try {
      final token = await _auth.getToken();
      if (token == null) return false;
      await _dio.put(
        '/alertas/$id/desactivar',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      debugPrint('ERROR desactivarAlerta: $e');
      return false;
    }
  }
}
