/// Named-route identifiers for the entire application.
///
/// Declared in full up-front so navigation calls elsewhere compile against a
/// stable contract. The corresponding [GetPage]s are registered in
/// `AppPages.pages` as each feature module lands (Splash now; Shell/Home/
/// Settings/History/Dashboard in their respective modules).
abstract final class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String shell = '/shell';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String dashboard = '/dashboard';
}
