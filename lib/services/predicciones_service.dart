import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/prediccion.dart';
import 'auth_service.dart';

class PrediccionesService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final AuthService _auth = AuthService();

  // Usado en PrediccionesScreen — retorna predicciones agrupadas por sector
  Future<List<Prediccion>> getPrediccionesPorSector() async {
    try {
      final token = await _auth.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final response = await _dio.get(
        '/predicciones/por-sector',
        options: Options(headers: headers),
      );
      // El endpoint retorna lista de objetos con sector, tipo_delito, probabilidad promedio, etc.
      if (response.data is List) {
        return (response.data as List)
            .map((i) => Prediccion.fromJson(i))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR getPrediccionesPorSector: $e');
      return [];
    }
  }

  // Usado en el mapa — retorna predicciones para colorear polígonos
  Future<List<Prediccion>> getPrediccionesMapa() async {
    try {
      // Endpoint is public - no auth needed
      final response = await _dio.get('/predicciones/mapa');
      debugPrint('getPrediccionesMapa response type: ${response.data.runtimeType}, length: ${response.data is List ? (response.data as List).length : "N/A"}');
      if (response.data is List) {
        return (response.data as List)
            .map((i) => Prediccion.fromJson(i))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR getPrediccionesMapa: $e');
      return [];
    }
  }

  // Últimas predicciones generadas
  Future<List<Prediccion>> getUltimas() async {
    try {
      final token = await _auth.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final response = await _dio.get(
        '/predicciones/ultimas',
        options: Options(headers: headers),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((i) => Prediccion.fromJson(i))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR getUltimas: $e');
      return [];
    }
  }

  // Métricas del modelo
  Future<Map<String, dynamic>> getMetricas() async {
    try {
      final token = await _auth.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final response = await _dio.get(
        '/metricas/',
        options: Options(headers: headers),
      );
      return response.data ?? {};
    } catch (e) {
      debugPrint('ERROR getMetricas: $e');
      return {};
    }
  }
}
