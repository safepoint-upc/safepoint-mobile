import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../services/predicciones_service.dart';
import '../../services/incidentes_service.dart';
import '../../models/prediccion.dart';
import '../../widgets/bar_chart_card.dart';
import 'mapa_screen.dart';
import 'predicciones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const AgenteHomeTab(),
      const MapaScreen(),
      const PrediccionesScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Predicciones',
          ),
        ],
      ),
    );
  }
}

// ── Tab de inicio del agente ───────────────────────────────────────────────
class AgenteHomeTab extends StatefulWidget {
  const AgenteHomeTab({super.key});

  @override
  State<AgenteHomeTab> createState() => _AgenteHomeTabState();
}

class _AgenteHomeTabState extends State<AgenteHomeTab> {
  final PrediccionesService _prediccionesService = PrediccionesService();
  final IncidentesService _incidentesService = IncidentesService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _prediccionesCuadrante = [];
  String _franjaActualBackend = AppConstants.getFranjaActual(); // se actualiza con la franja real del backend
  String? _sectorSeleccionado; // null = todos los sectores

  List<Map<String, dynamic>> _incidentesPorFranja = [];

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
      // Cargamos predicciones sin filtro de franja, estadísticas e incidentes por franja
      final results = await Future.wait([
        _prediccionesService.getPrediccionesPorCuadrante(), // sin filtro de franja
        _incidentesService.getEstadisticas(),
        _incidentesService.getIncidentesPorFranja(),
        _prediccionesService.getUltimasPredicciones(), // para obtener la franja real del backend
      ]);

      final prediccionesCuad = results[0] as List<Map<String, dynamic>>;
      final incidentesPorFranja = results[2] as List<Map<String, dynamic>>;
      final ultimasPredicciones = results[3] as List<Prediccion>;

      // La franja real viene del backend, no del reloj del dispositivo
      final franjaBackend = ultimasPredicciones.isNotEmpty
          ? ultimasPredicciones.first.franjaHoraria ?? AppConstants.getFranjaActual()
          : AppConstants.getFranjaActual();

