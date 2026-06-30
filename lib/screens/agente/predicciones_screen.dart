import 'package:flutter/material.dart';
import '../../services/predicciones_service.dart';
import '../../models/prediccion.dart';
import '../../theme/app_theme.dart';

class PrediccionesScreen extends StatefulWidget {
  const PrediccionesScreen({super.key});

  @override
  State<PrediccionesScreen> createState() => _PrediccionesScreenState();
}

class _PrediccionesScreenState extends State<PrediccionesScreen> {
  final PrediccionesService _service = PrediccionesService();
  List<Prediccion> _sectores = [];
  List<Prediccion> _ultimas = [];
  List<Prediccion> _ultimasFiltradas = [];
  bool _isLoading = true;
  String _sectorSel = 'Todos';
  String _franjaSel = 'Todas';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final resSectores = await _service.getPrediccionesPorSector();
      final resUltimas = await _service.getUltimas();

      if (mounted) {
        setState(() {
          _sectores = resSectores;
          _ultimas = resUltimas;
          _ultimasFiltradas = resUltimas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _ultimasFiltradas = _ultimas.where((p) {
        final matchSector = _sectorSel == 'Todos' || p.sector == _sectorSel;
        final matchFranja = _franjaSel == 'Todas' || p.franjaHoraria == _franjaSel;
        return matchSector && matchFranja;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Predicciones XGBoost'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
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
                          const Text(
                            'Evaluación Predictiva por Sector',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Modelo v1.0.0 • Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid de sectores
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: _sectores.length,
                      itemBuilder: (context, index) {
                        final s = _sectores[index];
                        final prob = s.probabilidad;
                        final color = prob > 0.66 ? AppTheme.riskHigh : (prob >= 0.33 ? AppTheme.riskMed : AppTheme.riskLow);
                        final riesgoTexto = prob > 0.66 ? 'ALTO' : (prob >= 0.33 ? 'MEDIO' : 'BAJO');

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sector ${s.sector}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      riesgoTexto,
                                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Riesgo Promedio', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                  Text(
                                    '${(prob * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: prob,
                                      backgroundColor: AppTheme.background,
                                      valueColor: AlwaysStoppedAnimation(color),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Gráfico de barras horizontales
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comparativo de Probabilidad por Sector',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Umbral de alerta: 50%',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                          const SizedBox(height: 16),
                          ..._sectores.map((s) {
                            final color = s.probabilidad > 0.66 ? AppTheme.riskHigh : (s.probabilidad >= 0.33 ? AppTheme.riskMed : AppTheme.riskLow);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text('Sector ${s.sector}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Container(
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: AppTheme.background,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: s.probabilidad,
                                          child: Container(
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        // Línea de referencia 50%
                                        Positioned(
                                          left: MediaQuery.of(context).size.width * 0.5 * 0.45,
                                          child: Container(
                                            width: 1.5,
                                            height: 20,
                                            color: AppTheme.riskHigh.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 45,
                                    child: Text(
                                      ' ${(s.probabilidad * 100).toStringAsFixed(1)}%',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filtros
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filtros', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  'Sector',
                                  _sectorSel,
                                  ['Todos', ...List.generate(9, (i) => '${i + 1}')],
                                  (v) => setState(() => _sectorSel = v ?? 'Todos'),
                                  displayFn: (v) => v == 'Todos' ? 'Todos' : 'Sector $v',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown(
                                  'Franja',
                                  _franjaSel,
                                  ['Todas', ..._franjas],
                                  (v) => setState(() => _franjaSel = v ?? 'Todas'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _aplicarFiltros,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Aplicar Filtros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tabla de últimas predicciones
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.analytics, color: AppTheme.primary, size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Desglose de Últimas Predicciones del Modelo',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: AppTheme.border, height: 1),

                          if (_ultimasFiltradas.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('Sin predicciones', style: TextStyle(color: AppTheme.textMuted))),
                            )
                          else
                            // Tabla con encabezado y datos
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppTheme.surfaceVariant),
                                dataRowMinHeight: 48,
                                dataRowMaxHeight: 56,
                                columnSpacing: 16,
                                horizontalMargin: 16,
                                headingTextStyle: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                                columns: const [
                                  DataColumn(label: Text('#')),
                                  DataColumn(label: Text('SECTOR')),
                                  DataColumn(label: Text('DELITO')),
                                  DataColumn(label: Text('FRANJA')),
                                  DataColumn(label: Text('CONFIANZA')),
                                  DataColumn(label: Text('RIESGO')),
                                ],
                                rows: _ultimasFiltradas.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final p = entry.value;
                                  final prob = p.probabilidad;
                                  final color = prob > 0.66 ? AppTheme.riskHigh : (prob >= 0.33 ? AppTheme.riskMed : AppTheme.riskLow);
                                  final riesgo = prob > 0.66 ? 'ALTO' : (prob >= 0.33 ? 'MEDIO' : 'BAJO');

                                  return DataRow(cells: [
                                    DataCell(Text('${idx + 1}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))),
                                    DataCell(Text('Sector ${p.sector}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (p.tipoDelito == 'ROBO' ? AppTheme.riskHigh : AppTheme.primary).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: (p.tipoDelito == 'ROBO' ? AppTheme.riskHigh : AppTheme.primary).withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          p.tipoDelito,
                                          style: TextStyle(
                                            color: p.tipoDelito == 'ROBO' ? AppTheme.riskHigh : AppTheme.primary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(p.franjaHoraria, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('${(prob * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          const SizedBox(width: 6),
                                          SizedBox(
                                            width: 40,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value: prob,
                                                backgroundColor: AppTheme.background,
                                                valueColor: AlwaysStoppedAnimation(color),
                                                minHeight: 4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          riesgo,
                                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, {String Function(String)? displayFn}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted, size: 18),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: options.map((o) => DropdownMenuItem(
                value: o,
                child: Text(displayFn != null ? displayFn(o) : o, style: const TextStyle(fontSize: 12)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
