import 'package:flutter/material.dart';

import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

/// A hairline-style row for displaying a booking in the admin booking list.
///
/// Layout:
///   Left  — startTime in Anton 36px (ink)
///   Middle — client name (Manrope 14px bold), optional participants (Manrope 14px
///            concrete), status label (JetBrains Mono 11px colored)
///   Right  — CONFIRMAR / RECUSAR outline pills (visible only when isPending)
///
/// A 0.5px [AppTheme.lineHair] top border is shown on all rows except the first
/// (index == 0).
class AdminBookingRow extends StatelessWidget {
  final BookingModel booking;

  /// Row index within the list — used to suppress the top hairline on the first row.
  final int index;

  /// Called when the admin taps CONFIRMAR. Null hides the button area.
  final VoidCallback? onConfirm;

  /// Called when the admin taps RECUSAR. Null hides the button area.
  final VoidCallback? onReject;

  const AdminBookingRow({
    super.key,
    required this.booking,
    required this.index,
    this.onConfirm,
    this.onReject,
  });

  Color _statusColor(String status, String? paymentMethod) {
    return switch ((status, paymentMethod)) {
      ('pending', _) => AppTheme.orange,
      ('pending_payment', _) => AppTheme.sun,
      ('confirmed', 'pix') => AppTheme.court,
      ('confirmed', 'on_arrival') => AppTheme.ink,
      ('confirmed', _) => AppTheme.court,
      ('expired', _) => AppTheme.concrete,
      ('rejected', _) => AppTheme.orangeDk,
      _ => AppTheme.concrete,
    };
  }

  String _statusLabel(String status, String? paymentMethod) {
    return switch ((status, paymentMethod)) {
      ('pending', _) => 'AGUARDANDO',
      ('pending_payment', _) => 'AGUARDANDO PIX',
      ('confirmed', 'pix') => 'PIX PAGO',
      ('confirmed', 'on_arrival') => 'PAGAR NA HORA',
      ('confirmed', _) => 'CONFIRMADO',
      ('expired', _) => 'EXPIRADO',
      ('rejected', _) => 'RECUSADO',
      _ => status.toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status, booking.paymentMethod);
    final statusLabel = _statusLabel(booking.status, booking.paymentMethod);
    final isPending = booking.isPending;
    final clientName = booking.userDisplayName ?? 'Cliente';
    final timeDisplay = booking.startTime ?? '';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : const Border(
                top: BorderSide(color: AppTheme.lineHair, width: 0.5),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: time + name + participants | price
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(timeDisplay, style: AppTheme.display(size: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clientName,
                        style: AppTheme.ui(size: 15, weight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (booking.participants != null &&
                          booking.participants!.isNotEmpty)
                        Text(
                          booking.participants!,
                          style: AppTheme.ui(size: 12, color: AppTheme.concrete),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                if (booking.price != null)
                  Text(
                    'R\$ ${booking.price!.toStringAsFixed(0)}',
                    style: AppTheme.ui(size: 14, color: AppTheme.concrete),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: status | actions (pending only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusLabel,
                  style: AppTheme.mono(size: 10, color: statusColor),
                ),
                if (isPending)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // CONFIRMAR — ink filled with check icon
                      SizedBox(
                        height: 32,
                        child: FilledButton.icon(
                          onPressed: onConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.ink,
                            foregroundColor: AppTheme.paper,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: const StadiumBorder(),
                            textStyle: AppTheme.mono(size: 10),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.check, size: 11),
                          label: const Text('CONFIRMAR'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // RECUSAR — quiet outlined
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.ink,
                            side: const BorderSide(color: AppTheme.ink, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: const StadiumBorder(),
                            textStyle: AppTheme.mono(size: 10),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('RECUSAR'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
