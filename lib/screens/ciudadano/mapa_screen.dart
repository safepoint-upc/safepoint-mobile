import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../services/predicciones_service.dart';
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
  final PrediccionesService _prediccionesService = PrediccionesService();

  List<Map<String, dynamic>> _prediccionesPorCuadrante = [];
  Map<String, dynamic>? _geojsonCuadrantes;
  bool _isLoading = true;
  bool _isDarkMode = true;

  // Búsqueda de direcciones
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // Franja horaria actual de Lima (UTC-5)
  late Timer _clockTimer;
  String _franjaActual = '';

  @override
  void initState() {
    super.initState();
    _franjaActual = AppConstants.getFranjaActual();
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
      // Cargamos GeoJSON y predicciones en paralelo
      final results = await Future.wait([
        _loadGeoJson(),
        _prediccionesService.getPrediccionesPorCuadrante(
          franjaHoraria: _franjaActual,
        ),
      ]);

      if (mounted) {
        setState(() {
          _geojsonCuadrantes = results[0] as Map<String, dynamic>?;
          _prediccionesPorCuadrante = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR _loadData ciudadano: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Carga el GeoJSON de los 52 cuadrantes desde assets
  Future<Map<String, dynamic>?> _loadGeoJson() async {
    try {
      final String data = await rootBundle.loadString('assets/Cuadrantes.geojson');
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ERROR cargando GeoJSON ciudadano: $e');
      return null;
    }
  }

  // Construye los polígonos de cuadrantes coloreados por nivel de riesgo
  List<Polygon> _buildPolygons() {
    if (_geojsonCuadrantes == null) return [];

    final features = _geojsonCuadrantes!['features'] as List<dynamic>;

    return features.map((feature) {
      final props = feature['properties'] as Map<String, dynamic>;
      final cuadranteId = props['cuadrante']?.toString() ?? '';

      // Busca la predicción de este cuadrante
      final pred = _prediccionesPorCuadrante.firstWhere(
            (p) => p['cuadrante']?.toString() == cuadranteId,
        orElse: () => {},
      );

      // Determina el color: nivel_riesgo primero, probabilidad como fallback
      Color color;
      if (pred.isNotEmpty) {
        final nivelRiesgo = pred['nivel_riesgo'];
        final prob = (pred['probabilidad_promedio'] as num?)?.toDouble() ?? 0.0;

        if (nivelRiesgo == 2) color = AppTheme.riskHigh;
        else if (nivelRiesgo == 1) color = AppTheme.riskMed;
        else if (nivelRiesgo == 0) color = AppTheme.riskLow;
        else if (prob > 0.66) color = AppTheme.riskHigh;
        else if (prob >= 0.33) color = AppTheme.riskMed;
        else color = AppTheme.riskLow;
      } else {
        color = AppTheme.textMuted;
      }

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

  // Búsqueda de direcciones con Nominatim
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
      debugPrint('ERROR búsqueda Nominatim ciudadano: $e');
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
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.safepoint.mobile',
              ),
              // Solo mostramos cuadrantes coloreados — sin heatmap ni puntos de incidentes
              PolygonLayer(polygons: _buildPolygons()),
            ],
          ),

          // Barra de búsqueda
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
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
                          child: const Icon(
                            Icons.close,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
                // Resultados de búsqueda
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
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

          // Controles del mapa
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              children: [
                MapControlButton(
                  icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
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
                MapControlButton(
                  icon: Icons.my_location,
                  onPressed: () {
                    _mapController.move(
                      const LatLng(
                        AppConstants.jesusMariaLat,
                        AppConstants.jesusMariaLng,
                      ),
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nivel de Riesgo',
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