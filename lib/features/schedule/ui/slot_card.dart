import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class SlotCard extends StatelessWidget {
  final SlotViewModel viewModel;
  final VoidCallback? onTap;

  const SlotCard({super.key, required this.viewModel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: _statusColor(viewModel.status),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      viewModel.slot.startTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(viewModel.slot.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusLabel(status: viewModel.status, bookerName: viewModel.bookerName),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Color _statusColor(SlotStatus status) => switch (status) {
        SlotStatus.available => AppTheme.primaryGreen,
        SlotStatus.booked => Colors.grey,
        SlotStatus.myBooking => Colors.grey,
        SlotStatus.blocked => const Color(0xFFE53935),
      };

  String _formatPrice(double price) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(price);
}

class _StatusLabel extends StatelessWidget {
  final SlotStatus status;
  final String? bookerName;

  const _StatusLabel({required this.status, this.bookerName});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      SlotStatus.available => const Text(
          'Dispon\u00edvel',
          style: TextStyle(color: AppTheme.primaryGreen),
        ),
      SlotStatus.booked => Text(
          bookerName ?? 'Ocupado',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      SlotStatus.myBooking => Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: const Text(
            'Minha reserva',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      SlotStatus.blocked => const Text(
          'Bloqueado',
          style: TextStyle(color: Color(0xFFE53935)),
        ),
    };
  }
}
