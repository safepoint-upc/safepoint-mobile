import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final AuthService _auth = AuthService();

  List<Map<String, dynamic>> _porFranja = [];
  List<Map<String, dynamic>> _porTipo = [];
  Map<String, dynamic> _estadisticas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = await _auth.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};
      final opts = Options(headers: headers);

      final results = await Future.wait([
        _dio.get('/incidentes/por-franja', options: opts),
        _dio.get('/incidentes/por-tipo', options: opts),
        _dio.get('/incidentes/estadisticas', options: opts),
      ]);

      if (mounted) {
        setState(() {
          // /por-franja returns List<{franja_horaria, cantidad}>
          if (results[0].data is List) {
            _porFranja = (results[0].data as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          // /por-tipo returns List<{tipo_delito, cantidad}>
          if (results[1].data is List) {
            _porTipo = (results[1].data as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          // /estadisticas returns {total_incidentes, por_tipo_delito, por_sector}
          if (results[2].data is Map) {
            _estadisticas = Map<String, dynamic>.from(results[2].data);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR estadisticas ciudadano: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen general
                    _buildResumenCard(),
                    const SizedBox(height: 20),
                    // Gráfico de barras por franja horaria
                    _buildSectionTitle('Incidentes por Franja Horaria', Icons.access_time),
                    const SizedBox(height: 12),
                    _buildBarChartCard(),
                    const SizedBox(height: 20),
                    // Lista de tipos de delito
                    _buildSectionTitle('Tipos de Delito más Frecuentes', Icons.warning_amber_rounded),
                    const SizedBox(height: 12),
                    _buildTiposDelitoCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildResumenCard() {
    final total = _estadisticas['total_incidentes'] ?? 0;
    final cantidadTipos = (_estadisticas['por_tipo_delito'] as List?)?.length ?? _porTipo.length;
    
    int cantidadSectores = 0;
    if (_estadisticas['por_sector'] is List) {
      final sectores = _estadisticas['por_sector'] as List;
      cantidadSectores = sectores.where((s) {
        final nombre = s['sector']?.toString().trim() ?? '';
        return nombre.isNotEmpty && nombre != 'null' && nombre != '0' && nombre != 'Desconocido';
      }).length;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(Icons.report_outlined, '$total', 'Incidentes'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.category_outlined, '$cantidadTipos', 'Tipos'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.map_outlined, '$cantidadSectores', 'Sectores'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard() {
    if (_porFranja.isEmpty) {
      return _buildEmptyCard('No hay datos de franjas horarias');
    }

    final maxCantidad = _porFranja.map((e) => (e['cantidad'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCantidad * 1.2,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < _porFranja.length) {
                      final franja = _porFranja[value.toInt()]['franja_horaria'] ?? '';
                      // Show abbreviated franja
                      final parts = franja.toString().split(' - ');
                      final abbr = parts.isNotEmpty ? parts[0].substring(0, parts[0].length > 5 ? 5 : parts[0].length) : franja;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(abbr, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: maxCantidad / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppTheme.border.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _porFranja.asMap().entries.map((entry) {
              final cantidad = (entry.value['cantidad'] as num).toDouble();
              final ratio = cantidad / maxCantidad;
              final color = ratio > 0.7
                  ? AppTheme.riskHigh
                  : ratio > 0.4
                      ? AppTheme.riskMed
                      : AppTheme.primary;
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: cantidad,
                    color: color,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxCantidad * 1.2,
                      color: AppTheme.surfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppTheme.surface,
                getTooltipItem: (group, groupIdx, rod, rodIdx) {
                  final franja = _porFranja[group.x.toInt()]['franja_horaria'] ?? '';
                  return BarTooltipItem(
                    '$franja\n${rod.toY.toInt()} incidentes',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTiposDelitoCard() {
    if (_porTipo.isEmpty) {
      return _buildEmptyCard('No hay datos de tipos de delito');
    }

    final colors = [
      AppTheme.riskHigh,
      const Color(0xFFf97316),
      AppTheme.primary,
      const Color(0xFF22c55e),
      const Color(0xFF8b5cf6),
      const Color(0xFF14b8a6),
      const Color(0xFFec4899),
      const Color(0xFF64748b),
    ];

    final maxCantidad = _porTipo.isNotEmpty
        ? _porTipo.map((e) => (e['cantidad'] as num).toDouble()).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: _porTipo.asMap().entries.map((entry) {
          final idx = entry.key;
          final data = entry.value;
          final tipo = data['tipo_delito'] ?? 'Desconocido';
          final cantidad = (data['cantidad'] as num).toInt();
          final color = colors[idx % colors.length];
          final ratio = cantidad / maxCantidad;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tipo,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '$cantidad',
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
