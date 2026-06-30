import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/alertas_service.dart';
import '../../models/alerta.dart';
import '../../theme/app_theme.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final AlertasService _service = AlertasService();
  List<Alerta> _alertas = [];
  bool _isLoading = true;
  String _filtroSector = 'Todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAlertasActivas();
      if (mounted) {
        setState(() {
          _alertas = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _atender(int alertaId) async {
    try {
      final success = await _service.desactivarAlerta(alertaId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta marcada como atendida')),
        );
        _load();
      }
    } catch (e) {
      // Ignorar error por ahora
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertasFiltradas = _filtroSector == 'Todos'
        ? _alertas
        : _alertas.where((a) => a.sector == _filtroSector || 'Sector ${a.sector}' == _filtroSector).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Alertas Activas'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Filtros rápidos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todos',
                        isSelected: _filtroSector == 'Todos',
                        onTap: () => setState(() => _filtroSector = 'Todos'),
                      ),
                      ...List.generate(9, (i) => i + 1).map((sectorNum) {
                        final sectorName = 'Sector $sectorNum';
                        final hasAlerts = _alertas.any((a) => a.sector == sectorName || a.sector == sectorNum.toString());
                        if (!hasAlerts && _filtroSector != sectorName) return const SizedBox.shrink();
                        
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: 'Sector $sectorNum',
                            isSelected: _filtroSector == sectorName,
                            onTap: () => setState(() => _filtroSector = sectorName),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                // Lista de alertas
                Expanded(
                  child: alertasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: AppTheme.riskLow.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              const Text('No hay alertas activas', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.surface,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: alertasFiltradas.length,
                            itemBuilder: (context, index) {
                              final alerta = alertasFiltradas[index];
                              final isAltoRiesgo = alerta.probabilidad > 0.66;
                              final borderColor = isAltoRiesgo ? AppTheme.riskHigh : AppTheme.riskMed;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: borderColor.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: borderColor.withValues(alpha: 0.1),
                                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.warning_rounded, color: borderColor, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                'SECTOR ${alerta.sector}',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: borderColor,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isAltoRiesgo ? 'ALTO RIESGO' : 'RIESGO MEDIO',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _DetailItem(icon: Icons.access_time, title: 'Franja', value: alerta.franjaHoraria),
                                              ),
                                              Expanded(
                                                child: _DetailItem(icon: Icons.local_police_outlined, title: 'Delito Estimado', value: alerta.tipoDelito),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _DetailItem(icon: Icons.percent, title: 'Probabilidad', value: '${(alerta.probabilidad * 100).toStringAsFixed(1)}%'),
                                              ),
                                              Expanded(
                                                child: _DetailItem(
                                                  icon: Icons.calendar_today,
                                                  title: 'Generada',
                                                  value: DateFormat('dd/MM/yy HH:mm').format(alerta.creadoEn.toLocal()),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: OutlinedButton.icon(
                                              onPressed: () => _atender(alerta.id),
                                              icon: const Icon(Icons.check_circle_outline, size: 20),
                                              label: const Text('Marcar como atendida'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: const BorderSide(color: AppTheme.border, width: 1.5),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
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

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
