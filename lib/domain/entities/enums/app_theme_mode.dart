/// Domain representation of the user's theme preference.
///
/// The Domain layer must not depend on Flutter, so this is a pure enum rather
/// than Flutter's `ThemeMode`. The Presentation layer maps between the two.
enum AppThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  const AppThemeMode(this.value);

  final String value;

  static AppThemeMode fromValue(String value) {
    return AppThemeMode.values.firstWhere(
      (AppThemeMode mode) => mode.value == value,
      orElse: () => AppThemeMode.dark,
    );
  }
}
