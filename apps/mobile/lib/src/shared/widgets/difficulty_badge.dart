import 'package:carnometer_core/carnometer_core.dart';
import 'package:flutter/material.dart';

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({required this.difficulty, super.key});

  final RouteDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (difficulty) {
      RouteDifficulty.easy => (Colors.green, Icons.trending_flat),
      RouteDifficulty.medium => (Colors.amber.shade700, Icons.trending_up),
      RouteDifficulty.hard => (Colors.orange.shade800, Icons.terrain),
      RouteDifficulty.expert => (Colors.red.shade700, Icons.whatshot),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            difficulty.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
