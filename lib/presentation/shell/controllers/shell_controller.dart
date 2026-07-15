import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A top-level navigation destination in the app shell.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Drives the persistent NavigationRail: which top-level section is active.
class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;

  static const List<ShellDestination> destinations = <ShellDestination>[
    ShellDestination(
      label: 'Home',
      icon: Icons.add_circle_outline_rounded,
      selectedIcon: Icons.add_circle_rounded,
    ),
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    ShellDestination(
      label: 'History',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_toggle_off_rounded,
    ),
    ShellDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  void changeTo(int index) {
    if (index < 0 || index >= destinations.length) {
      return;
    }
    currentIndex.value = index;
  }
}
