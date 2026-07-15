/// Centralized, user-facing string catalog.
///
/// No screen, controller, or widget may hardcode display text — every visible
/// label references a member of this class. Grows module-by-module as screens
/// are added. Kept as plain constants (not `.arb`) because this desktop tool
/// ships single-locale; the single-source-of-truth rule is what matters.
abstract final class AppStrings {
  const AppStrings._();

  // ── Splash / bootstrap ──────────────────────────────────────────────
  static const String initializing = 'Initializing…';
}
