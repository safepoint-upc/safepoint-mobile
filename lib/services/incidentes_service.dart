import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/incidente.dart';
import 'auth_service.dart';

class IncidentesService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final AuthService _auth = AuthService();

  Future<List<Incidente>> getIncidentes({
    String? sector,
    String? tipoDelito,
    String? franjaHoraria,
    String? anio,
    String? mes,
    String? diaSemana,
    int porPagina = 6000,
    int pagina = 1,
  }) async {
    try {
      final token = await _auth.getToken();
      final Map<String, dynamic> params = {
        'por_pagina': porPagina,
        'pagina': pagina,
      };
      if (sector != null && sector != 'Todos') params['sector'] = sector;
      if (tipoDelito != null && tipoDelito != 'Todos') params['tipo_delito'] = tipoDelito;
      if (franjaHoraria != null && franjaHoraria != 'Todas') params['franja_horaria'] = franjaHoraria;
      if (anio != null && anio != 'Todos') params['anio'] = anio;
      if (mes != null && mes != 'Todos') params['mes'] = mes;
      if (diaSemana != null && diaSemana != 'Todos') params['dia_semana'] = diaSemana;

      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      final response = await _dio.get(
        '/incidentes/',
        queryParameters: params,
        options: Options(headers: headers),
      );

      // El backend retorna {"total": N, "pagina": N, "por_pagina": N, "datos": [...]}
      final data = response.data;
      if (data is Map && data.containsKey('datos')) {
        return (data['datos'] as List)
            .map((i) => Incidente.fromJson(i))
            .toList();
      }
      // Fallback por si retorna lista directa
      if (data is List) {
        return data.map((i) => Incidente.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR getIncidentes: $e');
      return [];
    }
  }

  Future<List<Incidente>> getIncidentesMapa() async {
    try {
      // Endpoint is public - no auth needed
      final response = await _dio.get('/incidentes/mapa');
      debugPrint('getIncidentesMapa response type: ${response.data.runtimeType}, length: ${response.data is List ? (response.data as List).length : "N/A"}');
      if (response.data is List) {
        return (response.data as List)
            .map((i) => Incidente.fromJson(i))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR getIncidentesMapa: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final token = await _auth.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final response = await _dio.get(
        '/incidentes/estadisticas',
        options: Options(headers: headers),
      );
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getPorFranja() async {
    try {
      final token = await _auth.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final response = await _dio.get(
        '/incidentes/por-franja',
        options: Options(headers: headers),
      );
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getPorTipo() async {
    try {
      final token = await _auth.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final response = await _dio.get(
        '/incidentes/por-tipo',
        options: Options(headers: headers),
      );
      return response.data ?? {};
    } catch (e) {
      return {};
    }
  }
}
