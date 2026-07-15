import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/presentation/home/controllers/home_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_button.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_card.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/section_label.dart';
import 'package:get/get.dart';

/// Left pane: the large paste area plus Analyze/Clear actions.
class JobInputPanel extends StatelessWidget {
  const JobInputPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('Job Description', icon: Icons.content_paste_rounded),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'Paste a job post copied from WhatsApp, LinkedIn, or email.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Expanded(
            child: TextField(
              controller: controller.pasteController,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Paste the full job description here…',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Obx(() {
            final bool isLoading = controller.state.value == ViewState.loading;
            return Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: 'Analyze with AI',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: isLoading,
                    onPressed: controller.analyze,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                AppButton(
                  label: 'Clear',
                  icon: Icons.clear_rounded,
                  variant: AppButtonVariant.outlined,
                  onPressed: isLoading ? null : controller.clear,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
