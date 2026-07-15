import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_colors.dart';

/// Circular gauge visualizing a 0–100 match score, colored by band
/// (low/medium/high).
class MatchScoreGauge extends StatelessWidget {
  const MatchScoreGauge({required this.score, this.size = 92, super.key});

  final int score;
  final double size;

  Color get _bandColor {
    if (score < 40) {
      return AppColors.scoreLow;
    }
    if (score < 70) {
      return AppColors.scoreMid;
    }
    return AppColors.scoreHigh;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int clamped = score.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped / 100,
              strokeWidth: 7,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(_bandColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$clamped',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _bandColor,
                ),
              ),
              Text(
                'MATCH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
