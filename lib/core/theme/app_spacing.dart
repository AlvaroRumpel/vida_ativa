/// Spacing tokens for consistent padding and margin values.
///
/// Usage: `EdgeInsets.all(AppSpacing.md)` or `SizedBox(height: AppSpacing.sm)`
class AppSpacing {
  AppSpacing._(); // Private constructor — use static members only

  /// 4.0 — Icon gaps, badge internal padding, color strip width
  static const double xs = 4.0;

  /// 8.0 — Compact list item vertical padding, inline element gaps
  static const double sm = 8.0;

  /// 16.0 — Default horizontal padding on list screens, form field spacing
  static const double md = 16.0;

  /// 24.0 — Section padding, form horizontal padding, empty-state text padding
  static const double lg = 24.0;

  /// 32.0 — Layout gaps between major sections
  static const double xl = 32.0;
}
