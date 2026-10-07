import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../services/incidentes_service.dart';
import '../../models/incidente.dart';
import '../../theme/app_theme.dart';

class IncidentesScreen extends StatefulWidget {
  const IncidentesScreen({super.key});

  @override
  State<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends State<IncidentesScreen> {
  final IncidentesService _service = IncidentesService();
  List<Incidente> _incidentes = [];
  List<Incidente> _filtrados = [];

  bool _isLoading = true;
  String _busqueda = '';

  // Filtros que se envían al backend
  String? _filtroTipo;
  String? _filtroSector;
  String? _filtroFranja;
  String? _filtroAnio;
  String? _filtroMes;
  String? _filtroDia;

  final TextEditingController _searchController = TextEditingController();

  // Opciones de filtros — tipos y franjas según el dataset real
  static const List<String> _tipos = [
    'HURTO', 'ROBO', 'ESTAFA', 'USURPACION', 'EXTORSIÓN', 'CONTRA EL PATRIMONIO',
  ];
  static const List<String> _franjas = [
    'De 00:00 a 02:59 H.',
    'De 03:00 a 05:59 H.',
    'De 06:00 a 08:59 H.',
    'De 09:00 a 11:59 H.',
    'De 12:00 a 14:59 H.',
    'De 15:00 a 17:59 H.',
    'De 18:00 a 20:59 H.',
    'De 21:00 a 23:59 H.',
  ];
  // Años del dataset real (2023-2026)
  static const List<String> _anios = ['2023', '2024', '2025', '2026'];
  static const List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const List<String> _dias = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  // Paginación local
  int _paginaActual = 1;
  static const int _porPagina = 50;
  int _totalPaginas = 1;

  @override
  void initState() {
    super.initState();
    _loadIncidentes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidentes() async {
    setState(() => _isLoading = true);
    try {
      // Usamos getIncidentesMapa que devuelve incidentes con coordenadas
      // y soporta todos los filtros que necesitamos
      final result = await _service.getIncidentesMapa(
        sector: _filtroSector,
        tipoDelito: _filtroTipo,
        franjaHoraria: _filtroFranja,
        anio: _filtroAnio != null ? int.tryParse(_filtroAnio!) : null,
        mes: _filtroMes,
        diaSemana: _filtroDia,
      );

      if (mounted) {
        setState(() {
          _incidentes = result;
          _applyLocalSearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Aplica filtro de texto localmente sobre los resultados del backend
  void _applyLocalSearch() {
    _filtrados = _incidentes.where((i) {
      if (_busqueda.isEmpty) return true;
      final query = _busqueda.toLowerCase();
      return (i.avenida?.toLowerCase().contains(query) ?? false) ||
          (i.cuadra?.toLowerCase().contains(query) ?? false) ||
          (i.tipoDelito?.toLowerCase().contains(query) ?? false);
    }).toList();

    _totalPaginas = (_filtrados.length / _porPagina).ceil();
    if (_totalPaginas == 0) _totalPaginas = 1;
    if (_paginaActual > _totalPaginas) _paginaActual = 1;
  }

  void _onFilterChanged() {
    _paginaActual = 1;
    _loadIncidentes();
  }

  void _clearFilters() {
    setState(() {
      _filtroTipo = null;
      _filtroSector = null;
      _filtroFranja = null;
      _filtroAnio = null;
      _filtroMes = null;
      _filtroDia = null;
    });
    _onFilterChanged();
  }

  // Capitaliza la primera letra de cada palabra
  String _capitalize(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.split(' ').map((w) => w.isEmpty
        ? w
        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  void _showDetalle(Incidente incidente) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Incidente #${incidente.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Badge con el tipo de delito
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    incidente.tipoDelito ?? '-',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetalleRow(
              label: 'Dirección',
              value: _capitalize(incidente.avenida),
            ),
            _DetalleRow(
              label: 'Cuadra',
              value: incidente.cuadra ?? '-',
            ),
            _DetalleRow(
              label: 'Fecha',
              value: DateFormat('dd/MM/yyyy').format(incidente.fecha),
            ),
            _DetalleRow(label: 'Hora', value: incidente.hora),
            _DetalleRow(
              label: 'Sector',
              value: incidente.sectorGps ?? incidente.sector ?? '-',
            ),
            _DetalleRow(
              label: 'Cuadrante',
              value: incidente.cuadranteGps ?? incidente.cuadrante ?? '-',
            ),
            _DetalleRow(
              label: 'Franja',
              value: incidente.franjaHoraria ?? '-',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = (_paginaActual - 1) * _porPagina;
    final endIndex = math.min(_paginaActual * _porPagina, _filtrados.length);
    final currentItems = _filtrados.isEmpty
        ? <Incidente>[]
        : _filtrados.sublist(startIndex, endIndex);

    final hayFiltros = _filtroTipo != null ||
        _filtroSector != null ||
        _filtroFranja != null ||
        _filtroAnio != null ||
        _filtroMes != null ||
        _filtroDia != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Incidentes Históricos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIncidentes),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda de texto
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _busqueda = v;
                _applyLocalSearch();
              }),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por avenida, cuadra o tipo...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                  onPressed: () => setState(() {
                    _busqueda = '';
                    _searchController.clear();
                    _applyLocalSearch();
                  }),
                )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Filtros desplegables por tipo, sector, franja, año, mes y día
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _DropFilter(
                    label: _filtroTipo ?? 'Tipo',
                    options: _tipos,
                    selected: _filtroTipo,
                    onSelected: (v) { setState(() => _filtroTipo = v); _onFilterChanged(); },
                  ),
                  const SizedBox(width: 8),
                  _DropFilter(
                    label: _filtroFranja != null
                        ? AppConstants.franjaCorta(_filtroFranja!)
                        : 'Franja',
                    options: _franjas,
                    selected: _filtroFranja,
                    onSelected: (v) { setState(() => _filtroFranja = v); _onFilterChanged(); },
                  ),
                  const SizedBox(width: 8),
                  _DropFilter(
                    label: _filtroAnio ?? 'Año',
                    options: _anios,
                    selected: _filtroAnio,
                    onSelected: (v) { setState(() => _filtroAnio = v); _onFilterChanged(); },
                  ),
                  const SizedBox(width: 8),
                  _DropFilter(
                    label: _filtroMes ?? 'Mes',
                    options: _meses,
                    selected: _filtroMes,
                    onSelected: (v) { setState(() => _filtroMes = v); _onFilterChanged(); },
                  ),
                  const SizedBox(width: 8),
                  _DropFilter(
                    label: _filtroDia ?? 'Día',
                    options: _dias,
                    selected: _filtroDia,
                    onSelected: (v) { setState(() => _filtroDia = v); _onFilterChanged(); },
                  ),
                  // Botón para limpiar todos los filtros
                  if (hayFiltros) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.riskHigh.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.riskHigh.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Limpiar',
                          style: TextStyle(color: AppTheme.riskHigh, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_filtrados.length} resultados',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Lista de incidentes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filtrados.isEmpty
                ? const Center(
              child: Text(
                'Sin resultados',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: currentItems.length,
              itemBuilder: (context, index) {
                final i = currentItems[index];
                final actualIndex = startIndex + index + 1;
                return GestureDetector(
                  onTap: () => _showDetalle(i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.report_outlined,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    i.tipoDelito ?? '-',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Badge del sector/cuadrante
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      i.cuadranteGps ?? i.cuadrante ?? '-',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '#$actualIndex',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _capitalize(i.avenida),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(i.fecha)} ${i.hora}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Paginación
          if (!_isLoading && _filtrados.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _paginaActual > 1
                        ? () => setState(() => _paginaActual--)
                        : null,
                    icon: Icon(
                      Icons.chevron_left,
                      color: _paginaActual > 1 ? AppTheme.primary : AppTheme.textMuted,
                    ),
                    label: Text(
                      'Anterior',
                      style: TextStyle(
                        color: _paginaActual > 1 ? AppTheme.primary : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    'Pág $_paginaActual de $_totalPaginas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _paginaActual < _totalPaginas
                        ? () => setState(() => _paginaActual++)
                        : null,
                    icon: Icon(
                      Icons.chevron_right,
                      color: _paginaActual < _totalPaginas
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                    label: Text(
                      'Siguiente',
                      style: TextStyle(
                        color: _paginaActual < _totalPaginas
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Fila de detalle en el modal ────────────────────────────────────────────
class _DetalleRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetalleRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filtro desplegable reutilizable ────────────────────────────────────────
class _DropFilter extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final Function(String?) onSelected;

  const _DropFilter({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text(
                        'Todos',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      onTap: () => Navigator.pop(context, null),
                    ),
                    ...options.map((o) => ListTile(
                      title: Text(
                        o,
                        style: TextStyle(
                          color: selected == o ? AppTheme.primary : Colors.white,
                          fontWeight: selected == o
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: selected == o
                          ? const Icon(Icons.check,
                          color: AppTheme.primary, size: 18)
                          : null,
                      onTap: () => Navigator.pop(context, o),
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
        onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected != null
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null
                ? AppTheme.primary.withValues(alpha: 0.5)
                : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected != null ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: selected != null ? AppTheme.primary : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}