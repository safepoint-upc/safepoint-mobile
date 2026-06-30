import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  
  // Filtros API
  String? _filtroTipo;
  String? _filtroSector;
  String? _filtroFranja;
  String? _filtroAnio;
  String? _filtroMes;
  String? _filtroDia;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _tipos = ['HURTO', 'ROBO', 'ESTAFA', 'USURPACION', 'EXTORSIÓN', 'CONTRA EL PATRIMONIO'];
  static const List<String> _sectores = ['Sector 1','Sector 2','Sector 3','Sector 4','Sector 5','Sector 6','Sector 7','Sector 8','Sector 9'];
  static const List<String> _franjas = ['Madrugada', 'Mañana', 'Tarde', 'Noche'];
  static const List<String> _anios = ['2019', '2020', '2021', '2022', '2023', '2024'];
  static const List<String> _meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
  static const List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  // Paginación Local
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
      // Mandar filtros al API (Backend supports filtering for performance)
      // Mapear el mes texto a número para el backend
      String? backendMes;
      if (_filtroMes != null) {
        backendMes = (_meses.indexOf(_filtroMes!) + 1).toString();
      }

      final result = await _service.getIncidentes(
        sector: _filtroSector?.replaceAll('Sector ', ''),
        tipoDelito: _filtroTipo,
        franjaHoraria: _filtroFranja,
        anio: _filtroAnio,
        mes: backendMes,
        diaSemana: _filtroDia,
      );
      
      if (mounted) {
        setState(() {
          _incidentes = result;
          _applyFiltersLocal();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFiltersLocal() {
    // Aplicamos solo filtro de búsqueda de texto localmente porque el API no tiene "q" o query
    _filtrados = _incidentes.where((i) {
      final matchBusqueda = _busqueda.isEmpty ||
          i.avenida.toLowerCase().contains(_busqueda.toLowerCase()) ||
          i.cuadra.toLowerCase().contains(_busqueda.toLowerCase());
      return matchBusqueda;
    }).toList();

    _totalPaginas = (_filtrados.length / _porPagina).ceil();
    if (_totalPaginas == 0) _totalPaginas = 1;
    if (_paginaActual > _totalPaginas) _paginaActual = 1;
  }

  void _onFilterChanged() {
    // Al cambiar un dropdown, relanzar consulta a la BD
    _paginaActual = 1;
    _loadIncidentes();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  void _showDetalle(Incidente incidente) {
    final dateStr = DateFormat('dd/MM/yyyy').format(incidente.fecha);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Incidente #${incidente.id}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(incidente.tipoDelito, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetalleRow(label: 'Dirección', value: _capitalize(incidente.avenida)),
            _DetalleRow(label: 'Cuadra', value: incidente.cuadra),
            _DetalleRow(label: 'Fecha', value: dateStr),
            _DetalleRow(label: 'Hora', value: incidente.hora),
            _DetalleRow(label: 'Sector', value: 'Sector ${incidente.sector}'),
            _DetalleRow(label: 'Cuadrante', value: incidente.cuadrante),
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
    final currentItems = _filtrados.isEmpty ? <Incidente>[] : _filtrados.sublist(startIndex, endIndex);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() { _busqueda = v; _applyFiltersLocal(); }),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por avenida o cuadra...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                        onPressed: () => setState(() { _busqueda = ''; _searchController.clear(); _applyFiltersLocal(); }),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _DropFilter(label: _filtroTipo ?? 'Tipo', options: _tipos, selected: _filtroTipo, onSelected: (v) { _filtroTipo = v; _onFilterChanged(); }),
                  const SizedBox(width: 8),
                  _DropFilter(label: _filtroSector ?? 'Sector', options: _sectores, selected: _filtroSector, onSelected: (v) { _filtroSector = v; _onFilterChanged(); }),
                  const SizedBox(width: 8),
                  _DropFilter(label: _filtroFranja ?? 'Franja', options: _franjas, selected: _filtroFranja, onSelected: (v) { _filtroFranja = v; _onFilterChanged(); }),
                  const SizedBox(width: 8),
                  _DropFilter(label: _filtroAnio ?? 'Año', options: _anios, selected: _filtroAnio, onSelected: (v) { _filtroAnio = v; _onFilterChanged(); }),
                  const SizedBox(width: 8),
                  _DropFilter(label: _filtroMes ?? 'Mes', options: _meses, selected: _filtroMes, onSelected: (v) { _filtroMes = v; _onFilterChanged(); }),
                  const SizedBox(width: 8),
                  _DropFilter(label: _filtroDia ?? 'Día', options: _dias, selected: _filtroDia, onSelected: (v) { _filtroDia = v; _onFilterChanged(); }),
                  if (_filtroTipo != null || _filtroSector != null || _filtroFranja != null || _filtroAnio != null || _filtroMes != null || _filtroDia != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _filtroTipo = null; _filtroSector = null; _filtroFranja = null; _filtroAnio = null; _filtroMes = null; _filtroDia = null;
                        _onFilterChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.riskHigh.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.riskHigh.withValues(alpha: 0.3)),
                        ),
                        child: const Text('Limpiar', style: TextStyle(color: AppTheme.riskHigh, fontSize: 13)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_filtrados.length} resultados encontrados', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filtrados.isEmpty
                    ? const Center(child: Text('Sin resultados', style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: currentItems.length,
                        itemBuilder: (context, index) {
                          final i = currentItems[index];
                          final actualIndex = startIndex + index + 1;
                          final dateStr = DateFormat('dd/MM/yyyy').format(i.fecha);
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
                                    child: const Icon(Icons.report_outlined, color: AppTheme.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(i.tipoDelito, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                                              child: Text('S${i.sector}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                            const Spacer(),
                                            Text('#$actualIndex', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(_capitalize(i.avenida), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text('$dateStr ${i.hora}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Paginación Footer
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
                    onPressed: _paginaActual > 1 ? () => setState(() => _paginaActual--) : null,
                    icon: Icon(Icons.chevron_left, color: _paginaActual > 1 ? AppTheme.primary : AppTheme.textMuted),
                    label: Text('Ant', style: TextStyle(color: _paginaActual > 1 ? AppTheme.primary : AppTheme.textMuted)),
                  ),
                  Text(
                    'Pág $_paginaActual de $_totalPaginas',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: _paginaActual < _totalPaginas ? () => setState(() => _paginaActual++) : null,
                    icon: Icon(Icons.chevron_right, color: _paginaActual < _totalPaginas ? AppTheme.primary : AppTheme.textMuted),
                    label: Text('Sig', style: TextStyle(color: _paginaActual < _totalPaginas ? AppTheme.primary : AppTheme.textMuted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _DropFilter extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final Function(String?) onSelected;
  const _DropFilter({required this.label, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('Todos', style: TextStyle(color: AppTheme.textSecondary)),
                      onTap: () => Navigator.pop(context, null),
                    ),
                    ...options.map((o) => ListTile(
                      title: Text(o, style: TextStyle(
                        color: selected == o ? AppTheme.primary : Colors.white,
                        fontWeight: selected == o ? FontWeight.bold : FontWeight.normal,
                      )),
                      trailing: selected == o ? const Icon(Icons.check, color: AppTheme.primary, size: 18) : null,
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
          color: selected != null ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected != null ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: selected != null ? AppTheme.primary : AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: selected != null ? AppTheme.primary : AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