      if (mounted) {
        setState(() {
          _prediccionesCuadrante = prediccionesCuad;
          _franjaActualBackend = franjaBackend;
          _incidentesPorFranja = incidentesPorFranja;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR _loadData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Top 3 cuadrantes en ALTO del sector seleccionado (o de todos si no hay filtro).
  // Misma lógica que prediccionesAltoActual en el dashboard web:
  // filtra nivel_riesgo == 2 + sector coincidente, ordena por probabilidad DESC.
  String get _top3Cuadrantes {
    final altos = _prediccionesCuadrante
        .where((p) {
          final esAlto = (p['nivel_riesgo'] as int?) == 2;
          final coincideSector = _sectorSeleccionado == null ||
              p['sector']?.toString() == _sectorSeleccionado;
          return esAlto && coincideSector;
        })
        .toList()
      ..sort((a, b) =>
          ((b['probabilidad'] as num?)?.toDouble() ?? 0.0)
              .compareTo((a['probabilidad'] as num?)?.toDouble() ?? 0.0));

    if (altos.isEmpty) {
      return _sectorSeleccionado != null ? 'Sin cuadrantes ALTO' : '—';
    }

    return altos.take(3).map((p) => p['cuadrante']?.toString() ?? '').join(' · ');
  }

  // KPI 2: Sector o Cuadrante Más Crítico
  // Misma lógica idéntica que Dashboard.jsx (kpi2)
  Map<String, String> get _kpi2Data {
    if (_sectorSeleccionado != null) {
      // Filtrar por sector seleccionado y ordenar cuadrantes:
      // 1. nivel_riesgo DESC (2=ALTO, 1=MEDIO, 0=BAJO)
      // 2. probabilidad DESC dentro del mismo nivel
      final predSector = [..._prediccionesCuadrante]
          .where((p) => p['sector']?.toString() == _sectorSeleccionado)
          .toList();

      predSector.sort((a, b) {
        final nivelA = (a['nivel_riesgo'] as int?) ?? 0;
        final nivelB = (b['nivel_riesgo'] as int?) ?? 0;
        if (nivelB != nivelA) return nivelB.compareTo(nivelA);

        final probA = (a['probabilidad'] as num?)?.toDouble() ?? 0.0;
        final probB = (b['probabilidad'] as num?)?.toDouble() ?? 0.0;
        return probB.compareTo(probA);
      });

      if (predSector.isNotEmpty && predSector.first['cuadrante'] != null) {
        final top = predSector.first;
        final cuad = top['cuadrante']?.toString() ?? '';
        final nivel = (top['nivel_riesgo'] as int?) ?? 0;
        final nivelStr = nivel == 2
            ? 'Riesgo ALTO'
            : nivel == 1
                ? 'Riesgo MEDIO'
                : 'Riesgo BAJO';
        final prob = (top['probabilidad'] as num?)?.toDouble() ?? 0.0;
        final probPct = (prob * 100).toStringAsFixed(1);

        return {
          'titulo': 'Cuadrante Más Crítico',
          'valor': cuad,
          'subtitulo': '$nivelStr ($probPct% certeza)',
          'tooltip': 'Cuadrante de mayor riesgo en el sector seleccionado. El porcentaje indica la certeza del modelo XGBoost en su predicción, no la probabilidad de que ocurra un delito.',
        };
      }

      return {
        'titulo': 'Cuadrante Más Crítico',
        'valor': 'Sector $_sectorSeleccionado',
        'subtitulo': AppConstants.nombresSectores[_sectorSeleccionado] ?? 'Sector $_sectorSeleccionado',
        'tooltip': 'Cuadrante de mayor riesgo en el sector seleccionado. El porcentaje indica la certeza del modelo XGBoost en su predicción, no la probabilidad de que ocurra un delito.',
      };
    }

    // Modo "Todos": mostrar el Sector Más Crítico
    final list = _sectoresCriticosCalculados;
    if (list.isNotEmpty) {
      final topSec = list.first['sector']?.toString() ?? '1';
      return {
        'titulo': 'Sector Más Crítico',
        'valor': 'Sector $topSec',
        'subtitulo': AppConstants.nombresSectores[topSec] ?? 'Mayor riesgo',
        'tooltip': 'Sector con mayor proporción de cuadrantes en riesgo ALTO ahora mismo.',
      };
    }

    return {
      'titulo': 'Sector Más Crítico',
      'valor': '—',
      'subtitulo': 'Sin datos',
      'tooltip': 'Sector con mayor proporción de cuadrantes en riesgo ALTO ahora mismo.',
    };
  }

  // Estructura y cálculo idéntico al dashboard web (Dashboard.jsx)
  List<Map<String, dynamic>> get _sectoresCriticosCalculados {
    final sectores = AppConstants.sectorCuadrantes.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    final result = <Map<String, dynamic>>[];

    for (final sectorId in sectores) {
      if (_sectorSeleccionado != null && sectorId != _sectorSeleccionado) continue;

      final todosCuadrantes = AppConstants.sectorCuadrantes[sectorId] ?? [];
      final totalCuadrantes = todosCuadrantes.length;

      // Filtrar predicciones del sector
      final predSector = _prediccionesCuadrante.where(
        (p) => p['sector']?.toString() == sectorId.toString()
      ).toList();

      int altoCount = 0;
      int medioCount = 0;
      int bajoCount = 0;

      // Buscar predicción por cada cuadrante oficial (igual que Dashboard.jsx)
      for (final cuad in todosCuadrantes) {
        final predCuad = predSector.firstWhere(
          (p) => p['cuadrante']?.toString() == cuad,
          orElse: () => {},
        );
        final nivel = predCuad.isNotEmpty ? (predCuad['nivel_riesgo'] as int? ?? 0) : 0;

        if (nivel == 2) {
          altoCount++;
        } else if (nivel == 1) {
          medioCount++;
        } else {
          bajoCount++;
        }
      }

      final proporcionAlto = totalCuadrantes > 0 ? altoCount / totalCuadrantes : 0.0;

      String nivelCalculado = 'BAJO';
      if (proporcionAlto > 0.5) {
        nivelCalculado = 'ALTO';
      } else if (proporcionAlto >= 1 / 3) {
        nivelCalculado = 'MEDIO';
      }

      result.add({
        'sector': sectorId,
        'nivel': nivelCalculado,
        'altos': altoCount,
        'medios': medioCount,
        'bajos': bajoCount,
        'total': totalCuadrantes,
        'proporcion': proporcionAlto,
      });
    }

    // Mismo criterio de ordenamiento idéntico al Dashboard Web:
    // 1. Mayor proporcionAlto
    // 2. Desempate por mayor altoCount
    // 3. Desempate por número de sector ascendente
    result.sort((a, b) {
      final double propA = a['proporcion'];
      final double propB = b['proporcion'];
      if (propB != propA) return propB.compareTo(propA);
      final int altosA = a['altos'];
      final int altosB = b['altos'];
      if (altosB != altosA) return altosB.compareTo(altosA);
      return int.parse(a['sector']).compareTo(int.parse(b['sector']));
    });

    return result;
  }

  // Lista para renderizar en la sección "Sectores Críticos del Día"
  List<Map<String, dynamic>> get _sectoresCriticos {
    if (_prediccionesCuadrante.isEmpty) return [];
    return _sectoresCriticosCalculados;
  }

  Map<String, int> get _mapaIncidentesPorFranja {
    final List<Map<String, dynamic>> ordenado = List.from(_incidentesPorFranja)
      ..sort((a, b) {
        final franjaA = a['franja_horaria']?.toString() ?? '';
        final franjaB = b['franja_horaria']?.toString() ?? '';
        final idxA = AppConstants.franjasHorarias.indexOf(franjaA);
        final idxB = AppConstants.franjasHorarias.indexOf(franjaB);
        return (idxA == -1 ? 999 : idxA).compareTo(idxB == -1 ? 999 : idxB);
      });

    final Map<String, int> result = {};
    for (final item in ordenado) {
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
                  AppConstants.franjaCorta(_franjaActualBackend),
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

  // Tarjetas KPI: 2 columnas con altura uniforme (IntrinsicHeight)
  Widget _buildKpiCards() {
    final kpi2 = _kpi2Data;
    final cuadrantesAlto = _prediccionesCuadrante.where((p) {
      final esAlto = (p['nivel_riesgo'] as int?) == 2;
      final coincideSector = _sectorSeleccionado == null ||
          p['sector']?.toString() == _sectorSeleccionado;
      return esAlto && coincideSector;
    }).toList();

    final countAlto = cuadrantesAlto.length;
    final colorAlto = countAlto > 0 ? AppTheme.riskHigh : AppTheme.riskLow;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _KpiCard(
              titulo: 'Cuadrantes en ALTO',
              valor: countAlto.toString(),
              icono: Icons.warning_amber_rounded,
              color: colorAlto,
              subtitulo: countAlto > 0
                  ? 'Top 3: $_top3Cuadrantes'
                  : 'Sin cuadrantes en alto riesgo',
              tooltip: 'Cuadrantes en riesgo ALTO en la franja horaria actual. El Top 3 muestra los cuadrantes con mayor certeza del modelo.',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              titulo: kpi2['titulo'] ?? 'Sector Más Crítico',
              valor: kpi2['valor'] ?? '—',
              icono: Icons.location_on,
              color: AppTheme.riskHigh,
              subtitulo: kpi2['subtitulo'] ?? 'Sin datos',
              tooltip: kpi2['tooltip'],
            ),
          ),
        ],
      ),
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
                  content: Text(
                      'Sectores ordenados por nivel de riesgo estimado. Se actualiza con los últimos datos de predicción para la franja actual.'),
                  duration: Duration(seconds: 4),
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
              'Sin sectores registrados para el filtro actual',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          )
        else
          Container(
            height: 275,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _sectoresCriticos.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppTheme.border,
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                ),
                itemBuilder: (context, i) {
                  final s = _sectoresCriticos[i];
                  final nombre = AppConstants.nombresSectores[s['sector']] ?? '';
                  final pct = (s['proporcion'] as double);
                  final nivel = s['nivel'] as String? ?? 'BAJO';

                  final Color riskColor = AppTheme.riskColor(nivel);
                  final IconData riskIcon = nivel == 'ALTO'
                      ? Icons.warning_rounded
                      : nivel == 'MEDIO'
                          ? Icons.info_outline
                          : Icons.check_circle_rounded;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: riskColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(riskIcon, color: riskColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    nivel,
                                    style: TextStyle(
                                      color: riskColor,
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
                                  valueColor: AlwaysStoppedAnimation(riskColor),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${s['altos']} de ${s['total']} cuadrantes en ALTO · ${(pct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
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
          color: AppTheme.primary,
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

// ── Tarjeta KPI (grid 2 columnas) ──────────────────────────────────────────
// Diseño premium: gradiente de fondo, borde izquierdo coloreado (4 px),
// sombra coloreada sutil, ícono en esquina superior derecha.
// Se usa ClipRRect + Stack porque Flutter no soporta Border asimétrico
// con borderRadius de forma nativa.
class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final String subtitulo;
  final String? tooltip;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.subtitulo,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // ── Cuerpo con gradiente + sombra coloreada ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1e293b),
                  Color(0xFF0f172a),
                ],
              ),
              border: const Border(
                left: BorderSide(color: Colors.transparent, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Fila superior: título + tooltip | ícono ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              titulo.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (tooltip != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tooltip!),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.info_outline,
                                color: AppTheme.textMuted,
                                size: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(icono, color: color.withValues(alpha: 0.8), size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Valor principal ──
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                // ── Subtítulo ──
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // ── Borde izquierdo coloreado ──
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Container(width: 4, color: color),
          ),
        ],
      ),
    );
  }
}