import 'package:flutter/material.dart';
import '../../services/predicciones_service.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../models/prediccion.dart';
import '../../widgets/risk_badge.dart';

/// Pantalla de Predicciones del Modelo XGBoost.
/// Replicada desde el dashboard web con alta fidelidad y optimizada para mobile.
class PrediccionesScreen extends StatefulWidget {
  const PrediccionesScreen({super.key});

  @override
  State<PrediccionesScreen> createState() => _PrediccionesScreenState();
}

class _PrediccionesScreenState extends State<PrediccionesScreen> {
  final PrediccionesService _prediccionesService = PrediccionesService();

  List<Prediccion> _predicciones = [];
  bool _isLoading = true;
  String _sectorSeleccionado = 'Todos'; // 'Todos', 'Sector 1'...'Sector 9'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final franjaActual = AppConstants.getFranjaActual();
      final data = await _prediccionesService.getPrediccionesMapa(
        franjaHoraria: franjaActual,
      );
      if (mounted) {
        setState(() {
          _predicciones = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar predicciones: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Cálculo local de KPIs ──────────────────────────────────────────────────
  int get _altoCount => _predicciones.where((p) => p.nivelRiesgo == 2).length;
  int get _medioCount => _predicciones.where((p) => p.nivelRiesgo == 1).length;
  int get _bajoCount => _predicciones.where((p) => p.nivelRiesgo == 0).length;
  int get _totalCount => _predicciones.isNotEmpty ? _predicciones.length : 52;

  double get _pctAlto => _totalCount > 0 ? (_altoCount / _totalCount) * 100 : 0;
  double get _pctMedio => _totalCount > 0 ? (_medioCount / _totalCount) * 100 : 0;
  double get _pctBajo => _totalCount > 0 ? (_bajoCount / _totalCount) * 100 : 0;

  // ── Agrupación por sector ──────────────────────────────────────────────────
  List<Map<String, dynamic>> get _sectoresAgrupados {
    final Map<String, List<Prediccion>> porSector = {};
    for (int i = 1; i <= 9; i++) {
      porSector['$i'] = [];
    }

    for (final p in _predicciones) {
      final sec = p.sector?.toString() ?? '';
      if (porSector.containsKey(sec)) {
        porSector[sec]!.add(p);
      }
    }

    final list = porSector.entries.map((e) {
      final items = e.value;
      final alto = items.where((p) => p.nivelRiesgo == 2).length;
      final medio = items.where((p) => p.nivelRiesgo == 1).length;
      final bajo = items.where((p) => p.nivelRiesgo == 0).length;
      final total = items.length;

      return {
        'sectorId': e.key,
        'nombre': AppConstants.nombresSectores[e.key] ?? 'Sector ${e.key}',
        'alto': alto,
        'medio': medio,
        'bajo': bajo,
        'total': total,
      };
    }).toList();

    // Ordenar por cuadrantes ALTO desc, luego MEDIO desc
    list.sort((a, b) {
      final cmpAlto = (b['alto'] as int).compareTo(a['alto'] as int);
      if (cmpAlto != 0) return cmpAlto;
      return (b['medio'] as int).compareTo(a['medio'] as int);
    });

    return list;
  }

  // ── Filtrado y ordenamiento de cuadrantes para la lista ───────────────────
  List<Prediccion> get _cuadrantesFiltrados {
    var lista = [..._predicciones];
    if (_sectorSeleccionado != 'Todos') {
      final idSec = _sectorSeleccionado.replaceAll('Sector ', '').trim();
      lista = lista.where((p) => p.sector?.toString() == idSec).toList();
    }

    // Ordenado por certeza / probabilidad descendente
    lista.sort((a, b) => b.probabilidad.compareTo(a.probabilidad));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final franjaCorta = AppConstants.franjaCorta(AppConstants.getFranjaActual());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Predicciones del Modelo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Franja activa: $franjaCorta',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Actualizar predicciones',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección 1 — Resumen Ejecutivo
                    _buildResumenEjecutivo(),
                    const SizedBox(height: 24),

                    // Sección 2 — Distribución por Sector
                    _buildDistribucionSector(),
                    const SizedBox(height: 24),

                    // Sección 3 — Filtro por Sector (Chips)
                    _buildFiltroSectorChips(),
                    const SizedBox(height: 16),

                    // Sección 4 — Detalle por Cuadrante
                    _buildDetalleCuadrantes(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Sección 1: Resumen Ejecutivo ──────────────────────────────────────────
  Widget _buildResumenEjecutivo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RESUMEN EJECUTIVO',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  '52 CUADRANTES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Porcentajes superiores
          Text(
            '${_pctAlto.toStringAsFixed(0)}% ALTO  ·  ${_pctMedio.toStringAsFixed(0)}% MEDIO  ·  ${_pctBajo.toStringAsFixed(0)}% BAJO',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Barra de proporción territorial tricolor
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (_pctAlto > 0)
                    Expanded(
                      flex: _altoCount,
                      child: Container(color: AppTheme.riskHigh),
                    ),
                  if (_pctMedio > 0)
                    Expanded(
                      flex: _medioCount,
                      child: Container(color: AppTheme.riskMed),
                    ),
                  if (_pctBajo > 0)
                    Expanded(
                      flex: _bajoCount,
                      child: Container(color: AppTheme.riskLow),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Cards en Row
          Row(
            children: [
              Expanded(
                child: _buildResumenCard(
                  titulo: 'ALTO RIESGO',
                  count: _altoCount,
                  pct: _pctAlto,
                  subtitulo: 'Patrullaje prioritario',
                  color: AppTheme.riskHigh,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResumenCard(
                  titulo: 'MEDIO RIESGO',
                  count: _medioCount,
                  pct: _pctMedio,
                  subtitulo: 'Vigilancia activa',
                  color: AppTheme.riskMed,
                  icon: Icons.error_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResumenCard(
                  titulo: 'BAJO RIESGO',
                  count: _bajoCount,
                  pct: _pctBajo,
                  subtitulo: 'Sin alertas',
                  color: AppTheme.riskLow,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard({
    required String titulo,
    required int count,
    required double pct,
    required String subtitulo,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sección 2: Distribución por Sector ────────────────────────────────────
  Widget _buildDistribucionSector() {
    final sectores = _sectoresAgrupados;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DISTRIBUCIÓN POR SECTOR',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  _buildLeyendaDot(AppTheme.riskHigh, 'Alto'),
                  const SizedBox(width: 8),
                  _buildLeyendaDot(AppTheme.riskMed, 'Medio'),
                  const SizedBox(width: 8),
                  _buildLeyendaDot(AppTheme.riskLow, 'Bajo'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lista de sectores
          ...sectores.map((sec) {
            final alto = sec['alto'] as int;
            final medio = sec['medio'] as int;
            final bajo = sec['bajo'] as int;
            final total = sec['total'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Sector ${sec['sectorId']} — ${sec['nombre']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _buildCountBadge(alto, AppTheme.riskHigh),
                          const SizedBox(width: 6),
                          _buildCountBadge(medio, AppTheme.riskMed),
                          const SizedBox(width: 6),
                          _buildCountBadge(bajo, AppTheme.riskLow),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: total == 0
                          ? Container(color: AppTheme.surfaceVariant)
                          : Row(
                              children: [
                                if (alto > 0)
                                  Expanded(
                                    flex: alto,
                                    child: Container(color: AppTheme.riskHigh),
                                  ),
                                if (medio > 0)
                                  Expanded(
                                    flex: medio,
                                    child: Container(color: AppTheme.riskMed),
                                  ),
                                if (bajo > 0)
                                  Expanded(
                                    flex: bajo,
                                    child: Container(color: AppTheme.riskLow),
                                  ),
                              ],
                            ),
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

  Widget _buildLeyendaDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0 ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: count > 0 ? color : AppTheme.textMuted.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ── Sección 3: Filtro por Sector (Chips) ──────────────────────────────────
  Widget _buildFiltroSectorChips() {
    final opciones = ['Todos', ...List.generate(9, (i) => 'Sector ${i + 1}')];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: opciones.map((opt) {
          final isSelected = _sectorSeleccionado == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              disabledColor: AppTheme.surface,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _sectorSeleccionado = opt);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Sección 4: Detalle por Cuadrante ──────────────────────────────────────
  Widget _buildDetalleCuadrantes() {
    final cuadrantes = _cuadrantesFiltrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DETALLE POR CUADRANTE',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${cuadrantes.length} resultados',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (cuadrantes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text(
                'Sin cuadrantes registrados para este sector',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cuadrantes.length,
            itemBuilder: (context, index) {
              final item = cuadrantes[index];
              final orden = index + 1;
              final probPct = (item.probabilidad * 100).toStringAsFixed(1);
              final nivel = item.nivelRiesgo ?? 0;
              final colorNivel = AppTheme.riskColor(
                nivel == 2 ? 'ALTO' : nivel == 1 ? 'MEDIO' : 'BAJO',
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Número de orden (#1, #2)
                        SizedBox(
                          width: 28,
                          child: Text(
                            '#$orden',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Badge de Cuadrante (ej. 9D)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            item.cuadrante ?? '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Sector
                        Expanded(
                          child: Text(
                            'Sector ${item.sector ?? '—'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Badge Nivel de Riesgo
                        RiskBadge(nivelRiesgo: nivel),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Barra de certeza del modelo
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.probabilidad.clamp(0.0, 1.0),
                              backgroundColor: AppTheme.background,
                              valueColor: AlwaysStoppedAnimation<Color>(colorNivel),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$probPct%',
                          style: TextStyle(
                            color: colorNivel,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ── Skeleton Loader mientras carga ─────────────────────────────────────────
  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 70,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}