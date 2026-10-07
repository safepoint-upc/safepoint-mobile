import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/alerta.dart';

class AlertasService {
  final Dio _dio = ApiClient().dio;

  Future<List<Alerta>> getAlertasActivas() async {
    try {
      final response = await _dio.get('/alertas/activas');
      return (response.data as List)
          .map((e) => Alerta.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('ERROR getAlertasActivas: $e');
      return [];
    }
  }

  Future<List<Alerta>> getAlertas({String? sector, bool? activa}) async {
    try {
      final Map<String, dynamic> params = {};
      if (sector != null) params['sector'] = sector;
      if (activa != null) params['activa'] = activa;
      final response = await _dio.get('/alertas', queryParameters: params.isNotEmpty ? params : null);
      return (response.data as List)
          .map((e) => Alerta.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('ERROR getAlertas: $e');
      return [];
    }
  }

  Future<bool> desactivarAlerta(int id) async {
    try {
      await _dio.patch('/alertas/$id/desactivar');
      return true;
    } catch (e) {
      debugPrint('ERROR desactivarAlerta: $e');
      return false;
    }
  }
}