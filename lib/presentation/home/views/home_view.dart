import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/presentation/home/controllers/home_controller.dart';
import 'package:flutter_apply_ai/presentation/home/widgets/job_input_panel.dart';
import 'package:flutter_apply_ai/presentation/home/widgets/job_preview_panel.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/onboarding_banner.dart';
import 'package:get/get.dart';

/// Home screen: side-by-side compose (left) and preview (right) on wide
/// desktop widths, stacked on narrow widths.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const double _stackBreakpoint = 980;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        children: <Widget>[
          Obx(() {
            if (!controller.needsSetup) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
              child: OnboardingBanner(
                missingItems: controller.missingSetupItems,
                onOpenSettings: controller.openSettings,
              ),
            );
          }),
          Expanded(child: _buildPanels(context)),
        ],
      ),
    );
  }

  Widget _buildPanels(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final JobInputPanel input = JobInputPanel(controller: controller);
        final JobPreviewPanel preview = JobPreviewPanel(controller: controller);

        if (constraints.maxWidth < _stackBreakpoint) {
          return Column(
            children: <Widget>[
              SizedBox(height: constraints.maxHeight * 0.45, child: input),
              const SizedBox(height: AppDimensions.spaceMd),
              Expanded(child: preview),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: input),
            const SizedBox(width: AppDimensions.spaceLg),
            Expanded(child: preview),
          ],
        );
      },
    );
  }
}
