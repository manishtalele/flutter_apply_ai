import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';

/// Small uppercase caption used to title a group of content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.icon, super.key});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.labelMedium?.copyWith(
      letterSpacing: 1.1,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppDimensions.spaceXs),
        ],
        Text(text.toUpperCase(), style: style),
      ],
    );
  }
}
