import 'package:flutter/material.dart';

/// Canonical color palette. No widget may use a literal `Color(0x...)`; every
/// color references a member here so the palette is auditable and consistent
/// across light and dark themes.
abstract final class AppColors {
  const AppColors._();

  // ── Brand ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryVariant = Color(0xFF5847C4);
  static const Color secondary = Color(0xFF00C2A8);
  static const Color tertiary = Color(0xFFFF7675);

  // ── Dark theme neutrals ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkSurfaceVariant = Color(0xFF1F232C);
  static const Color darkOutline = Color(0xFF2C313C);
  static const Color darkOnSurface = Color(0xFFE6E9F0);
  static const Color darkOnSurfaceMuted = Color(0xFF9AA3B2);

  // ── Light theme neutrals ─────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDEFF5);
  static const Color lightOutline = Color(0xFFD9DDE7);
  static const Color lightOnSurface = Color(0xFF1A1D24);
  static const Color lightOnSurfaceMuted = Color(0xFF5B6270);

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF1C40F);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ── Application status (History / Dashboard chips) ───────────────────
  static const Color statusApplied = Color(0xFF3498DB);
  static const Color statusInterview = Color(0xFF9B59B6);
  static const Color statusSelected = Color(0xFF2ECC71);
  static const Color statusRejected = Color(0xFFE74C3C);
  static const Color statusNoReply = Color(0xFF7F8C8D);

  // ── Match-score gradient anchors (0 → 100) ───────────────────────────
  static const Color scoreLow = Color(0xFFE74C3C);
  static const Color scoreMid = Color(0xFFF1C40F);
  static const Color scoreHigh = Color(0xFF2ECC71);

  // ── Absolutes ────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}
