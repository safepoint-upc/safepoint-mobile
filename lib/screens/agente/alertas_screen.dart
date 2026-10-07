import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/alertas_service.dart';
import '../../models/alerta.dart';
import '../../theme/app_theme.dart';
import '../../widgets/risk_badge.dart';

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
    final success = await _service.desactivarAlerta(alertaId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta marcada como atendida')),
      );
      _load();
    }
  }

  // Obtiene los sectores únicos de las alertas actuales para los filtros
  List<String> get _sectoresDisponibles {
    final sectores = _alertas.map((a) => a.sector).toSet().toList();
    sectores.sort();
    return sectores;
  }

  @override
  Widget build(BuildContext context) {
    // Filtra las alertas según el sector seleccionado
    final alertasFiltradas = _filtroSector == 'Todos'
        ? _alertas
        : _alertas.where((a) => a.sector == _filtroSector).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Alertas Activas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
        children: [
          // Filtros rápidos por sector — solo muestra los sectores con alertas
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
                ..._sectoresDisponibles.map((sector) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: 'Sector $sector',
                    isSelected: _filtroSector == sector,
                    onTap: () => setState(() => _filtroSector = sector),
                  ),
                )),
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
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.riskLow.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay alertas activas',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                  ),
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
                  final color = isAltoRiesgo ? AppTheme.riskHigh : AppTheme.riskMed;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Cabecera de la alerta con sector y nivel de riesgo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_rounded, color: color, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SECTOR ${alerta.sector} — ${alerta.cuadrante ?? ""}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              RiskBadge(nivelRiesgo: isAltoRiesgo ? 2 : 1),
                            ],
                          ),
                        ),

                        // Detalles de la alerta
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _DetailItem(
                                      icon: Icons.access_time,
                                      title: 'Franja horaria',
                                      value: alerta.franjaHoraria,
                                    ),
                                  ),
                                  Expanded(
                                    child: _DetailItem(
                                      icon: Icons.percent,
                                      title: 'Probabilidad',
                                      value: '${(alerta.probabilidad * 100).toStringAsFixed(1)}%',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _DetailItem(
                                icon: Icons.calendar_today,
                                title: 'Generada',
                                value: DateFormat('dd/MM/yyyy HH:mm').format(
                                  alerta.creadoEn.toLocal(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Botón para marcar la alerta como atendida
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () => _atender(alerta.id),
                                  icon: const Icon(Icons.check_circle_outline, size: 20),
                                  label: const Text('Marcar como atendida'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppTheme.border,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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

// ── Chip de filtro por sector ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
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

// ── Item de detalle reutilizable ───────────────────────────────────────────
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}