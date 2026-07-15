import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/constants/oauth_config.dart';
import 'package:flutter_apply_ai/core/theme/app_colors.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/presentation/settings/controllers/settings_controller.dart';
import 'package:flutter_apply_ai/presentation/settings/widgets/add_resume_dialog.dart';
import 'package:flutter_apply_ai/presentation/settings/widgets/settings_section.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_button.dart';
import 'package:get/get.dart';

/// Settings screen: AI key, resumes, Gmail, appearance.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Settings', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppDimensions.spaceLg),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: ListView(
                  children: <Widget>[
                    _OpenAiSection(controller: controller),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _SenderSection(controller: controller),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _ResumesSection(controller: controller),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _GmailSection(controller: controller),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _AppearanceSection(controller: controller),
                    const SizedBox(height: AppDimensions.spaceLg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenAiSection extends StatelessWidget {
  const _OpenAiSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'OpenAI API Key',
      icon: Icons.key_rounded,
      subtitle: 'Used to analyze job posts and generate emails. Stored securely.',
      child: Column(
        children: <Widget>[
          Obx(
            () => TextField(
              controller: controller.apiKeyController,
              obscureText: controller.obscureApiKey.value,
              decoration: InputDecoration(
                hintText: 'Paste your OpenAI API key',
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureApiKey.value
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: controller.toggleApiKeyVisibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: <Widget>[
              Obx(
                () => Expanded(
                  child: _StatusText(
                    ok: controller.settings.value.hasGeminiKey,
                    okText: 'API key configured',
                    notText: 'No API key set',
                  ),
                ),
              ),
              Obx(
                () => AppButton(
                  label: 'Save key',
                  icon: Icons.save_rounded,
                  isLoading: controller.savingApiKey.value,
                  onPressed: controller.saveApiKey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SenderSection extends StatelessWidget {
  const _SenderSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Your Profile',
      icon: Icons.badge_outlined,
      subtitle: 'Your name (used as the email "From") and a short summary of '
          'your skills/experience — the AI uses this to compute match scores.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: controller.senderNameController,
            decoration: const InputDecoration(
              labelText: 'Sender name',
              hintText: 'e.g. Jane Doe',
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          TextField(
            controller: controller.profileController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Profile summary',
              hintText: 'e.g. 4 years Flutter, Dart, GetX, REST APIs; '
                  'based in Bengaluru; open to remote.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Save profile',
              icon: Icons.save_rounded,
              variant: AppButtonVariant.outlined,
              onPressed: controller.saveProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumesSection extends StatelessWidget {
  const _ResumesSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Resumes',
      icon: Icons.description_outlined,
      subtitle: 'Manage multiple resumes and choose a default to attach.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Obx(() {
            final List<ResumeProfile> resumes = controller.resumes;
            if (resumes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spaceMd,
                ),
                child: Text(
                  'No resumes yet. Add one to attach it to applications.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return Column(
              children: resumes
                  .map(
                    (ResumeProfile resume) => _ResumeTile(
                      resume: resume,
                      controller: controller,
                    ),
                  )
                  .toList(growable: false),
            );
          }),
          const SizedBox(height: AppDimensions.spaceSm),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Add resume',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outlined,
              onPressed: () => _openAddDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => AddResumeDialog(controller: controller),
      ),
    );
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({required this.resume, required this.controller});

  final ResumeProfile resume;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Row(
        children: <Widget>[
          Flexible(child: Text(resume.label, overflow: TextOverflow.ellipsis)),
          if (resume.isDefault) ...<Widget>[
            const SizedBox(width: AppDimensions.spaceXs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Text(
                'Default',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(resume.fileName, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!resume.isDefault)
            IconButton(
              tooltip: 'Set as default',
              icon: const Icon(Icons.star_outline_rounded),
              onPressed: () =>
                  unawaited(controller.setDefaultResume(resume.id)),
            ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => unawaited(controller.deleteResume(resume.id)),
          ),
        ],
      ),
    );
  }
}

class _GmailSection extends StatelessWidget {
  const _GmailSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Gmail',
      icon: Icons.mail_outline_rounded,
      subtitle: 'Connect your Gmail to send applications and track replies.',
      child: Obx(() {
        final bool connected = controller.isGmailConnected;
        if (!OAuthConfig.isConfigured) {
          return const _StatusText(
            ok: false,
            okText: '',
            notText: 'OAuth client not configured (set GOOGLE_OAUTH_CLIENT_ID).',
          );
        }
        return Row(
          children: <Widget>[
            Expanded(
              child: _StatusText(
                ok: connected,
                okText: 'Connected as ${controller.gmailAccount}',
                notText: 'Not connected',
              ),
            ),
            if (connected)
              AppButton(
                label: 'Disconnect',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: controller.disconnectGmail,
              )
            else
              AppButton(
                label: 'Connect Gmail',
                icon: Icons.login_rounded,
                isLoading: controller.connectingGmail.value,
                onPressed: controller.connectGmail,
              ),
          ],
        );
      }),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      child: Obx(
        () => SegmentedButton<AppThemeMode>(
          segments: const <ButtonSegment<AppThemeMode>>[
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_rounded),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_rounded),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto_rounded),
            ),
          ],
          selected: <AppThemeMode>{controller.themeMode},
          onSelectionChanged: (Set<AppThemeMode> selection) =>
              unawaited(controller.setThemeMode(selection.first)),
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({
    required this.ok,
    required this.okText,
    required this.notText,
  });

  final bool ok;
  final String okText;
  final String notText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = ok ? AppColors.success : theme.colorScheme.onSurfaceVariant;
    return Row(
      children: <Widget>[
        Icon(
          ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppDimensions.spaceXs),
        Flexible(
          child: Text(
            ok ? okText : notText,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
