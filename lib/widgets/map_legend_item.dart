import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String? description;

  const MapLegendItem({
    super.key,
    required this.color,
    required this.label,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: color,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 1),
                Text(
                  description!,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
