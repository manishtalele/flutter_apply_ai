/// Spacing, radius, elevation, and component-sizing tokens.
///
/// Every gap, corner radius, and fixed size in the UI references a token here
/// so spacing stays on a consistent scale and can be tuned in one place.
abstract final class AppDimensions {
  const AppDimensions._();

  // ── Spacing scale (4pt base) ─────────────────────────────────────────
  static const double spaceXxs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // ── Corner radius ────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  // ── Elevation ────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationCard = 1;
  static const double elevationDialog = 3;

  // ── Borders ──────────────────────────────────────────────────────────
  static const double borderThin = 1;
  static const double borderThick = 1.5;

  // ── Component sizing ─────────────────────────────────────────────────
  static const double buttonHeight = 48;
  static const double inputMinHeight = 52;
  static const double navRailWidth = 240;
  static const double navRailCollapsedWidth = 84;
  static const double iconButtonSize = 40;
  static const double maxContentWidth = 1400;
  static const double cardPadding = 20;

  // ── Animation ────────────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
}
