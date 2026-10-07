import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/incidente.dart';

class IncidentesService {
  final Dio _dio = ApiClient().dio;

  // Obtiene incidentes con coordenadas para mostrar en el mapa
  Future<List<Incidente>> getIncidentesMapa({
    String? sector,
    String? tipoDelito,
    String? franjaHoraria,
    int? anio,
    String? mes,
    String? diaSemana,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (sector != null) params['sector'] = sector;
      if (tipoDelito != null) params['tipo_delito'] = tipoDelito;
      if (franjaHoraria != null) params['franja_horaria'] = franjaHoraria;
      if (anio != null) params['anio'] = anio;
      if (mes != null) params['mes'] = mes;
      if (diaSemana != null) params['dia_semana'] = diaSemana;

      final response = await _dio.get(
        '/incidentes/mapa',
        queryParameters: params.isNotEmpty ? params : null,
      );
      return (response.data as List)
          .map((e) => Incidente.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('ERROR getIncidentesMapa: $e');
      return [];
    }
  }

  // Obtiene estadísticas generales: total, por tipo de delito y por sector
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final response = await _dio.get('/incidentes/estadisticas');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('ERROR getEstadisticas: $e');
      return {};
    }
  }

  // Obtiene cantidad de incidentes agrupados por franja horaria
  // Útil para gráficas en la pantalla de estadísticas
  Future<List<Map<String, dynamic>>> getIncidentesPorFranja({
    String? sector,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (sector != null) params['sector'] = sector;

      final response = await _dio.get(
        '/incidentes/por-franja',
        queryParameters: params.isNotEmpty ? params : null,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('ERROR getIncidentesPorFranja: $e');
      return [];
    }
  }

  // Obtiene cantidad de incidentes agrupados por tipo de delito
  Future<List<Map<String, dynamic>>> getIncidentesPorTipo({
    String? sector,
    String? franjaHoraria,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (sector != null) params['sector'] = sector;
      if (franjaHoraria != null) params['franja_horaria'] = franjaHoraria;

      final response = await _dio.get(
        '/incidentes/por-tipo',
        queryParameters: params.isNotEmpty ? params : null,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('ERROR getIncidentesPorTipo: $e');
      return [];
    }
  }

  // Obtiene la matriz semanal de incidentes por día y franja horaria
  // Se usa para el heatmap en la pantalla de estadísticas
  Future<List<Map<String, dynamic>>> getMatrizSemanal() async {
    try {
      final response = await _dio.get('/incidentes/matriz-semanal');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('ERROR getMatrizSemanal: $e');
      return [];
    }
  }

  // Obtiene historial de incidentes agrupados por año y mes en orden cronológico
  Future<List<Map<String, dynamic>>> getHistorial() async {
    try {
      final response = await _dio.get('/incidentes/historial');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      debugPrint('ERROR getHistorial: $e');
      return [];
    }
  }
}