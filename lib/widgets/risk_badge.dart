import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final int nivelRiesgo;

  const RiskBadge({
    super.key,
    required this.nivelRiesgo,
  });

  String get _text {
    switch (nivelRiesgo) {
      case 0:
        return 'BAJO';
      case 1:
        return 'MEDIO';
      case 2:
        return 'ALTO';
      default:
        return 'DESCONOCIDO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final color = AppTheme.riskColor(text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
