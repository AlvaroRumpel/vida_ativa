import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class SlotEventTile extends StatelessWidget {
  final SlotViewModel viewModel;
  final VoidCallback? onTap;

  const SlotEventTile({super.key, required this.viewModel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor(viewModel.status),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (viewModel.status) {
      case SlotStatus.available:
        return InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: AppTheme.primaryGreen,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        viewModel.slot.startTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatPrice(viewModel.slot.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case SlotStatus.booked:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: const Color(0xFF9E9E9E),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.slot.startTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Text(
                      viewModel.bookerName ?? 'Ocupado',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757575),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case SlotStatus.myBooking:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.slot.startTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Minha reserva',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.white70, size: 18),
            ],
          ),
        );

      case SlotStatus.blocked:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: const Color(0xFFC62828),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Bloqueado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB71C1C),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Color _backgroundColor(SlotStatus status) => switch (status) {
        SlotStatus.available => AppTheme.primaryGreen.withValues(alpha: 0.10),
        SlotStatus.booked => const Color(0xFFF0EDE8),
        SlotStatus.myBooking => AppTheme.primaryGreen,
        SlotStatus.blocked => const Color(0xFFFCECEC),
      };

  String _formatPrice(double price) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(price);
}
