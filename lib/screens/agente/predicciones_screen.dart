import 'package:flutter/material.dart';
import '../../services/predicciones_service.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../models/prediccion.dart';
import '../../widgets/risk_badge.dart';

/// Pantalla de predicciones XGBoost por sector/cuadrante.
/// Muestra el riesgo promedio por sector (grid + barras) y el listado
/// de últimas predicciones filtrable por sector y franja horaria.
class PrediccionesScreen extends StatefulWidget {
  const PrediccionesScreen({super.key});

  @override
  State<PrediccionesScreen> createState() => _PrediccionesScreenState();
}

class _PrediccionesScreenState extends State<PrediccionesScreen> {
  final PrediccionesService _service = PrediccionesService();

  // Predicciones agrupadas por sector: [{sector, probabilidad_promedio, total, nivel_riesgo}]
  List<Map<String, dynamic>> _sectores = [];

  // Todas las predicciones recientes y las filtradas para el listado inferior
  List<Prediccion> _ultimas = [];
  List<Prediccion> _ultimasFiltradas = [];

  bool _isLoading = true;
  String _sectorSel = 'Todos';
  String _franjaSel = 'Todas';

  // Métricas del modelo (F1-Score, precisión, recall…)
  Map<String, dynamic>? _metricas;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Carga en paralelo: predicciones por sector, últimas predicciones y métricas
      final results = await Future.wait([
        _service.getPrediccionesPorCuadrante(),   // agrupa cuadrantes → sectores
        _service.getUltimasPredicciones(),         // últimas N predicciones
        _service.getMetricas(),                    // F1-Score del modelo
      ]);

      // Agrupar cuadrantes por sector para el grid
      final porCuadrante = results[0] as List<Map<String, dynamic>>;
      final sectoresAgrupados = _agruparPorSector(porCuadrante);

