import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/map_control_button.dart';
import '../../widgets/map_legend_item.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  final IncidentesService _incidentesService = IncidentesService();
  final PrediccionesService _prediccionesService = PrediccionesService();

  List<Incidente> _incidentes = [];
  List<Map<String, dynamic>> _prediccionesPorCuadrante = [];
  bool _isLoading = true;
  bool _isDarkMode = true;

// Toggles de capas del mapa
  bool _mostrarPoligonos = true;
  bool _mostrarIncidentes = false;
  bool _mostrarNumeros = false;
  bool _mostrarHeatmap = true;

// Búsqueda de direcciones con Nominatim
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

// Imagen del heatmap generada en memoria
  MemoryImage? _heatmapImage;

// GeoJSON de los 52 cuadrantes cargado desde assets
  Map<String, dynamic>? _geojsonCuadrantes;

// Franja horaria actual de Lima (UTC-5)
  late Timer _clockTimer;
  String _franjaActual = '';

  @override
  void initState() {
    super.initState();
    _franjaActual = AppConstants.getFranjaActual();
// Actualiza la franja activa cada minuto
    _clockTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) { if (mounted) setState(() => _franjaActual = AppConstants.getFranjaActual()); },
    );
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
// Cargamos todo en paralelo para mayor velocidad
      final results = await Future.wait([
        _loadGeoJson(),
        _incidentesService.getIncidentesMapa(),
        _prediccionesService.getPrediccionesPorCuadrante(
          franjaHoraria: _franjaActual,
        ),
      ]);

      if (mounted) {
        setState(() {
          _geojsonCuadrantes = results[0] as Map<String, dynamic>?;
          _incidentes = results[1] as List<Incidente>;
          _prediccionesPorCuadrante = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
        _generateHeatmap();
      }
    } catch (e) {
      debugPrint('ERROR _loadData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Carga el GeoJSON de los 52 cuadrantes desde los assets de la app
  Future<Map<String, dynamic>?> _loadGeoJson() async {
    try {
      final String data = await rootBundle.loadString('assets/Cuadrantes.geojson');
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ERROR cargando GeoJSON: $e');
      return null;
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
    final List<Float32List> grid =
    List.generate(gridHeight, (_) => Float32List(gridWidth));
    const double h = 0.0028;
    final double radiusY = h / dLat;
    final double radiusX = h / dLng;

    for (final inc in _incidentes) {
// Solo incidentes con coordenadas válidas dentro del distrito
      final lat = inc.latitud;
      final lng = inc.longitud;
      if (lat == null || lng == null) continue;
      if (lat < minLat || lat > maxLat || lng < minLng || lng > maxLng) continue;

      final double ix = (lng - minLng) / dLng;
      final double iy = (lat - minLat) / dLat;

      final int minY = (iy - radiusY).floor().clamp(0, gridHeight - 1);
      final int maxY2 = (iy + radiusY).ceil().clamp(0, gridHeight - 1);
      final int minX = (ix - radiusX).floor().clamp(0, gridWidth - 1);
      final int maxX2 = (ix + radiusX).ceil().clamp(0, gridWidth - 1);

      for (int y = minY; y <= maxY2; y++) {
        for (int x = minX; x <= maxX2; x++) {
          final double clat = minLat + (y + 0.5) * dLat;
          final double clng = minLng + (x + 0.5) * dLng;
          final double dy = clat - lat;
          final double dx = (clng - lng) * 0.978;
          final double dist = dx * dx + dy * dy;
          if (dist < h * h) {
            final double u = math.sqrt(dist) / h;
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
      pixels, gridWidth, gridHeight, ui.PixelFormat.rgba8888,
          (ui.Image img) async {
        final ByteData? byteData =
        await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null && mounted) {
          setState(() {
            _heatmapImage = MemoryImage(byteData.buffer.asUint8List());
          });
        }
      },
    );
  }

// Búsqueda de direcciones usando Nominatim (servicio externo de OpenStreetMap)
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
// Usamos un Dio separado para Nominatim ya que es un servicio externo
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
      debugPrint('ERROR búsqueda Nominatim: $e');
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

  void _zoomIn() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom + 1);

  void _zoomOut() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom - 1);

  void _resetRotation() => _mapController.rotate(0.0);
// Construye los polígonos de los 52 cuadrantes coloreados según nivel de riesgo
// Usa nivel_riesgo primero (igual que el dashboard web) y probabilidad como fallback
  List<Polygon> _buildPolygons() {
    if (!_mostrarPoligonos || _geojsonCuadrantes == null) return [];

    final features = _geojsonCuadrantes!['features'] as List<dynamic>;

    return features.map((feature) {
      final props = feature['properties'] as Map<String, dynamic>;
      final cuadranteId = props['cuadrante']?.toString() ?? '';

// Busca la predicción correspondiente a este cuadrante
      final pred = _prediccionesPorCuadrante.firstWhere(
            (p) => p['cuadrante']?.toString() == cuadranteId,
        orElse: () => {},
      );

// Determina el color según nivel_riesgo primero, probabilidad como fallback
      Color color;
      if (pred.isNotEmpty) {
        final nivelRiesgo = pred['nivel_riesgo'];
        final probabilidad = (pred['probabilidad_promedio'] as num?)?.toDouble() ?? 0.0;

        if (nivelRiesgo == 2 || nivelRiesgo == 'ALTO') {
          color = AppTheme.riskHigh;
        } else if (nivelRiesgo == 1 || nivelRiesgo == 'MEDIO') {
          color = AppTheme.riskMed;
        } else if (nivelRiesgo == 0 || nivelRiesgo == 'BAJO') {
          color = AppTheme.riskLow;
        } else if (probabilidad > 0.66) {
          color = AppTheme.riskHigh;
        } else if (probabilidad >= 0.33) {
          color = AppTheme.riskMed;
        } else {
          color = AppTheme.riskLow;
        }
      } else {
// Sin predicción disponible para este cuadrante
        color = AppTheme.textMuted;
      }

// Extrae las coordenadas del polígono del GeoJSON
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      List<LatLng> points = [];
      if (type == 'Polygon') {
        final ring = coordinates[0] as List<dynamic>;
        points = ring.map((c) => LatLng(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        )).toList();
      } else if (type == 'MultiPolygon') {
        final ring = coordinates[0][0] as List<dynamic>;
        points = ring.map((c) => LatLng(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        )).toList();
      }

      return Polygon(
        points: points,
        color: color.withValues(alpha: 0.15),
        borderStrokeWidth: 2,
        borderColor: color.withValues(alpha: 0.8),
      );
    }).toList();
  }

// Construye los marcadores de incidentes para el modo de puntos individuales
  List<Marker> _buildIncidentesMarkers() {
    if (!_mostrarIncidentes) return [];

    return _incidentes
        .where((i) => i.latitud != null && i.longitud != null)
        .map((i) {
      return Marker(
        point: LatLng(i.latitud!, i.longitud!),
        width: 12,
        height: 12,
        child: Container(
          decoration: BoxDecoration(
// Color diferente según tipo de delito
            color: (i.tipoDelito?.toUpperCase() == 'ROBO'
                ? AppTheme.riskHigh
                : AppTheme.primary)
                .withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      );
    })
        .toList();
  }

// Panel inferior para activar o desactivar capas del mapa
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Capas del Mapa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Activa o desactiva las capas visuales',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              _LayerToggle(
                icon: Icons.whatshot,
                label: 'Mapa de Calor',
                sublabel: 'Densidad de incidentes históricos',
                value: _mostrarHeatmap,
                onChanged: (val) {
                  setModalState(() => _mostrarHeatmap = val);
                  setState(() {});
                  _generateHeatmap();
                },
              ),
              const SizedBox(height: 12),
              _LayerToggle(
                icon: Icons.hexagon_outlined,
                label: 'Cuadrantes de Riesgo',
                sublabel: 'Polígonos coloreados por nivel de predicción',
                value: _mostrarPoligonos,
                onChanged: (val) {
                  setModalState(() => _mostrarPoligonos = val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              _LayerToggle(
                icon: Icons.pin_drop,
                label: 'Puntos de Incidentes',
                sublabel: 'Ubicación de incidentes registrados',
                value: _mostrarIncidentes,
                onChanged: (val) {
                  setModalState(() => _mostrarIncidentes = val);
                  setState(() {});
                },
              ),
              if (_mostrarIncidentes) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _LayerToggle(
                    icon: Icons.numbers,
                    label: 'Agrupar puntos',
                    sublabel: 'Muestra la cantidad por zona',
                    value: _mostrarNumeros,
                    onChanged: (val) {
                      setModalState(() => _mostrarNumeros = val);
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
  @override
  Widget build(BuildContext context) {
    const darkTile = 'https://api.maptiler.com/maps/basic-v2-dark/256/{z}/{x}/{y}.png?key=jPBrASxMmEi3FPAa6tvR';
    const lightTile = 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
    final tileUrl = _isDarkMode ? darkTile : lightTile;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Mapa principal
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(
                AppConstants.jesusMariaLat,
                AppConstants.jesusMariaLng,
              ),
              initialZoom: 14.5,
              maxZoom: 18,
              minZoom: 12,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Capa base del mapa (oscuro o claro)
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.safepoint.mobile',
              ),
              // Capa de heatmap de densidad de incidentes
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
              // Capa de polígonos de cuadrantes coloreados por riesgo
              PolygonLayer(polygons: _buildPolygons()),
              // Capa de puntos individuales de incidentes
              if (_mostrarIncidentes && !_mostrarNumeros)
                MarkerLayer(
                  markers: _incidentes
                      .where((i) => i.latitud != null && i.longitud != null)
                      .map((i) => Marker(
                    point: LatLng(i.latitud!, i.longitud!),
                    width: 14,
                    height: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ))
                      .toList(),
                ),
              // Capa de puntos agrupados con contador
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
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
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
                          color: AppTheme.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Buscar zona o dirección...',
                                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                                child: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Botón para abrir el panel de capas
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        onPressed: _showFilterPanel,
                      ),
                    ),
                  ],
                ),
                // Resultados de búsqueda desplegables
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _searchResults.take(5).map((result) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          title: Text(
                            result['display_name'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
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

          // Franja horaria activa
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: AppTheme.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _franjaActual,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles del mapa (zoom, rotación, modo día/noche)
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              children: [
                MapControlButton(
                  icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  onPressed: () {
                    setState(() => _isDarkMode = !_isDarkMode);
                    _generateHeatmap();
                  },
                ),
                const SizedBox(height: 8),
                MapControlButton(
                  icon: Icons.explore_outlined,
                  onPressed: _resetRotation,
                ),
                const SizedBox(height: 8),
                MapControlButton(icon: Icons.add, onPressed: _zoomIn),
                const SizedBox(height: 4),
                MapControlButton(icon: Icons.remove, onPressed: _zoomOut),
                const SizedBox(height: 8),
                // Vuelve al centro del distrito
                MapControlButton(
                  icon: Icons.my_location,
                  onPressed: () {
                    _mapController.move(
                      const LatLng(AppConstants.jesusMariaLat, AppConstants.jesusMariaLng),
                      14.5,
                    );
                    _resetRotation();
                  },
                ),
              ],
            ),
          ),

          // Leyenda de niveles de riesgo
          Positioned(
            left: 16,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Niveles de Riesgo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  MapLegendItem(color: AppTheme.riskHigh, label: 'Alto'),
                  const SizedBox(height: 3),
                  MapLegendItem(color: AppTheme.riskMed, label: 'Medio'),
                  const SizedBox(height: 3),
                  MapLegendItem(color: AppTheme.riskLow, label: 'Bajo'),
                  if (_mostrarHeatmap) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Densidad histórica',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF22c55e),
                            Color(0xFFfacc15),
                            Color(0xFFf97316),
                            Color(0xFFef4444),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Indicador de búsqueda en progreso
          if (_isSearching)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(
                color: AppTheme.primary,
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Toggle de capa del mapa ────────────────────────────────────────────────
class _LayerToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LayerToggle({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? AppTheme.primary : AppTheme.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: value ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.border,
          ),
        ],
      ),
    );
  }
}