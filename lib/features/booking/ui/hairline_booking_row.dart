import 'package:flutter/material.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/ui/client_booking_detail_sheet.dart';
import 'package:vida_ativa/features/booking/ui/pix_payment_screen.dart';

/// A hairline-style row for displaying a booking in the client's booking list.
///
/// Layout:
///   Left  — day-of-month (Anton 30px) + day abbreviation (mono 10px concrete)
///   Middle — time (Anton 26px, expanded)
///   Right  — status pill (outline only, no fill) with optional AGUARDANDO PIX eyebrow
///
/// A 0.5px [AppTheme.lineHair] top border is shown on all rows except the first
/// (index == 0).
///
/// Tap routing:
///   - pending_payment + paymentId → PixPaymentScreen (full-screen push)
///   - all other statuses → ClientBookingDetailSheet (bottom sheet)
class HairlineBookingRow extends StatelessWidget {
  final BookingModel booking;
  final BookingCubit bookingCubit;

  /// Row index within the list — used to suppress the top hairline on the first row.
  final int index;

  /// Whether this booking is in the future — passed to ClientBookingDetailSheet.
  final bool isFuture;

  static const _dayAbbrevs = [
    'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM',
  ];

  const HairlineBookingRow({
    super.key,
    required this.booking,
    required this.bookingCubit,
    required this.index,
    required this.isFuture,
  });

  (Color, String) _statusInfo(String status) {
    return switch (status) {
      'confirmed'       => (AppTheme.court, 'CONFIRMADO'),
      'pending_payment' => (AppTheme.orange, 'PIX PENDENTE'),
      'cancelled'       => (AppTheme.orangeDk, 'CANCELADO'),
      'expired'         => (AppTheme.concrete, 'EXPIRADO'),
      _                 => (AppTheme.concrete, status.toUpperCase()),
    };
  }

  void _onTap(BuildContext context) {
    if (booking.isPendingPayment && booking.paymentId != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PixPaymentScreen(
            bookingId: booking.id,
            paymentId: booking.paymentId,
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ClientBookingDetailSheet(
          booking: booking,
          bookingCubit: bookingCubit,
          isFuture: isFuture,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(booking.date);
    final dayNum = date.day;
    final dayAbbr = _dayAbbrevs[date.weekday - 1];
    final timeDisplay = booking.startTime ?? '';
    final (statusColor, statusLabel) = _statusInfo(booking.status);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : const Border(
                top: BorderSide(color: AppTheme.lineHair, width: 0.5),
              ),
      ),
      child: InkWell(
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: day number + day abbreviation
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$dayNum',
                    style: AppTheme.display(size: 30, color: AppTheme.ink),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dayAbbr,
                    style: AppTheme.mono(size: 10, color: AppTheme.concrete),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Middle: time (expanded)
              Expanded(
                child: Text(
                  timeDisplay,
                  style: AppTheme.display(size: 26, color: AppTheme.ink),
                ),
              ),
              // Right: optional eyebrow + status pill (outline only, no fill)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (booking.status == 'pending_payment')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'AGUARDANDO PIX',
                        style: AppTheme.mono(size: 9, color: AppTheme.orange),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: statusColor, width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Text(
                      statusLabel,
                      style: AppTheme.mono(size: 10, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
