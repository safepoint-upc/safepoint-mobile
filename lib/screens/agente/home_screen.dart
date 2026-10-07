import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../services/alertas_service.dart';
import '../../services/predicciones_service.dart';
import '../../services/incidentes_service.dart';
import '../../models/alerta.dart';
import '../../widgets/section_header.dart';
import '../../widgets/bar_chart_card.dart';
import 'mapa_screen.dart';
import 'alertas_screen.dart';
import 'incidentes_screen.dart';
import 'predicciones_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _alertasActivas = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AgenteHomeTab(onAlertasLoaded: (count) {
        if (mounted) setState(() => _alertasActivas = count);
      }),
      const MapaScreen(),
      const PrediccionesScreen(),
      const AlertasScreen(),
      const IncidentesScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Predicciones',
          ),
          BottomNavigationBarItem(
            icon: _alertasActivas > 0
                ? Badge(
              label: Text('$_alertasActivas'),
              child: const Icon(Icons.notifications_outlined),
            )
                : const Icon(Icons.notifications_outlined),
            activeIcon: _alertasActivas > 0
                ? Badge(
              label: Text('$_alertasActivas'),
              child: const Icon(Icons.notifications),
            )
                : const Icon(Icons.notifications),
            label: 'Alertas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Incidentes',
          ),
        ],
      ),
    );
  }
}

// ── Tab de inicio del agente ───────────────────────────────────────────────
class AgenteHomeTab extends StatefulWidget {
  final Function(int) onAlertasLoaded;
  const AgenteHomeTab({super.key, required this.onAlertasLoaded});

  @override
  State<AgenteHomeTab> createState() => _AgenteHomeTabState();
}

class _AgenteHomeTabState extends State<AgenteHomeTab> {
  final AlertasService _alertasService = AlertasService();
  final PrediccionesService _prediccionesService = PrediccionesService();
  final IncidentesService _incidentesService = IncidentesService();

  bool _isLoading = true;
  List<Alerta> _alertasActivas = [];
  List<Map<String, dynamic>> _sectores = [];
  String? _sectorSeleccionado; // null = todos los sectores
  int _totalIncidentes = 0;
  double _f1Score = 0.0;
  String _versionModelo = '';

  List<Map<String, dynamic>> _incidentesPorFranja = [];
  List<Map<String, dynamic>> _prediccionesPorCuadrante = [];

  // Sectores disponibles del 1 al 9
  static const List<String> _sectoresDisponibles = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargas esenciales ultrarrápidas
      final essentialResults = await Future.wait([
        _alertasService.getAlertasActivas(),
        _prediccionesService.getPrediccionesPorSector(),
        _incidentesService.getEstadisticas(),
        _prediccionesService.getMetricas(),
        _incidentesService.getIncidentesPorFranja(),
      ]);

