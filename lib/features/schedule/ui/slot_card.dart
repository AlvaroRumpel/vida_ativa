import 'package:flutter/material.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class SlotCard extends StatelessWidget {
  final SlotViewModel viewModel;
  final VoidCallback? onTap;

  const SlotCard({super.key, required this.viewModel, this.onTap});

  @override
  Widget build(BuildContext context) {
    final mine = viewModel.status == SlotStatus.myBooking;
    final booked = viewModel.status == SlotStatus.booked;
    final blocked = viewModel.status == SlotStatus.blocked;
    final unavailable = booked || blocked;

    return GestureDetector(
      onTap: unavailable ? null : onTap,
      child: Opacity(
        opacity: unavailable ? 0.45 : 1.0,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.lineHair)),
          ),
          child: Stack(
            children: [
              // Orange left stripe for "mine"
              if (mine)
                Positioned(
                  left: 0,
                  top: 12,
                  bottom: 12,
                  child: Container(width: 3, color: AppTheme.orange),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time in Anton
                    SizedBox(
                      width: 88,
                      child: Text(
                        viewModel.slot.startTime,
                        style: AppTheme.display(
                          size: 42,
                          color: mine
                              ? AppTheme.orange
                              : booked
                                  ? AppTheme.concrete
                                  : AppTheme.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Middle content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mine) ...[
                            Text(
                              'SUA RESERVA',
                              style: AppTheme.mono(
                                size: 9.5,
                                color: AppTheme.orange,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confirmada · 60 min',
                              style: AppTheme.ui(size: 13, color: AppTheme.concrete),
                            ),
                          ] else if (booked) ...[
                            Text(
                              viewModel.bookerName ?? 'Ocupado',
                              style: AppTheme.ui(size: 13, color: AppTheme.concrete),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else if (blocked) ...[
                            Text(
                              'BLOQUEADO',
                              style: AppTheme.mono(
                                size: 9.5,
                                color: AppTheme.concrete,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ] else ...[
                            _SportPrice(value: viewModel.slot.price),
                          ],
                        ],
                      ),
                    ),
                    // Chevron for tappable rows
                    if (!unavailable)
                      const Icon(Icons.chevron_right, size: 18, color: AppTheme.concrete),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportPrice extends StatelessWidget {
  final double value;
  const _SportPrice({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'R\$',
            style: AppTheme.mono(size: 11, color: AppTheme.concrete, letterSpacing: 0),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          value.toStringAsFixed(0),
          style: AppTheme.display(size: 22, color: AppTheme.concrete),
        ),
      ],
    );
  }
}
