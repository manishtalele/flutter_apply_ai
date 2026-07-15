import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/theme/app_colors.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/presentation/home/controllers/home_controller.dart';
import 'package:flutter_apply_ai/presentation/home/widgets/match_score_gauge.dart';
import 'package:flutter_apply_ai/presentation/home/widgets/preview_field.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_button.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_card.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_empty_state.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/section_label.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

/// Right pane: renders the AI analysis result (or empty/loading/error states)
/// and the Apply/Copy actions.
class JobPreviewPanel extends StatelessWidget {
  const JobPreviewPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Obx(() {
        final ViewState viewState = controller.state.value;
        return AnimatedSwitcher(
          duration: AppDimensions.animNormal,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey<ViewState>(viewState),
            child: _buildContent(viewState),
          ),
        );
      }),
    );
  }

  Widget _buildContent(ViewState viewState) {
    switch (viewState) {
      case ViewState.initial:
        return const AppEmptyState(
          icon: Icons.description_outlined,
          title: 'No analysis yet',
          message: 'Paste a job description and tap "Analyze with AI" to '
              'extract details and generate an application email.',
        );
      case ViewState.loading:
        return const _LoadingState();
      case ViewState.error:
        return AppEmptyState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          title: 'Analysis failed',
          message: controller.errorMessage.value,
          actionLabel: 'Try again',
          onAction: controller.analyze,
        );
      case ViewState.success:
        final JobPosting? posting = controller.posting.value;
        if (posting == null) {
          return const SizedBox.shrink();
        }
        return _ResultContent(controller: controller, posting: posting);
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text('Analyzing job description…', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.controller, required this.posting});

  final HomeController controller;
  final JobPosting posting;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            MatchScoreGauge(score: posting.matchScore),
            const SizedBox(width: AppDimensions.spaceLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    posting.role.isEmpty ? 'Role not detected' : posting.role,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    posting.company.isEmpty ? '—' : posting.company,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  _RecommendationChip(shouldApply: posting.shouldApply),
                ],
              ),
            ),
          ],
        ),
        if (posting.matchSummary.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppDimensions.spaceMd),
          Text(posting.matchSummary, style: theme.textTheme.bodySmall),
        ],
        const Divider(height: AppDimensions.spaceXl),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PreviewField(
                  icon: Icons.mail_outline_rounded,
                  label: 'Recipient Email',
                  value: posting.email,
                  emptyPlaceholder: 'No email found in the post',
                ),
                PreviewField(
                  icon: Icons.place_outlined,
                  label: 'Location',
                  value: posting.location,
                ),
                PreviewField(
                  icon: Icons.work_outline_rounded,
                  label: 'Experience',
                  value: posting.experience,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                const SectionLabel('Required Skills', icon: Icons.bolt_rounded),
                const SizedBox(height: AppDimensions.spaceXs),
                _SkillChips(skills: posting.skills),
                const SizedBox(height: AppDimensions.spaceMd),
                const SectionLabel('Email Subject', icon: Icons.subject_rounded),
                const SizedBox(height: AppDimensions.spaceXs),
                SelectableText(
                  posting.subject.isEmpty ? '—' : posting.subject,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                const SectionLabel('Generated Email', icon: Icons.drafts_outlined),
                const SizedBox(height: AppDimensions.spaceXs),
                _EmailBodyBox(html: posting.emailBody),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        _ApplyActions(controller: controller),
      ],
    );
  }
}

class _ApplyActions extends StatelessWidget {
  const _ApplyActions({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Obx(() {
      final List<ResumeProfile> resumes = controller.resumes;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (resumes.isEmpty)
            Text(
              'No resume selected. Add one in Settings to apply.',
              style: theme.textTheme.bodySmall,
            )
          else
            Row(
              children: <Widget>[
                Icon(
                  Icons.attach_file_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppDimensions.spaceXs),
                Expanded(
                  child: DropdownButton<ResumeProfile>(
                    isExpanded: true,
                    value: controller.selectedResume.value,
                    underline: const SizedBox.shrink(),
                    items: resumes
                        .map(
                          (ResumeProfile r) => DropdownMenuItem<ResumeProfile>(
                            value: r,
                            child: Text(
                              r.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: controller.selectResume,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppDimensions.spaceSm),
          _AttachmentsRow(controller: controller),
          const SizedBox(height: AppDimensions.spaceSm),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: 'Apply',
                  icon: Icons.send_rounded,
                  isLoading: controller.applying.value,
                  onPressed: controller.canApply ? controller.apply : null,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              AppButton(
                label: 'Copy',
                icon: Icons.copy_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: controller.copyEmail,
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              AppButton(
                label: 'Clear',
                icon: Icons.clear_rounded,
                variant: AppButtonVariant.text,
                onPressed: controller.clear,
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _RecommendationChip extends StatelessWidget {
  const _RecommendationChip({required this.shouldApply});

  final bool shouldApply;

  @override
  Widget build(BuildContext context) {
    final Color color = shouldApply ? AppColors.success : AppColors.warning;
    final IconData icon =
        shouldApply ? Icons.check_circle_rounded : Icons.info_rounded;
    final String label = shouldApply ? 'Recommended to apply' : 'Review before applying';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SkillChips extends StatelessWidget {
  const _SkillChips({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Text(
        'No specific skills detected.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Wrap(
      spacing: AppDimensions.spaceXs,
      runSpacing: AppDimensions.spaceXs,
      children: skills
          .map((String skill) => Chip(label: Text(skill)))
          .toList(growable: false),
    );
  }
}

class _AttachmentsRow extends StatelessWidget {
  const _AttachmentsRow({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Obx(
      () => Wrap(
        spacing: AppDimensions.spaceXs,
        runSpacing: AppDimensions.spaceXs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text('Attachments:', style: theme.textTheme.labelMedium),
          ...controller.extraAttachments.map(
            (String path) => InputChip(
              avatar: const Icon(Icons.attach_file_rounded, size: 16),
              label: Text(p.basename(path)),
              onDeleted: () => controller.removeAttachment(path),
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add file'),
            onPressed: () => unawaited(controller.addAttachments()),
          ),
        ],
      ),
    );
  }
}

class _EmailBodyBox extends StatelessWidget {
  const _EmailBodyBox({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: SelectableText(
        html.isEmpty ? '—' : html,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
