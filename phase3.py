import os

base_dir = r'C:\Users\fersa\Desktop\proyecto-tesis\safepoint-mobile\lib'

agente_mapa_content = '''import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/constants.dart';
import '../../services/incidentes_service.dart';
import '../../services/alertas_service.dart';
import '../../models/incidente.dart';
import '../../models/alerta.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  List<Incidente> _incidentes = [];
  List<Alerta> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final incidentesService = IncidentesService();
      final alertasService = AlertasService();
      
      final results = await Future.wait([
        incidentesService.getIncidentes(),
        alertasService.getAlertasActivas(),
      ]);
      
      if (mounted) {
        setState(() {
          _incidentes = results[0] as List<Incidente>;
          _alertas = results[1] as List<Alerta>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar datos del mapa')),
        );
      }
    }
  }

  List<Polygon> _buildSectoresPolygons() {
    final sectores = [
      AppConstants.sector1, AppConstants.sector2, AppConstants.sector3,
      AppConstants.sector4, AppConstants.sector5, AppConstants.sector6,
      AppConstants.sector7, AppConstants.sector8, AppConstants.sector9,
    ];

    return sectores.asMap().entries.map((entry) {
      final idx = entry.key;
      final coords = entry.value;
      
      // Determine if there is an active alert for this sector (Sector is 1-indexed)
      final sectorName = 'Sector \${idx + 1}';
      final hasAlert = _alertas.any((a) => a.sector == sectorName && a.activa);
      
      final color = hasAlert 
          ? Colors.red.withOpacity(0.4) 
          : Colors.blue.withOpacity(0.1);
      final borderColor = hasAlert ? Colors.red : Colors.blue;

      return Polygon(
        points: coords.map((c) => LatLng(c[0], c[1])).toList(),
        color: color,
        borderStrokeWidth: 2,
        borderColor: borderColor,
      );
    }).toList();
  }

  List<Marker> _buildIncidentesMarkers() {
    return _incidentes.map((i) {
      return Marker(
        point: LatLng(i.latitud, i.longitud),
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 30,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Interactivo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(AppConstants.jesusMariaLat, AppConstants.jesusMariaLng),
                initialZoom: AppConstants.defaultZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safepoint.mobile',
                ),
                PolygonLayer(polygons: _buildSectoresPolygons()),
                MarkerLayer(markers: _buildIncidentesMarkers()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
'''

agente_alertas_content = '''import 'package:flutter/material.dart';
import '../../services/alertas_service.dart';
import '../../models/alerta.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final AlertasService _alertasService = AlertasService();
  List<Alerta> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlertas();
  }

  Future<void> _loadAlertas() async {
    setState(() => _isLoading = true);
    try {
      final alertas = await _alertasService.getAlertasActivas();
      if (mounted) {
        setState(() {
          _alertas = alertas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _desactivarAlerta(int id) async {
    final success = await _alertasService.desactivarAlerta(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta desactivada con éxito')),
        );
        _loadAlertas();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al desactivar alerta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas Activas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlertas,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? const Center(child: Text('No hay alertas activas', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = _alertas[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(alerta.creadoEn);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '\${alerta.tipoDelito}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.riskHigh.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'RIESGO \${alerta.nivelRiesgo}',
                                    style: const TextStyle(
                                      color: AppTheme.riskHigh,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text('\${alerta.sector}', style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text('Franja: \${alerta.franjaHoraria}', style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(dateStr, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _desactivarAlerta(alerta.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cardColor,
                                  side: const BorderSide(color: Colors.grey),
                                ),
                                child: const Text('Marcar como Resuelta', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
'''

agente_incidentes_content = '''import 'package:flutter/material.dart';
import '../../services/incidentes_service.dart';
import '../../models/incidente.dart';
import 'package:intl/intl.dart';

class IncidentesScreen extends StatefulWidget {
  const IncidentesScreen({super.key});

  @override
  State<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends State<IncidentesScreen> {
  final IncidentesService _incidentesService = IncidentesService();
  List<Incidente> _incidentes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidentes();
  }

  Future<void> _loadIncidentes() async {
    setState(() => _isLoading = true);
    try {
      final incidentes = await _incidentesService.getIncidentes();
      if (mounted) {
        setState(() {
          _incidentes = incidentes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Incidentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidentes,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidentes.isEmpty
              ? const Center(child: Text('No hay incidentes registrados', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incidentes.length,
                  itemBuilder: (context, index) {
                    final incidente = _incidentes[index];
                    final dateStr = DateFormat('dd/MM/yyyy').format(incidente.fecha);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          child: const Icon(Icons.warning, color: Colors.blue),
                        ),
                        title: Text(
                          incidente.tipoDelito,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('\${incidente.avenida} \${incidente.cuadra}'),
                            const SizedBox(height: 2),
                            Text('\${incidente.sector} | \$dateStr \${incidente.hora}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
'''

agente_home_update = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'mapa_screen.dart';
import 'alertas_screen.dart';
import 'incidentes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapaScreen(),
    const AlertasScreen(),
    const IncidentesScreen(),
  ];

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Agente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Incidentes',
          ),
        ],
      ),
    );
  }
}
'''

def write_file(path, content):
    with open(os.path.join(base_dir, path), 'w', encoding='utf-8') as f:
        f.write(content)

write_file('screens/agente/mapa_screen.dart', agente_mapa_content)
write_file('screens/agente/alertas_screen.dart', agente_alertas_content)
write_file('screens/agente/incidentes_screen.dart', agente_incidentes_content)
write_file('screens/agente/home_screen.dart', agente_home_update)

print("Fase 3 completada.")
