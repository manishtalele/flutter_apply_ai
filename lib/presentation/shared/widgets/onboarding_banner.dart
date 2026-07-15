import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_colors.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';

/// A dismissible-style guidance banner shown when required setup is missing
/// (API key, Gmail connection, or a resume), with a shortcut to Settings.
class OnboardingBanner extends StatelessWidget {
  const OnboardingBanner({
    required this.missingItems,
    required this.onOpenSettings,
    super.key,
  });

  final List<String> missingItems;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Finish setup to start applying',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Still needed: ${missingItems.join(', ')}.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          FilledButton.tonalIcon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
