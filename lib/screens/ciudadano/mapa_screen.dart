import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../services/incidentes_service.dart';
import '../../services/predicciones_service.dart';
import '../../models/incidente.dart';
import '../../models/prediccion.dart';
import '../../theme/app_theme.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  List<Incidente> _incidentes = [];
  List<Prediccion> _predicciones = [];
  bool _isLoading = true;
  bool _isDarkMode = true;
  bool _isFullscreen = false;

  // Toggles de capas
  bool _mostrarPoligonos = true;
  bool _mostrarIncidentes = false;
  bool _mostrarNumeros = false;
  bool _mostrarHeatmap = true;

  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // Heatmap Image
  MemoryImage? _heatmapImage;

  // Tiempo
  late Timer _clockTimer;
  String _franjaActual = '';

  @override
  void initState() {
    super.initState();
    _franjaActual = _getFranjaActual();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _franjaActual = _getFranjaActual());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  String _getFranjaActual() {
    final h = DateTime.now().toUtc().subtract(const Duration(hours: 5)).hour;
    if (h < 3) return '00:00 - 02:59';
    if (h < 6) return '03:00 - 05:59';
    if (h < 9) return '06:00 - 08:59';
    if (h < 12) return '09:00 - 11:59';
    if (h < 15) return '12:00 - 14:59';
    if (h < 18) return '15:00 - 17:59';
    if (h < 21) return '18:00 - 20:59';
    return '21:00 - 23:59';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final incidentesService = IncidentesService();
    final prediccionesService = PrediccionesService();

    // Load independently so one failure doesn't break the other
    List<Incidente> incidentes = [];
    List<Prediccion> predicciones = [];

    try {
      incidentes = await incidentesService.getIncidentesMapa();
      debugPrint('Ciudadano: ${incidentes.length} incidentes cargados');
    } catch (e) {
      debugPrint('Ciudadano ERROR incidentes: $e');
    }

    try {
      predicciones = await prediccionesService.getPrediccionesMapa();
      debugPrint('Ciudadano: ${predicciones.length} predicciones cargadas');
    } catch (e) {
      debugPrint('Ciudadano ERROR predicciones: $e');
    }

    if (mounted) {
      setState(() {
        _incidentes = incidentes;
        _predicciones = predicciones;
        _isLoading = false;
      });
      _generateHeatmap();
    }
  }

  Future<void> _generateHeatmap() async {
    if (!_mostrarHeatmap || _incidentes.isEmpty) {
      if (mounted) setState(() => _heatmapImage = null);
      return;
    }

    const double minLat = -12.095, maxLat = -12.055;
    const double minLng = -77.070, maxLng = -77.025;
    const int gridWidth = 200, gridHeight = 200;
    final double dLat = (maxLat - minLat) / gridHeight;
    final double dLng = (maxLng - minLng) / gridWidth;
    final List<Float32List> grid = List.generate(gridHeight, (_) => Float32List(gridWidth));
    const double h = 0.0028;
    final double radiusY = h / dLat;
    final double radiusX = h / dLng;

    for (final inc in _incidentes) {
      if (inc.latitud == 0 || inc.longitud == 0) continue;
      if (inc.latitud < minLat || inc.latitud > maxLat || inc.longitud < minLng || inc.longitud > maxLng) continue;
      final double ix = (inc.longitud - minLng) / dLng;
      final double iy = (inc.latitud - minLat) / dLat;
      
      final int minY = (iy - radiusY).floor().clamp(0, gridHeight - 1);
      final int maxY2 = (iy + radiusY).ceil().clamp(0, gridHeight - 1);
      final int minX = (ix - radiusX).floor().clamp(0, gridWidth - 1);
      final int maxX2 = (ix + radiusX).ceil().clamp(0, gridWidth - 1);

      for (int y = minY; y <= maxY2; y++) {
        for (int x = minX; x <= maxX2; x++) {
          final double clat = minLat + (y + 0.5) * dLat;
          final double clng = minLng + (x + 0.5) * dLng;
          final double dy = clat - inc.latitud;
          final double dx = (clng - inc.longitud) * 0.978;
          final double dist = (dx * dx + dy * dy);
          if (dist < h * h) {
            final double u = (math.sqrt(dist)) / h;
            grid[y][x] += (1 - u * u) * (1 - u * u);
          }
        }
      }
    }

    double maxVal = 0.0001;
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (grid[y][x] > maxVal) maxVal = grid[y][x];
      }
    }

    final Uint8List pixels = Uint8List(gridWidth * gridHeight * 4);
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        final double val = grid[y][x] / maxVal;
        final int pixelY = gridHeight - 1 - y;
        final int pixelIdx = (pixelY * gridWidth + x) * 4;
        
        if (val > 0.015) {
          int r, g, b, a;
          if (val < 0.15) {
            final double t = val / 0.15;
            r = 250; g = 204; b = 21;
            a = (t * 0.35 * 255).round();
          } else if (val < 0.5) {
            final double t = (val - 0.15) / 0.35;
            r = (250 + t * (249 - 250)).round();
            g = (204 + t * (115 - 204)).round();
            b = (21 + t * (22 - 21)).round();
            a = ((0.35 + t * 0.40) * 255).round();
          } else {
            final double t = (val - 0.5) / 0.5;
            r = (249 + t * (239 - 249)).round();
            g = (115 + t * (68 - 115)).round();
            b = (22 + t * (68 - 22)).round();
            a = ((0.75 + t * 0.15) * 255).round();
          }
          if (!_isDarkMode) a = (a * 0.75).round();
          
          final double alphaFactor = a / 255.0;
          pixels[pixelIdx] = (r * alphaFactor).round().clamp(0, 255);
          pixels[pixelIdx + 1] = (g * alphaFactor).round().clamp(0, 255);
          pixels[pixelIdx + 2] = (b * alphaFactor).round().clamp(0, 255);
          pixels[pixelIdx + 3] = a.clamp(0, 255);
        }
      }
    }

    ui.decodeImageFromPixels(
      pixels,
      gridWidth,
      gridHeight,
      ui.PixelFormat.rgba8888,
      (ui.Image img) async {
        final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null && mounted) {
          setState(() {
            _heatmapImage = MemoryImage(byteData.buffer.asUint8List());
          });
        }
      },
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchNominatim(query);
    });
  }

  Future<void> _searchNominatim(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$query, Jesús María, Lima, Perú',
          'format': 'json',
          'limit': 5,
          'bounded': 1,
          'viewbox': '-77.070,-12.055,-77.025,-12.095',
        },
        options: Options(headers: {'User-Agent': 'SafePointApp/1.0'}),
      );
      if (response.statusCode == 200 && response.data is List) {
        if (mounted) setState(() => _searchResults = response.data as List);
      }
    } catch (e) {
      debugPrint('Error búsqueda Nominatim: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(dynamic result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    _mapController.move(LatLng(lat, lon), 17);
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocus.unfocus();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _resetRotation() {
    _mapController.rotate(0.0);
  }

  List<Polygon> _buildPolygons() {
    if (!_mostrarPoligonos) return [];

    final sectores = [
      AppConstants.sector1, AppConstants.sector2, AppConstants.sector3,
      AppConstants.sector4, AppConstants.sector5, AppConstants.sector6,
      AppConstants.sector7, AppConstants.sector8, AppConstants.sector9,
    ];

    return sectores.asMap().entries.map((entry) {
      final idx = entry.key;
      final coords = entry.value;
      final sectorId = '${idx + 1}';

      double probPromedio = 0.0;
      try {
        final predsSector = _predicciones.where((p) => p.sector == sectorId || p.sector == 'Sector $sectorId').toList();
        if (predsSector.isNotEmpty) {
          probPromedio = predsSector.map((p) => p.probabilidad).reduce((a, b) => a + b) / predsSector.length;
        }
      } catch (e) {
        // Ignorar si no hay predicción para el sector
      }

      Color fillBaseColor;
      Color borderBaseColor;

      if (probPromedio > 0.66) {
        fillBaseColor = AppTheme.riskHigh;
        borderBaseColor = AppTheme.riskHigh;
      } else if (probPromedio >= 0.33) {
        fillBaseColor = AppTheme.riskMed;
        borderBaseColor = AppTheme.riskMed;
      } else {
        fillBaseColor = AppTheme.riskLow;
        borderBaseColor = AppTheme.riskLow;
      }

      return Polygon(
        points: coords.map((c) => LatLng(c[0], c[1])).toList(),
        color: Colors.transparent,
        borderStrokeWidth: 3,
        borderColor: borderBaseColor.withValues(alpha: 0.8),
      );
    }).toList();
  }

  List<Marker> _buildIncidentesMarkers() {
    if (!_mostrarIncidentes) return [];

    return _incidentes.map((i) {
      if (i.latitud == 0 || i.longitud == 0) return null;
      final isRobo = i.tipoDelito.toUpperCase() == 'ROBO';
      return Marker(
        point: LatLng(i.latitud, i.longitud),
        width: 12,
        height: 12,
        child: Container(
          decoration: BoxDecoration(
            color: isRobo ? AppTheme.riskHigh : AppTheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Capas del Mapa',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Activa o desactiva las capas visuales',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              _buildLayerToggle(
                'Mapa de Calor (KDE)',
                'Densidad de incidentes históricos',
                Icons.whatshot,
                _mostrarHeatmap,
                (val) {
                  setModalState(() => _mostrarHeatmap = val);
                  setState(() {});
                  _generateHeatmap();
                },
              ),
              const SizedBox(height: 12),
              _buildLayerToggle(
                'Polígonos de Riesgo',
                'Sectores coloreados por nivel de predicción',
                Icons.hexagon_outlined,
                _mostrarPoligonos,
                (val) {
                  setModalState(() => _mostrarPoligonos = val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              _LayerToggle(
                icon: Icons.pin_drop,
                label: 'Puntos de Incidentes',
                value: _mostrarIncidentes,
                onChanged: (v) {
                  setModalState(() => _mostrarIncidentes = v);
                  setState(() {});
                },
              ),
              if (_mostrarIncidentes) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _LayerToggle(
                    icon: Icons.numbers,
                    label: 'Mostrar cantidad por punto',
                    value: _mostrarNumeros,
                    onChanged: (v) {
                      setModalState(() => _mostrarNumeros = v);
                      setState(() {});
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerToggle(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? AppTheme.primary : AppTheme.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: value ? Colors.white : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.border,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkTile = 'https://api.maptiler.com/maps/basic-v2-dark/256/{z}/{x}/{y}.png?key=jPBrASxMmEi3FPAa6tvR';
    const lightTile = 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
    final tileUrl = _isDarkMode ? darkTile : lightTile;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(AppConstants.jesusMariaLat, AppConstants.jesusMariaLng),
                    initialZoom: 14.5,
                    maxZoom: 18,
                    minZoom: 12,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tileUrl,
                      userAgentPackageName: 'com.safepoint.mobile',
                    ),
                    if (_mostrarHeatmap && _heatmapImage != null)
                      OverlayImageLayer(
                        overlayImages: [
                          OverlayImage(
                            bounds: LatLngBounds(
                              const LatLng(-12.095, -77.070),
                              const LatLng(-12.055, -77.025),
                            ),
                            imageProvider: _heatmapImage!,
                            opacity: 0.65,
                          ),
                        ],
                      ),
                    PolygonLayer(polygons: _buildPolygons()),
                    if (_mostrarIncidentes && !_mostrarNumeros)
                      MarkerLayer(
                        markers: _incidentes.where((i) => i.latitud != 0 && i.longitud != 0).map((inc) {
                          return Marker(
                            point: LatLng(inc.latitud, inc.longitud),
                            width: 14,
                            height: 14,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3b82f6).withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    if (_mostrarIncidentes && _mostrarNumeros)
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 35,
                          size: const Size(24, 24),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(50),
                          maxZoom: 18,
                          markers: _buildIncidentesMarkers(),
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3b82f6),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  markers.length.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),

          // Franja Activa
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (_isDarkMode ? AppTheme.surface : Colors.white).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isDarkMode ? AppTheme.border : Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: AppTheme.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Franja Activa: $_franjaActual',
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Barra de búsqueda superior
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_isDarkMode ? AppTheme.surface : Colors.white).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: _isDarkMode ? AppTheme.textMuted : Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Buscar zona o dirección...',
                                  hintStyle: TextStyle(color: _isDarkMode ? AppTheme.textMuted : Colors.grey, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                  _searchFocus.unfocus();
                                },
                                child: Icon(Icons.close, color: _isDarkMode ? AppTheme.textMuted : Colors.grey, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: (_isDarkMode ? AppTheme.surface : Colors.white).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.tune, color: _isDarkMode ? Colors.white : Colors.black87),
                        onPressed: _showFilterPanel,
                      ),
                    ),
                  ],
                ),
                // Resultados de búsqueda
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: (_isDarkMode ? AppTheme.surface : Colors.white).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _searchResults.take(5).map((result) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
                          title: Text(
                            result['display_name'] ?? '',
                            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Controles flotantes laterales
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              children: [
                _MapControlButton(
                  icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  onPressed: () {
                    setState(() => _isFullscreen = !_isFullscreen);
                  },
                  isDark: _isDarkMode,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  onPressed: () {
                    setState(() => _isDarkMode = !_isDarkMode);
                    _generateHeatmap();
                  },
                  isDark: _isDarkMode,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.explore_outlined,
                  onPressed: _resetRotation,
                  isDark: _isDarkMode,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                  isDark: _isDarkMode,
                ),
                const SizedBox(height: 4),
                _MapControlButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                  isDark: _isDarkMode,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.my_location,
                  onPressed: () {
                    _mapController.move(const LatLng(AppConstants.jesusMariaLat, AppConstants.jesusMariaLng), 14.5);
                    _resetRotation();
                  },
                  isDark: _isDarkMode,
                ),
              ],
            ),
          ),

          // Leyenda
          Positioned(
            left: 16,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (_isDarkMode ? AppTheme.surface : Colors.white).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isDarkMode ? AppTheme.border : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Niveles de Riesgo', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _LegendItem(color: AppTheme.riskHigh, label: 'Alto (>66%)', isDark: _isDarkMode),
                  const SizedBox(height: 3),
                  _LegendItem(color: AppTheme.riskMed, label: 'Medio (33-66%)', isDark: _isDarkMode),
                  const SizedBox(height: 3),
                  _LegendItem(color: AppTheme.riskLow, label: 'Bajo (<33%)', isDark: _isDarkMode),
                  if (_mostrarHeatmap) ...[
                    const SizedBox(height: 6),
                    Text('Densidad', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22c55e), Color(0xFFfacc15), Color(0xFFf97316), Color(0xFFef4444)],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Indicador de carga
          if (_isSearching)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: const Center(child: LinearProgressIndicator(color: AppTheme.primary, minHeight: 2)),
            ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.surface : Colors.white).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.border : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black87, fontSize: 10)),
      ],
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LayerToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? AppTheme.primary : AppTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
