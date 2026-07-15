/// Application-wide, non-UI configuration constants.
///
/// User-facing copy lives in `AppStrings`; database identifiers in
/// `DbConstants`; API endpoints in `ApiConstants`. This class only holds
/// application metadata and runtime tuning values.
abstract final class AppConstants {
  const AppConstants._();

  // ── Application metadata ────────────────────────────────────────────
  static const String appName = 'Flutter Apply AI';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Automate your job applications with AI';

  // ── Desktop window (window_manager) ─────────────────────────────────
  static const double initialWindowWidth = 1280;
  static const double initialWindowHeight = 820;
  static const double minWindowWidth = 1100;
  static const double minWindowHeight = 720;

  // ── Network timeouts (Dio) ──────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  // ── Presentation timing ─────────────────────────────────────────────
  static const Duration splashMinDuration = Duration(milliseconds: 1200);
  static const Duration routeTransitionDuration = Duration(milliseconds: 250);
}
