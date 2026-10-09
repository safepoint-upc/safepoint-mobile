import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/prediccion.dart';

class PrediccionesService {
  final Dio _dio = ApiClient().dio;

  // Obtiene predicciones con coordenadas para mostrar en el mapa
  // Filtra por franja horaria, sector y/o fecha
  Future<List<Prediccion>> getPrediccionesMapa({
    String? franjaHoraria,
    String? sector,
    DateTime? fecha,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (franjaHoraria != null) params['franja_horaria'] = franjaHoraria;
      if (sector != null) params['sector'] = sector;
      if (fecha != null) params['fecha'] = fecha.toIso8601String().split('T').first;

      final response = await _dio.get(
        '/predicciones/mapa',
        queryParameters: params.isNotEmpty ? params : null,
      );
      return (response.data as List)
          .map((e) => Prediccion.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('ERROR getPrediccionesMapa: $e');
      return [];
    }
  }

  // Obtiene las últimas 50 predicciones generadas por el modelo XGBoost
  Future<List<Prediccion>> getUltimasPredicciones() async {
    try {
      final response = await _dio.get('/predicciones/ultimas');
      return (response.data as List)
          .map((e) => Prediccion.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('ERROR getUltimasPredicciones: $e');
      return [];
    }
  }

  // Obtiene predicciones agrupadas por sector con probabilidad promedio
  // Útil para mostrar resumen por sector en el home del agente
  Future<List<Map<String, dynamic>>> getPrediccionesPorSector({
    String? franjaHoraria,
    DateTime? fecha,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (franjaHoraria != null) params['franja_horaria'] = franjaHoraria;
      if (fecha != null) params['fecha'] = fecha.toIso8601String().split('T').first;

      final response = await _dio.get(
        '/predicciones/por-sector',
        queryParameters: params.isNotEmpty ? params : null,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('ERROR getPrediccionesPorSector: $e');
      return [];
    }
  }

  // Obtiene todas las predicciones y devuelve la lista cruda con cuadrante, sector y nivel_riesgo.
  // Igual que hace el dashboard web con getPredicciones({ por_pagina: 6000 }).
  // Si se pasa franjaHoraria se filtra por ella (usado en las pantallas de mapa).
  // Desde home_screen se llama sin filtros para obtener todos los datos como el web.
  Future<List<Map<String, dynamic>>> getPrediccionesPorCuadrante({
    String? franjaHoraria,
    DateTime? fecha,
  }) async {
    try {
      final Map<String, dynamic> params = {'pagina': 1, 'por_pagina': 6000};
      if (franjaHoraria != null) params['franja_horaria'] = franjaHoraria;
      if (fecha != null) params['fecha'] = fecha.toIso8601String().split('T').first;

      final response = await _dio.get('/predicciones/', queryParameters: params);
      final List<dynamic> data = response.data['datos'] ?? [];
      return data
          .where((item) => item['cuadrante'] != null)
          .map((item) => {
                'cuadrante': item['cuadrante']?.toString() ?? '',
                'sector': item['sector']?.toString() ?? '',
                'nivel_riesgo': item['nivel_riesgo'] as int?,
                'probabilidad': (item['probabilidad'] as num?)?.toDouble() ?? 0.0,
              })
          .toList();
    } catch (e) {
      debugPrint('ERROR getPrediccionesPorCuadrante: $e');
      return [];
    }
  }

  // Obtiene las métricas del modelo XGBoost — F1-Score, AUC, precisión, etc.
  Future<Map<String, dynamic>> getMetricas() async {
    try {
      final response = await _dio.get('/metricas/');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('ERROR getMetricas: $e');
      return {};
    }
  }
}