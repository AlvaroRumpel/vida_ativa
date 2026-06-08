import 'package:flutter/material.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

enum _SportBtnVariant { filled, outlined, filledInk }

/// Primary action button for the Arena booking flow.
///
/// Three named constructors:
///   - [SportBtn.filled]    — orange background, paper text (primary CTA)
///   - [SportBtn.outlined]  — transparent background, ink border + text (secondary CTA)
///   - [SportBtn.filledInk] — ink background, paper text (primary footer CTA, e.g. PricingTab save)
///
/// All variants use Anton 15px (via AppTheme.display), StadiumBorder,
/// minimumSize(double.infinity, 52) and TextOverflow.ellipsis.
class SportBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final _SportBtnVariant _variant;

  const SportBtn.filled(
    this.label, {
    super.key,
    required this.onPressed,
  }) : _variant = _SportBtnVariant.filled;

  const SportBtn.outlined(
    this.label, {
    super.key,
    required this.onPressed,
  }) : _variant = _SportBtnVariant.outlined;

  const SportBtn.filledInk(
    this.label, {
    super.key,
    required this.onPressed,
  }) : _variant = _SportBtnVariant.filledInk;

  @override
  Widget build(BuildContext context) {
    return switch (_variant) {
      _SportBtnVariant.filled => FilledButton(
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
        ),
      _SportBtnVariant.outlined => OutlinedButton(
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
        ),
      _SportBtnVariant.filledInk => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.ink,
            foregroundColor: AppTheme.paper,
            minimumSize: const Size(double.infinity, 52),
            textStyle: AppTheme.display(size: 15, color: AppTheme.paper),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
    };
  }
}
