import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/presentation/settings/controllers/settings_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_button.dart';
import 'package:path/path.dart' as p;

/// Dialog to name and pick a resume file, then add it via
/// [SettingsController.addResume]. Local form state is intentionally held here
/// (ephemeral UI state), while persistence goes through the controller.
class AddResumeDialog extends StatefulWidget {
  const AddResumeDialog({required this.controller, super.key});

  final SettingsController controller;

  @override
  State<AddResumeDialog> createState() => _AddResumeDialogState();
}

class _AddResumeDialogState extends State<AddResumeDialog> {
  final TextEditingController _labelController = TextEditingController();
  String? _filePath;
  bool _makeDefault = false;
  bool _submitting = false;

  bool get _canSubmit =>
      _labelController.text.trim().isNotEmpty &&
      _filePath != null &&
      !_submitting;

  Future<void> _pickFile() async {
    final String? path = await widget.controller.pickResumeFile();
    if (!mounted || path == null) {
      return;
    }
    setState(() {
      _filePath = path;
      if (_labelController.text.trim().isEmpty) {
        _labelController.text = p.basenameWithoutExtension(path);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await widget.controller.addResume(
      label: _labelController.text,
      filePath: _filePath ?? '',
      makeDefault: _makeDefault,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String fileName =
        _filePath == null ? 'No file selected' : p.basename(_filePath!);

    return AlertDialog(
      title: const Text('Add resume'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _labelController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Flutter Resume',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    fileName,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                AppButton(
                  label: 'Choose file',
                  icon: Icons.upload_file_rounded,
                  variant: AppButtonVariant.outlined,
                  onPressed: _pickFile,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            CheckboxListTile(
              value: _makeDefault,
              onChanged: (bool? value) =>
                  setState(() => _makeDefault = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Set as default resume'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Add',
          isLoading: _submitting,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
