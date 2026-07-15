import 'package:flutter_apply_ai/presentation/dashboard/bindings/dashboard_binding.dart';
import 'package:flutter_apply_ai/presentation/history/bindings/history_binding.dart';
import 'package:flutter_apply_ai/presentation/home/bindings/home_binding.dart';
import 'package:flutter_apply_ai/presentation/settings/bindings/settings_binding.dart';
import 'package:flutter_apply_ai/presentation/shell/controllers/shell_controller.dart';
import 'package:get/get.dart';

/// Registers the [ShellController] and the controllers for each embedded
/// section. Home is wired now; Dashboard/History/Settings bindings are added
/// here as those modules land.
class ShellBinding extends Bindings {
  ShellBinding();

  @override
  void dependencies() {
    Get.put<ShellController>(ShellController());
    HomeBinding().dependencies();
    DashboardBinding().dependencies();
    HistoryBinding().dependencies();
    SettingsBinding().dependencies();
  }
}
