import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../welcome_screen.dart';
import 'mapa_screen.dart';
import 'alertas_screen.dart';
import 'incidentes_screen.dart';
import 'predicciones_screen.dart';
import 'perfil_screen.dart';
import '../../services/alertas_service.dart';
import '../../services/predicciones_service.dart';
import '../../services/incidentes_service.dart';
import '../../models/alerta.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _alertasActivas = 0;
  bool _isFullscreen = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AgenteHomeTab(onAlertasLoaded: (count) {
        if (mounted) setState(() => _alertasActivas = count);
      }),
      MapaScreen(onToggleFullscreen: () {
        if (mounted) setState(() => _isFullscreen = !_isFullscreen);
      }),
      const PrediccionesScreen(),
      const AlertasScreen(),
      const IncidentesScreen(),
    ];
  }

  // ignore: unused_element
  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.riskHigh)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _isFullscreen ? null : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          const BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Mapa'),
          const BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Predicciones'),
          BottomNavigationBarItem(
            icon: _alertasActivas > 0
                ? Badge(label: Text('$_alertasActivas'), child: const Icon(Icons.notifications_outlined))
                : const Icon(Icons.notifications_outlined),
            activeIcon: _alertasActivas > 0
                ? Badge(label: Text('$_alertasActivas'), child: const Icon(Icons.notifications))
                : const Icon(Icons.notifications),
            label: 'Alertas',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Incidentes'),
        ],
      ),
    );
  }
}

// ── Tab inicio del agente ──────────────────────────────────────────────────
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
  int _zonasAltoRiesgoCount = 0;
  double _f1Score = 0.0;
  int _totalIncidentes = 0;
  String _versionModelo = 'v1.0';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final resAlertas = await _alertasService.getAlertasActivas();
      final resSectores = await _prediccionesService.getPrediccionesPorSector();
      final resMetricas = await _prediccionesService.getMetricas();
      final resEstadisticas = await _incidentesService.getEstadisticas();

      if (mounted) {
        setState(() {
          _alertasActivas = resAlertas;
          _zonasAltoRiesgoCount = resSectores.where((s) => s.probabilidad > 0.66).length;
          
          if (resMetricas.isNotEmpty && !resMetricas.containsKey('mensaje')) {
            _f1Score = (resMetricas['f1_score'] as num?)?.toDouble() ?? 0.0;
            _versionModelo = resMetricas['version'] ?? 'v1.0';
          }
          
          if (resEstadisticas.isNotEmpty) {
            _totalIncidentes = resEstadisticas['total_incidentes'] ?? 0;
          }
          
          _isLoading = false;
        });
        widget.onAlertasLoaded(_alertasActivas.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nombre = authProvider.usuario?.nombre ?? 'Agente';
    
    // Header Banner
    Widget headerBanner = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0f172a), Color(0xFF1e1b4b)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'SafePoint Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.riskLow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Modelo $_versionModelo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bienvenido al panel integrado del Serenazgo de Jesús María. Monitoreo de riesgos criminales mediante IA XGBoost.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('Hola, ${nombre.split(' ').first}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen())),
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
                    headerBanner,
                    const SizedBox(height: 24),
                    
                    // Tarjetas KPI
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            titulo: 'Alertas Activas',
                            valor: _alertasActivas.length.toString(),
                            icono: Icons.warning_amber_rounded,
                            color: _alertasActivas.isNotEmpty ? AppTheme.riskHigh : AppTheme.primary,
                            subtitulo: '${_alertasActivas.length} zonas críticas',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            titulo: 'Alto Riesgo',
                            valor: _zonasAltoRiesgoCount.toString(),
                            icono: Icons.map_outlined,
                            color: _zonasAltoRiesgoCount > 0 ? AppTheme.riskHigh : AppTheme.riskMed,
                            subtitulo: 'Sectores en peligro',
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
                            valor: _f1Score.toStringAsFixed(4),
                            icono: Icons.memory,
                            color: _f1Score >= 0.90 ? AppTheme.riskLow : AppTheme.riskHigh,
                            subtitulo: _f1Score >= 0.90 ? 'Cumple objetivo' : 'Requiere ajuste',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            titulo: 'Total Incidentes',
                            valor: NumberFormat.decimalPattern().format(_totalIncidentes),
                            icono: Icons.list_alt,
                            color: AppTheme.primary,
                            subtitulo: 'Registros BD',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Mapa Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vista General',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                            if (homeState != null) homeState.setState(() => homeState._currentIndex = 1);
                          },
                          child: const Text('Abrir Mapa Completo', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        if (homeState != null) homeState.setState(() => homeState._currentIndex = 1);
                      },
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                          image: const DecorationImage(
                            image: NetworkImage('https://api.maptiler.com/maps/basic-v2-dark/256/13/2344/4255.png?key=jPBrASxMmEi3FPAa6tvR'),
                            fit: BoxFit.cover,
                            opacity: 0.6,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.background.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: AppTheme.primary, size: 16),
                                SizedBox(width: 8),
                                Text('Ver Mapa Interactivo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Últimas Alertas Generadas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Últimas Alertas Predictivas',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                            if (homeState != null) homeState.setState(() => homeState._currentIndex = 3);
                          },
                          child: const Text('Ver todas', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_alertasActivas.isEmpty)
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
                          children: _alertasActivas.take(4).map((alerta) {
                            return Container(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (alerta.tipoDelito.toUpperCase() == 'ROBO' ? AppTheme.riskHigh : AppTheme.primary).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: alerta.tipoDelito.toUpperCase() == 'ROBO' ? AppTheme.riskHigh : AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Sector ${alerta.sector}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${alerta.tipoDelito} • ${alerta.franjaHoraria}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(alerta.probabilidad * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                    Text(
                                      alerta.probabilidad > 0.66 ? 'ALTO RIESGO' : 'RIESGO MEDIO',
                                      style: TextStyle(
                                        color: alerta.probabilidad > 0.66 ? AppTheme.riskHigh : AppTheme.riskMed,
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
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

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
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Icon(icono, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(color: color == AppTheme.primary ? Colors.white : color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
