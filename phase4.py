import os

base_dir = r'C:\Users\fersa\Desktop\proyecto-tesis\safepoint-mobile\lib'

ciudadano_mapa_content = '''import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/constants.dart';
import '../../services/predicciones_service.dart';
import '../../models/prediccion.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  List<Prediccion> _predicciones = [];
  bool _isLoading = true;
  String _selectedFranja = 'Todas';

  final List<String> _franjas = ['Todas', 'Madrugada', 'Mañana', 'Tarde', 'Noche'];

  @override
  void initState() {
    super.initState();
    _loadPredicciones();
  }

  Future<void> _loadPredicciones() async {
    setState(() => _isLoading = true);
    try {
      final service = PrediccionesService();
      final data = await service.getPredicciones(franjaHoraria: _selectedFranja);
      if (mounted) {
        setState(() {
          _predicciones = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar predicciones')),
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
      
      final sectorName = 'Sector \${idx + 1}';
      
      // Calculate average probability for this sector
      final sectorPreds = _predicciones.where((p) => p.sector == sectorName).toList();
      double avgProb = 0;
      if (sectorPreds.isNotEmpty) {
        avgProb = sectorPreds.map((p) => p.probabilidad).reduce((a, b) => a + b) / sectorPreds.length;
      }
      
      Color fillColor;
      if (avgProb >= 0.7) {
        fillColor = Colors.red.withOpacity(0.4);
      } else if (avgProb >= 0.4) {
        fillColor = Colors.orange.withOpacity(0.4);
      } else if (avgProb > 0) {
        fillColor = Colors.green.withOpacity(0.4);
      } else {
        fillColor = Colors.blue.withOpacity(0.1);
      }

      return Polygon(
        points: coords.map((c) => LatLng(c[0], c[1])).toList(),
        color: fillColor,
        borderStrokeWidth: 2,
        borderColor: fillColor.withOpacity(1.0),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Predictivo'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _franjas.map((franja) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(franja),
                      selected: _selectedFranja == franja,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFranja = franja;
                          });
                          _loadPredicciones();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
'''

ciudadano_estadisticas_content = '''import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/incidentes_service.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final IncidentesService _service = IncidentesService();
  Map<String, dynamic> _porFranja = {};
  Map<String, dynamic> _porTipo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getPorFranja(),
        _service.getPorTipo(),
      ]);

      if (mounted) {
        setState(() {
          _porFranja = results[0];
          _porTipo = results[1];
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
        title: const Text('Estadísticas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Incidentes por Franja Horaria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildBarChart(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Tipos de Delito más Frecuentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPieChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildBarChart() {
    if (_porFranja.isEmpty) return const Center(child: Text('Sin datos'));

    final keys = _porFranja.keys.toList();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _porFranja.values.map((v) => (v as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(keys[value.toInt()], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: keys.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (_porFranja[entry.value] as num).toDouble(),
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_porTipo.isEmpty) return const Center(child: Text('Sin datos'));

    final colors = [Colors.red, Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.teal];
    final entries = _porTipo.entries.toList();

    return Column(
      children: entries.asMap().entries.map((entry) {
        final color = colors[entry.key % colors.length];
        return ListTile(
          leading: CircleAvatar(backgroundColor: color, radius: 8),
          title: Text(entry.value.key),
          trailing: Text('\${entry.value.value}'),
        );
      }).toList(),
    );
  }
}
'''

ciudadano_home_update = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'mapa_screen.dart';
import 'estadisticas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapaScreen(),
    const EstadisticasScreen(),
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
        title: const Text('SafePoint Ciudadano'),
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
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
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

write_file('screens/ciudadano/mapa_screen.dart', ciudadano_mapa_content)
write_file('screens/ciudadano/estadisticas_screen.dart', ciudadano_estadisticas_content)
write_file('screens/ciudadano/home_screen.dart', ciudadano_home_update)

print("Fase 4 completada.")
