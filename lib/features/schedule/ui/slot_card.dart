import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class SlotHairlineRow extends StatelessWidget {
  final SlotViewModel viewModel;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDetailTap;

  const SlotHairlineRow({
    super.key,
    required this.viewModel,
    required this.index,
    this.onTap,
    this.onDetailTap,
  });

  BoxDecoration _borderDecoration() => BoxDecoration(
        border: index == 0
            ? null
            : const Border(
                top: BorderSide(color: AppTheme.lineHair, width: 0.5),
              ),
      );

  double _opacity(SlotStatus status) => switch (status) {
        SlotStatus.available => 1.0,
        SlotStatus.myBooking => 1.0,
        SlotStatus.booked => 0.45,
        SlotStatus.blocked => 0.45,
      };

  String _statusLabel(SlotViewModel vm) => switch (vm.status) {
        SlotStatus.available => 'DISPONÍVEL',
        SlotStatus.myBooking => 'MINHA RESERVA',
        SlotStatus.booked => (vm.bookerName ?? 'OCUPADO').toUpperCase(),
        SlotStatus.blocked => 'BLOQUEADO',
      };

  Color _statusLabelColor(SlotStatus status) => switch (status) {
        SlotStatus.available => AppTheme.court,
        SlotStatus.myBooking => AppTheme.concrete,
        SlotStatus.booked => AppTheme.concrete,
        SlotStatus.blocked => AppTheme.concrete,
      };

  String _formatPrice(double price) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(price);

  Widget _contentRow() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            viewModel.slot.startTime,
            style: AppTheme.display(size: 42),
          ),
          const Spacer(),
          Text(
            _formatPrice(viewModel.slot.price),
            style: AppTheme.mono(size: 11),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Text(
              _statusLabel(viewModel),
              style: AppTheme.mono(
                size: 11,
                color: _statusLabelColor(viewModel.status),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );

  // Plain row — available, booked, blocked.
  // IntrinsicHeight is NOT used here (performance: these appear many times in list).
  Widget _buildPlainRow() => DecoratedBox(
        decoration: _borderDecoration(),
        child: Opacity(
          opacity: _opacity(viewModel.status),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _contentRow(),
            ),
          ),
        ),
      );

  // Stripe row — myBooking only.
  // IntrinsicHeight is acceptable here: a user has at most one myBooking per day.
  Widget _buildStripeRow() => DecoratedBox(
        decoration: _borderDecoration(),
        child: InkWell(
          onTap: onDetailTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: AppTheme.orange),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: _contentRow(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (viewModel.status == SlotStatus.myBooking) {
      return _buildStripeRow();
    }
    return _buildPlainRow();
  }
}
