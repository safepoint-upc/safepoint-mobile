import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/alertas_service.dart';
import '../../services/predicciones_service.dart';
import '../../services/incidentes_service.dart';
import '../../models/alerta.dart';
import '../../widgets/section_header.dart';
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
      // Cargamos todo en paralelo
      final results = await Future.wait([
        _alertasService.getAlertasActivas(),
        _prediccionesService.getPrediccionesPorSector(),
        _incidentesService.getEstadisticas(),
        _prediccionesService.getMetricas(),
      ]);

      final alertas = results[0] as List<Alerta>;
      final sectores = results[1] as List<Map<String, dynamic>>;
      final estadisticas = results[2] as Map<String, dynamic>;
      final metricas = results[3] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _alertasActivas = alertas;
          _sectores = sectores;
          _totalIncidentes = estadisticas['total_incidentes'] ?? 0;
          // Si no hay métricas disponibles el backend devuelve {mensaje: ...}
          if (!metricas.containsKey('mensaje')) {
            _f1Score = (metricas['f1_score'] as num?)?.toDouble() ?? 0.0;
            _versionModelo = metricas['version'] ?? '';
          }
          _isLoading = false;
        });
        widget.onAlertasLoaded(_alertasActivas.length);
      }
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

  // Sector con mayor probabilidad promedio de riesgo
  String get _sectorMasCritico {
    if (_sectores.isEmpty) return '—';
    final top = _sectores.reduce((a, b) =>
    (a['probabilidad_promedio'] as num) > (b['probabilidad_promedio'] as num)
        ? a
        : b);
    return 'Sector ${top['sector']}';
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
        title: Row(
          children: [
            const Icon(Icons.shield, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            Text('Hola, ${nombre.split(' ').first}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/agente/perfil'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
              // Selector de sector — filtra las alertas de abajo
              _buildSectorSelector(),
              const SizedBox(height: 16),

              // KPIs principales
              _buildKpiCards(),
              const SizedBox(height: 24),

              // Acceso rápido al mapa
              _buildMapaPreview(context),
              const SizedBox(height: 24),

              // Últimas alertas del sector seleccionado
              _buildUltimasAlertas(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
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
                valor: _sectorMasCritico,
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

  // Vista previa del mapa — toca para ir al mapa completo
  Widget _buildMapaPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          titulo: 'Mapa de Riesgo',
          onVerTodos: () => context.push('/agente/mapa'),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.push('/agente/mapa'),
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, color: AppTheme.primary, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Abrir Mapa Interactivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Lista de últimas alertas filtradas por sector
  Widget _buildUltimasAlertas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          titulo: 'Últimas Alertas',
          onVerTodos: () => context.push('/agente/alertas'),
        ),
        const SizedBox(height: 8),
        if (_alertasFiltradas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'No hay alertas activas en este momento.',
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
              children: _alertasFiltradas.take(4).map((alerta) {
                final color = alerta.probabilidad > 0.66
                    ? AppTheme.riskHigh
                    : AppTheme.riskMed;
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: AppTheme.border, width: 0.5),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sector ${alerta.sector} — ${alerta.cuadrante ?? "-"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      alerta.franjaHoraria ?? '-',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(alerta.probabilidad * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          alerta.probabilidad > 0.66 ? 'ALTO' : 'MEDIO',
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
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