import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../services/incidentes_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bar_chart_card.dart';

/// Pantalla de Estadísticas de Seguridad para el Ciudadano.
/// Diseñada para entender cuándo, dónde y de qué cuidarse en Jesús María.
class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final IncidentesService _service = IncidentesService();

  bool _isLoading = true;
  int _totalIncidentes = 0;

  List<Map<String, dynamic>> _porFranjaList = [];
  List<Map<String, dynamic>> _porTipoList = [];
  List<Map<String, dynamic>> _porSectorList = [];

  String _franjaMasPeligrosa = '—';
  String _delitoMasFrecuente = '—';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getEstadisticas(),
        _service.getIncidentesPorFranja(),
        _service.getIncidentesPorTipo(),
      ]);

      if (mounted) {
        final estadisticas = results[0] as Map<String, dynamic>;
        final porFranjaRaw = results[1] as List<Map<String, dynamic>>;
        final porTipoRaw = results[2] as List<Map<String, dynamic>>;

        // 1. Total de incidentes
        final total = (estadisticas['total_incidentes'] as num?)?.toInt() ?? 0;

        // 2. Procesar por franja (ordenar según AppConstants.franjasHorarias)
        final Map<String, int> mapFranjaTemp = {};
        for (final f in porFranjaRaw) {
          final franjaFull = f['franja_horaria']?.toString() ?? '';
          final totalF = (f['cantidad'] ?? f['total'] as num?)?.toInt() ?? 0;
          mapFranjaTemp[franjaFull] = totalF;
        }

        final List<Map<String, dynamic>> franjaOrdenada = [];
        String topFranjaName = '—';
        int topFranjaMax = -1;

        for (final franjaFull in AppConstants.franjasHorarias) {
          final count = mapFranjaTemp[franjaFull] ?? 0;
          final labelCorta = AppConstants.franjaCorta(franjaFull);
          if (count > topFranjaMax) {
            topFranjaMax = count;
            topFranjaName = labelCorta;
          }
          franjaOrdenada.add({
            'franjaFull': franjaFull,
            'labelCorta': labelCorta,
            'total': count,
          });
        }

        // 3. Procesar por tipo de delito — el endpoint retorna {tipo_delito, cantidad}
        final List<Map<String, dynamic>> tipoOrdenado = List.from(porTipoRaw)
          ..sort((a, b) => ((b['cantidad'] as num?)?.toInt() ?? 0)
              .compareTo((a['cantidad'] as num?)?.toInt() ?? 0));

        String topTipoName = '—';
        if (tipoOrdenado.isNotEmpty) {
          topTipoName = tipoOrdenado.first['tipo_delito']?.toString() ?? 'HURTO';
        }

        // 4. Procesar por sector — estadisticas retorna {por_sector: [{sector, cantidad}]}
        final listSectorRaw = (estadisticas['por_sector'] as List<dynamic>? ?? []);
        final List<Map<String, dynamic>> sectorOrdenado = listSectorRaw.map((e) {
          return {
            'sector': e['sector']?.toString() ?? '',
            'total': (e['cantidad'] as num?)?.toInt() ?? 0,
          };
        }).toList()
          ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

        setState(() {
          _totalIncidentes = total;
          _porFranjaList = franjaOrdenada;
          _porTipoList = tipoOrdenado;
          _porSectorList = sectorOrdenado;
          _franjaMasPeligrosa = topFranjaName;
          _delitoMasFrecuente = topTipoName.toUpperCase();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR _loadData estadísticas ciudadano: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Prepara datos para BarChartCard en la sección de franjas horarias
  Map<String, int> get _chartFranjaData {
    final Map<String, int> map = {};
    for (final item in _porFranjaList) {
      map[item['labelCorta'] as String] = item['total'] as int;
    }
    return map;
  }

  IconData _getIconForTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('hurto')) return Icons.account_balance_wallet_outlined;
    if (t.contains('robo')) return Icons.warning_amber_rounded;
    if (t.contains('estafa')) return Icons.credit_card_off_rounded;
    return Icons.gavel_rounded;
  }

  String _formatNumber(int number) {
    final str = number.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Seguridad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Jesús María, Lima · 2023-2026',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Actualizar datos',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección 1 — Hero Card de Resumen
                    _buildHeroCard(),
                    const SizedBox(height: 24),

                    // Sección 2 — ¿Cuándo ocurren más delitos?
                    _buildSeccionFranjas(),
                    const SizedBox(height: 24),

                    // Sección 3 — ¿De qué cuidarte?
                    _buildSeccionTiposDelito(),
                    const SizedBox(height: 24),

                    // Sección 4 — ¿Dónde tener más cuidado?
                    _buildSeccionSectores(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Sección 1: Hero Card Resumen ──────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surface,
            AppTheme.surfaceVariant.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'REPORTE HISTÓRICO',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Text(
                'Enero 2023 — Marzo 2026',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatNumber(_totalIncidentes),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'incidentes registrados en Jesús María',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.riskHigh,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Mayor riesgo entre las '),
                        TextSpan(
                          text: _franjaMasPeligrosa,
                          style: const TextStyle(
                            color: AppTheme.riskHigh,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: '. El delito más frecuente es '),
                        TextSpan(
                          text: _delitoMasFrecuente,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
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

  // ── Sección 2: ¿Cuándo ocurren más delitos? ────────────────────────────────
  Widget _buildSeccionFranjas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.access_time_filled, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text(
              '¿Cuándo ocurren más delitos?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Padding(
          padding: EdgeInsets.only(left: 26),
          child: Text(
            'Franjas horarias con más incidentes históricos',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
        BarChartCard(
          titulo: '',
          data: _chartFranjaData,
          color: AppTheme.riskHigh,
        ),
      ],
    );
  }

  // ── Sección 3: ¿De qué cuidarte? ──────────────────────────────────────────
  Widget _buildSeccionTiposDelito() {
    final maxTotal = _porTipoList.isNotEmpty
        ? ((_porTipoList.first['cantidad'] as num?)?.toInt() ?? 1)
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.security, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text(
              '¿De qué cuidarte?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Padding(
          padding: EdgeInsets.only(left: 26),
          child: Text(
            'Tipos de delito más frecuentes',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: _porTipoList.map((item) {
              final nombre = item['tipo_delito']?.toString() ?? 'Otro';
              final count = (item['cantidad'] as num?)?.toInt() ?? 0;
              final pct = _totalIncidentes > 0 ? (count / _totalIncidentes * 100).toStringAsFixed(1) : '0.0';
              final ratio = maxTotal > 0 ? count / maxTotal : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIconForTipo(nombre),
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _capitalize(nombre),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$count ($pct%)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Sección 4: ¿Dónde tener más cuidado? ──────────────────────────────────
  Widget _buildSeccionSectores() {
    final maxTotal = _porSectorList.isNotEmpty
        ? (_porSectorList.first['total'] as int)
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text(
              '¿Dónde tener más cuidado?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Padding(
          padding: EdgeInsets.only(left: 26),
          child: Text(
            'Sectores con más incidentes registrados',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: _porSectorList.map((item) {
              final secId = item['sector']?.toString() ?? '';
              final nombreSector = AppConstants.nombresSectores[secId] ?? 'Sector $secId';
              final count = item['total'] as int;
              final ratio = maxTotal > 0 ? count / maxTotal : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Sector $secId — $nombreSector',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$count incidentes',
                          style: const TextStyle(
                            color: AppTheme.riskMed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.riskMed),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Skeleton Loader ────────────────────────────────────────────────────────
  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}