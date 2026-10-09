import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BarChartCard extends StatelessWidget {
  final String titulo;
  final Map<String, int> data;
  final Color color;

  const BarChartCard({
    super.key,
    required this.titulo,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (titulo.isNotEmpty) ...[
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Center(
              child: Text(
                'Sin datos disponibles',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    final total = data.values.fold<int>(0, (sum, val) => sum + val);
    final maxVal = data.values.fold<int>(0, (max, val) => val > max ? val : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titulo.isNotEmpty) ...[
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Total de incidentes: $total',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            final value = entry.value;
            final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
            final ratio = maxVal > 0 ? value / maxVal : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 12,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$value ($percentage%)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