      if (mounted) {
        setState(() {
          _sectores = sectoresAgrupados;
          _ultimas = results[1] as List<Prediccion>;
          _ultimasFiltradas = _ultimas;
          _metricas = results[2] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Agrupa predicciones por cuadrante en sectores, promediando probabilidades.
  List<Map<String, dynamic>> _agruparPorSector(List<Map<String, dynamic>> porCuadrante) {
    final Map<String, List<double>> probsPorSector = {};

    for (final pred in porCuadrante) {
      final cuadrante = pred['cuadrante']?.toString() ?? '';
      // Detectar sector a partir del primer carácter numérico del cuadrante (ej. '3B1' → '3')
      final sectorMatch = RegExp(r'^(\d+)').firstMatch(cuadrante);
      final sector = sectorMatch?.group(1) ?? '?';
      final prob = (pred['probabilidad_promedio'] as num?)?.toDouble() ?? 0.0;
      probsPorSector.putIfAbsent(sector, () => []).add(prob);
    }

    return probsPorSector.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return {
        'sector': e.key,
        'probabilidad': avg,
        'total_cuadrantes': e.value.length,
      };
    }).toList()
      ..sort((a, b) => (a['sector'] as String).compareTo(b['sector'] as String));
  }

  /// Aplica filtros de sector y franja al listado de últimas predicciones.
  void _aplicarFiltros() {
    setState(() {
      _ultimasFiltradas = _ultimas.where((p) {
        final sectorPred = p.sector ?? '';
        final franjaPred = p.franjaHoraria ?? '';
        final matchSector = _sectorSel == 'Todos' || sectorPred == _sectorSel.replaceAll('Sector ', '');
        final matchFranja = _franjaSel == 'Todas' || franjaPred == _franjaSel;
        return matchSector && matchFranja;
      }).toList();
    });
  }

  /// Color según nivel de riesgo (0=bajo, 1=medio, 2=alto) o probabilidad.
  Color _colorRiesgo(double prob) {
    if (prob > 0.66) return AppTheme.riskHigh;
    if (prob >= 0.33) return AppTheme.riskMed;
    return AppTheme.riskLow;
  }

  String _textoRiesgo(double prob) {
    if (prob > 0.66) return 'ALTO';
    if (prob >= 0.33) return 'MEDIO';
    return 'BAJO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Predicciones XGBoost'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSectorGrid(),
              const SizedBox(height: 24),
              _buildBarChart(),
              const SizedBox(height: 24),
              _buildFiltros(),
              const SizedBox(height: 12),
              _buildListadoUltimas(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header con info del modelo ──────────────────────────────────────────────
  Widget _buildHeader() {
    final f1 = _metricas?['f1_score'];
    final f1Text = f1 != null ? '${(f1 * 100).toStringAsFixed(1)}%' : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evaluación Predictiva por Sector',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricChip(label: 'Modelo', value: 'XGBoost v3.1'),
              const SizedBox(width: 8),
              _MetricChip(label: 'F1-Score', value: f1Text, color: AppTheme.primary),
              const SizedBox(width: 8),
              _MetricChip(
                label: 'Actualizado',
                value: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Grid 2 columnas con tarjeta por sector ──────────────────────────────────
  Widget _buildSectorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _sectores.length,
      itemBuilder: (context, index) {
        final s = _sectores[index];
        final prob = (s['probabilidad'] as double?) ?? 0.0;
        final color = _colorRiesgo(prob);
        final riesgo = _textoRiesgo(prob);
        final nombre = AppConstants.nombresSectores[s['sector']] ?? '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sector ${s['sector']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(riesgo, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              // Nombre geográfico del sector
              if (nombre.isNotEmpty)
                Text(nombre, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Riesgo Promedio', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(
                    '${(prob * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: prob,
                      backgroundColor: AppTheme.background,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Gráfico de barras horizontales comparativo ──────────────────────────────
  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparativo de Probabilidad por Sector',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Umbral de alerta: 50%', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 16),
          ..._sectores.map((s) {
            final prob = (s['probabilidad'] as double?) ?? 0.0;
            final color = _colorRiesgo(prob);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: Text('Sector ${s['sector']}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Fondo de la barra
                        Container(height: 20, decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4))),
                        // Barra de progreso
                        FractionallySizedBox(
                          widthFactor: prob.clamp(0.0, 1.0),
                          child: Container(height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                        ),
                        // Línea vertical de referencia al 50%
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(width: 1.5, height: 20, color: AppTheme.riskHigh.withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(
                      ' ${(prob * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Filtros de sector y franja para el listado ──────────────────────────────
  Widget _buildFiltros() {
    final sectoresOpciones = ['Todos', ...List.generate(9, (i) => 'Sector ${i + 1}')];
    final franjasOpciones = ['Todas', ...AppConstants.franjasHorarias];

    return Row(
      children: [
        Expanded(
          child: _DropdownFilter(
            label: 'Sector',
            value: _sectorSel,
            items: sectoresOpciones,
            onChanged: (v) { setState(() => _sectorSel = v); _aplicarFiltros(); },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DropdownFilter(
            label: 'Franja',
            value: _franjaSel,
            items: franjasOpciones,
            onChanged: (v) { setState(() => _franjaSel = v); _aplicarFiltros(); },
          ),
        ),
      ],
    );
  }

  // ── Listado de últimas predicciones ────────────────────────────────────────
  Widget _buildListadoUltimas() {
    if (_ultimasFiltradas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sin predicciones para los filtros seleccionados',
              style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimas predicciones (${_ultimasFiltradas.length})',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._ultimasFiltradas.take(50).map((p) {
          final prob = p.probabilidad;
          final color = _colorRiesgo(prob);
          final franja = AppConstants.franjaCorta(p.franjaHoraria ?? '');
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${(prob * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuadrante ${p.cuadrante ?? '—'} · Sector ${p.sector ?? '—'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(franja, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                RiskBadge(nivelRiesgo: p.nivelRiesgo ?? 0),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppTheme.surface,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        icon: const Icon(Icons.expand_more, color: AppTheme.textMuted, size: 18),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}