      final alertas = essentialResults[0] as List<Alerta>;
      final sectores = essentialResults[1] as List<Map<String, dynamic>>;
      final estadisticas = essentialResults[2] as Map<String, dynamic>;
      final metricas = essentialResults[3] as Map<String, dynamic>;
      final incidentesPorFranja = essentialResults[4] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _alertasActivas = alertas;
          _sectores = sectores;
          _totalIncidentes = estadisticas['total_incidentes'] ?? 0;
          if (!metricas.containsKey('mensaje')) {
            _f1Score = (metricas['f1_score'] as num?)?.toDouble() ?? 0.0;
            _versionModelo = metricas['version'] ?? '';
          }
          _incidentesPorFranja = incidentesPorFranja;
          _isLoading = false;
        });
        widget.onAlertasLoaded(_alertasActivas.length);
      }

      // 2. Carga secundaria de predicciones por cuadrante (6000 registros en background)
      _prediccionesService.getPrediccionesPorCuadrante(
        franjaHoraria: AppConstants.getFranjaActual(),
      ).then((prediccionesPorCuadrante) {
        if (mounted) {
          setState(() {
            _prediccionesPorCuadrante = prediccionesPorCuadrante;
          });
        }
      }).catchError((e) {
        debugPrint('ERROR cargando predicciones por cuadrante: $e');
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtra las alertas según el sector seleccionado
  List<Alerta> get _alertasFiltradas {
    if (_sectorSeleccionado == null) return _alertasActivas;
    return _alertasActivas
        .where((a) => a.sector == _sectorSeleccionado)
        .toList();
  }

  Map<String, dynamic>? get _sectorMasCriticoData {
    if (_sectores.isEmpty) return null;
    return _sectores.reduce((a, b) =>
      (a['probabilidad_promedio'] as num) > (b['probabilidad_promedio'] as num) ? a : b);
  }

  List<Map<String, dynamic>> get _sectoresCriticos {
    final Map<String, int> totalPorSector = {};
    final Map<String, int> altosPorSector = {};

    for (final pred in _prediccionesPorCuadrante) {
      final cuadrante = pred['cuadrante']?.toString() ?? '';
      final sectorMatch = RegExp(r'^(\d+)').firstMatch(cuadrante);
      final sector = sectorMatch?.group(1) ?? '?';
      totalPorSector[sector] = (totalPorSector[sector] ?? 0) + 1;
      
      final nivel = pred['nivel_riesgo'];
      final prob = (pred['probabilidad_promedio'] as num?)?.toDouble() ?? 0.0;
      final isAlto = nivel == 2 || nivel == 'ALTO' || (nivel == null && prob > 0.66);
      
      if (isAlto) {
        altosPorSector[sector] = (altosPorSector[sector] ?? 0) + 1;
      }
    }

    final result = altosPorSector.entries.map((e) {
      final total = totalPorSector[e.key] ?? 1;
      return {
        'sector': e.key,
        'altos': e.value,
        'total': total,
        'porcentaje': e.value / total,
      };
    }).toList();

    result.sort((a, b) => (b['porcentaje'] as double).compareTo(a['porcentaje'] as double));
    return result.take(5).toList();
  }

  Map<String, int> get _mapaIncidentesPorFranja {
    final Map<String, int> result = {};
    for (final item in _incidentesPorFranja) {
      final franjaRaw = item['franja_horaria']?.toString() ?? '';
      final franja = AppConstants.franjaCorta(franjaRaw);
      // El backend devuelve el campo como 'cantidad', no 'total'
      final total = (item['cantidad'] as num?)?.toInt() ?? 0;
      if (franja.isNotEmpty) result[franja] = total;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final nombre = Provider.of<AuthProvider>(context, listen: false)
        .usuario
        ?.nombre ??
        'Agente';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${nombre.split(' ').first}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  AppConstants.franjaCorta(AppConstants.getFranjaActual()),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push('/agente/perfil'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  nombre.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton()
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
              _buildSectorSelector(),
              const SizedBox(height: 16),
              _buildKpiCards(),
              const SizedBox(height: 24),
              _buildSectoresCriticos(),
              const SizedBox(height: 24),
              _buildIncidentesPorFranja(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Skeleton chips
          Container(height: 36, decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
          )),
          const SizedBox(height: 16),
          // Skeleton KPI cards
          Row(children: [
            Expanded(child: Container(height: 100, decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 100, decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Container(height: 100, decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 100, decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ))),
          ]),
          const SizedBox(height: 24),
          Container(height: 200, decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          )),
        ],
      ),
    );
  }

  // Selector de sector horizontal con chips
  Widget _buildSectorSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip "Todos"
          _SectorChip(
            label: 'Todos',
            isSelected: _sectorSeleccionado == null,
            onTap: () => setState(() => _sectorSeleccionado = null),
          ),
          ..._sectoresDisponibles.map((s) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _SectorChip(
              label: 'Sector $s',
              isSelected: _sectorSeleccionado == s,
              onTap: () => setState(() => _sectorSeleccionado = s),
            ),
          )),
        ],
      ),
    );
  }

  // Tarjetas KPI: alertas, sector crítico, F1-Score y total incidentes
  Widget _buildKpiCards() {
    final sectorCritico = _sectorMasCriticoData;
    final valorSectorCritico = sectorCritico != null ? 'Sector ${sectorCritico['sector']}' : '—';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                titulo: 'Alertas Activas',
                valor: _alertasFiltradas.length.toString(),
                icono: Icons.warning_amber_rounded,
                color: _alertasFiltradas.isNotEmpty
                    ? AppTheme.riskHigh
                    : AppTheme.riskLow,
                subtitulo: 'Zonas en alerta ahora',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                titulo: 'Sector Más Crítico',
                valor: valorSectorCritico,
                icono: Icons.location_on,
                color: AppTheme.riskHigh,
                subtitulo: 'Mayor riesgo promedio',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                titulo: 'F1-Score Modelo',
                valor: _f1Score > 0
                    ? _f1Score.toStringAsFixed(4)
                    : '—',
                icono: Icons.memory,
                color: _f1Score >= 0.90
                    ? AppTheme.riskLow
                    : AppTheme.riskHigh,
                subtitulo: _versionModelo.isNotEmpty
                    ? _versionModelo
                    : 'XGBoost',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                titulo: 'Total Incidentes',
                valor: NumberFormat.decimalPattern()
                    .format(_totalIncidentes),
                icono: Icons.list_alt,
                color: AppTheme.primary,
                subtitulo: 'Registros en BD',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectoresCriticos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Sectores Críticos del Día',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sectores con más cuadrantes en riesgo ALTO en la franja horaria actual. Se actualiza automáticamente.'),
                  duration: Duration(seconds: 3),
                ),
              ),
              child: const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_sectoresCriticos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'Sin sectores en riesgo ALTO en la franja actual',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: _sectoresCriticos.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final nombre = AppConstants.nombresSectores[s['sector']] ?? '';
                final pct = (s['porcentaje'] as double);
                final isLast = i == _sectoresCriticos.length - 1;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(
                      bottom: BorderSide(color: AppTheme.border, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sector ${s['sector']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (nombre.isNotEmpty)
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.riskHigh.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_rounded, color: AppTheme.riskHigh, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'ALTO',
                                  style: TextStyle(
                                    color: AppTheme.riskHigh,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: AppTheme.background,
                                valueColor: const AlwaysStoppedAnimation(AppTheme.riskHigh),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${s['altos']} de ${s['total']} cuadrantes · ${(pct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildIncidentesPorFranja() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Incidentes por Franja',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cantidad histórica de incidentes registrados por turno del día. Útil para identificar en qué franjas reforzar el patrullaje.'),
                  duration: Duration(seconds: 3),
                ),
              ),
              child: const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BarChartCard(
          titulo: '',
          data: _mapaIncidentesPorFranja,
          color: AppTheme.riskHigh,
        ),
      ],
    );
  }
}

// ── Chip de selección de sector ────────────────────────────────────────────
class _SectorChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta KPI reutilizable ───────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final String subtitulo;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: const BorderSide(color: AppTheme.border),
          right: const BorderSide(color: AppTheme.border),
          bottom: const BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icono, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              color: color == AppTheme.primary ? Colors.white : color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}