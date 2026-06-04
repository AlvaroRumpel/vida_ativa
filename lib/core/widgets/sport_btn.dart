import 'package:flutter/material.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

/// Primary action button for the Arena booking flow.
///
/// Two named constructors:
///   - [SportBtn.filled] — orange background, paper text (primary CTA)
///   - [SportBtn.outlined] — transparent background, ink border + text (secondary CTA)
///
/// Both variants use Anton 15px (via AppTheme.display), StadiumBorder,
/// minimumSize(double.infinity, 52) and TextOverflow.ellipsis.
class SportBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool _filled;

  const SportBtn.filled(
    this.label, {
    super.key,
    required this.onPressed,
  }) : _filled = true;

  const SportBtn.outlined(
    this.label, {
    super.key,
    required this.onPressed,
  }) : _filled = false;

  @override
  Widget build(BuildContext context) {
    if (_filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.orange,
          foregroundColor: AppTheme.paper,
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTheme.display(size: 15, color: AppTheme.paper),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: Text(label, overflow: TextOverflow.ellipsis),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.ink,
        side: const BorderSide(color: AppTheme.ink, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        textStyle: AppTheme.display(size: 15, color: AppTheme.ink),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
