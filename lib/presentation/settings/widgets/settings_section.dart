import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_card.dart';

/// A titled settings group rendered inside an [AppCard].
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: AppDimensions.spaceXxs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppDimensions.spaceMd),
          child,
        ],
      ),
    );
  }
}
