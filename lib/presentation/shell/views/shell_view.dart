import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/constants/app_constants.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/presentation/dashboard/views/dashboard_view.dart';
import 'package:flutter_apply_ai/presentation/history/views/history_view.dart';
import 'package:flutter_apply_ai/presentation/home/views/home_view.dart';
import 'package:flutter_apply_ai/presentation/settings/views/settings_view.dart';
import 'package:flutter_apply_ai/presentation/shell/controllers/shell_controller.dart';
import 'package:get/get.dart';

/// Application shell hosting the persistent NavigationRail and the active
/// section. Sections are kept alive in an [IndexedStack] so state (e.g. a
/// pasted job) survives tab switches.
///
/// Home is live now; Dashboard/History/Settings are inserted by Modules
/// 19/13/12 (replacing the `_ComingSoon` placeholders below).
class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: <Widget>[
          Obx(
            () => NavigationRail(
              extended: true,
              minExtendedWidth: AppDimensions.navRailWidth,
              backgroundColor: theme.colorScheme.surface,
              selectedIndex: controller.currentIndex.value,
              onDestinationSelected: controller.changeTo,
              leading: const _RailHeader(),
              destinations: ShellController.destinations
                  .map(
                    (ShellDestination d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Obx(
              () => IndexedStack(
                index: controller.currentIndex.value,
                children: const <Widget>[
                  HomeView(),
                  DashboardView(),
                  HistoryView(),
                  SettingsView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceMd,
        AppDimensions.spaceLg,
        AppDimensions.spaceMd,
        AppDimensions.spaceLg,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppDimensions.spaceSm),
          SizedBox(
            width: AppDimensions.navRailWidth -
                (AppDimensions.spaceMd * 2) -
                24 -
                AppDimensions.spaceSm,
            child: Text(
              AppConstants.appName,
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

