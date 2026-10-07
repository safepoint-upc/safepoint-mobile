import 'package:flutter/material.dart';
import '../../services/incidentes_service.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../widgets/bar_chart_card.dart';

/// Pantalla de estadísticas históricas (equivalente al Dashboard.jsx del web).
/// Muestra 4 gráficos: incidentes por tipo, por sector, por franja horaria y por mes.
/// Usa datos del backend vía IncidentesService.
class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final IncidentesService _service = IncidentesService();

  bool _isLoading = true;

  // Datos agrupados para los 4 gráficos
  Map<String, int> _porTipo = {};
  Map<String, int> _porSector = {};
  Map<String, int> _porFranja = {};
  Map<String, int> _porMes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getEstadisticas(),
        _service.getIncidentesPorFranja(),
        _service.getIncidentesPorTipo(),
        _service.getHistorial(),
      ]);

      final estadisticas = results[0] as Map<String, dynamic>;
      final porFranjaRaw = results[1] as List<Map<String, dynamic>>;
      final porTipoRaw = results[2] as List<Map<String, dynamic>>;
      final historialRaw = results[3] as List<Map<String, dynamic>>;

      // 1. Por Tipo (usar porTipoRaw o estadisticas['por_tipo'])
      final Map<String, int> porTipoMap = {};
      final List<dynamic> listTipo = porTipoRaw.isNotEmpty 
          ? porTipoRaw 
          : (estadisticas['por_tipo'] as List<dynamic>? ?? []);
      for (final item in listTipo) {
        final t = (item['tipo_delito'] ?? item['tipo'])?.toString() ?? 'Desconocido';
        final total = (item['total'] as num?)?.toInt() ?? 0;
        porTipoMap[t] = total;
      }

      // 2. Por Sector (usar estadisticas['por_sector'])
      final Map<String, int> porSectorMap = {};
      final List<dynamic> listSector = (estadisticas['por_sector'] as List<dynamic>? ?? []);
      for (final item in listSector) {
        final s = 'Sector ${item['sector']}';
        final total = (item['total'] as num?)?.toInt() ?? 0;
        porSectorMap[s] = total;
      }

      // 3. Por Franja
      final Map<String, int> porFranjaMap = {};
      for (final item in porFranjaRaw) {
        final franjaFull = item['franja_horaria']?.toString() ?? '';
        final key = AppConstants.franjaCorta(franjaFull);
        final total = (item['total'] as num?)?.toInt() ?? 0;
        porFranjaMap[key] = total;
      }

      // 4. Por Mes (convertir número de mes a nombre corto y ordenar cronológicamente)
      final Map<String, int> porMesMap = {};
      const nombresMeses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      for (final item in historialRaw) {
        final mesNum = (item['mes'] as num?)?.toInt() ?? 0;
        final total = (item['total'] as num?)?.toInt() ?? 0;
        if (mesNum >= 1 && mesNum <= 12) {
          final nombreMes = nombresMeses[mesNum - 1];
          porMesMap[nombreMes] = (porMesMap[nombreMes] ?? 0) + total;
        }
      }

      // Ordenar porMesMap cronológicamente
      final Map<String, int> porMesOrdenado = {};
      for (final mesName in nombresMeses) {
        if (porMesMap.containsKey(mesName)) {
          porMesOrdenado[mesName] = porMesMap[mesName]!;
        }
      }

      if (mounted) {
        setState(() {
          _porTipo = porTipoMap;
          _porSector = porSectorMap;
          _porFranja = porFranjaMap;
          _porMes = porMesOrdenado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BarChartCard(
                      titulo: 'Incidentes por Tipo de Delito',
                      data: _porTipo,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    BarChartCard(
                      titulo: 'Incidentes por Sector',
                      data: _porSector,
                      color: AppTheme.riskMed,
                    ),
                    const SizedBox(height: 16),
                    BarChartCard(
                      titulo: 'Incidentes por Franja Horaria',
                      data: _porFranja,
                      color: AppTheme.riskHigh,
                    ),
                    const SizedBox(height: 16),
                    BarChartCard(
                      titulo: 'Incidentes por Mes',
                      data: _porMes,
                      color: const Color(0xFF8b5cf6),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}