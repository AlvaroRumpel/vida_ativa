import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';

class AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final AdminBookingCubit bookingCubit;

  const AdminBookingCard({
    super.key,
    required this.booking,
    required this.bookingCubit,
  });

  Color _statusColor(String status, String? paymentMethod) {
    return switch ((status, paymentMethod)) {
      ('pending', _) => Colors.orange,
      ('pending_payment', _) => const Color(0xFFFFC107),
      ('confirmed', 'pix') => const Color(0xFF4CAF50),
      ('confirmed', 'on_arrival') => const Color(0xFF2196F3),
      ('confirmed', _) => AppTheme.primaryGreen,
      ('expired', _) => Colors.grey,
      ('rejected', _) => Colors.red,
      _ => Colors.grey,
    };
  }

  // Paleta determinística para chip de esporte (UI-SPEC §Color)
  static const List<Color> _sportBgColors = [
    Color(0xFFE3F2FD), // blue bg
    Color(0xFFE8F5E9), // green bg
    Color(0xFFFFF3E0), // orange bg
    Color(0xFFF3E5F5), // purple bg
    Color(0xFFFCE4EC), // pink bg
    Color(0xFFE0F7FA), // teal bg
    Color(0xFFF9FBE7), // lime bg
    Color(0xFFFFF8E1), // amber bg
  ];

  static const List<Color> _sportFgColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF00695C),
    Color(0xFF558B2F),
    Color(0xFFF57F17),
  ];

  int _sportColorIndex(String sport) =>
      sport.hashCode.abs() % _sportBgColors.length;

  Widget _buildSportChip(String sport) {
    final i = _sportColorIndex(sport);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _sportBgColors[i],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        sport,
        style: TextStyle(
          color: _sportFgColors[i],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String status, String? paymentMethod) {
    return switch ((status, paymentMethod)) {
      ('pending', _) => 'Aguardando',
      ('pending_payment', _) => 'Aguardando Pix',
      ('confirmed', 'pix') => 'Pix pago',
      ('confirmed', 'on_arrival') => 'Pagar na hora',
      ('confirmed', _) => 'Confirmado',
      ('expired', _) => 'Expirada',
      ('rejected', _) => 'Recusado',
      _ => 'Cancelado',
    };
  }

  Future<void> _confirmAction(BuildContext context) async {
    final cubit = bookingCubit;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar reserva?'),
        content: const Text('Deseja confirmar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nao'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      await cubit.confirmBooking(booking.id);
    }
  }

  Future<void> _rejectAction(BuildContext context) async {
    final cubit = bookingCubit;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar reserva?'),
        content: const Text('Deseja recusar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nao'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      await cubit.rejectBooking(booking.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceText = booking.price != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
            .format(booking.price)
        : '';
    final statusColor = _statusColor(booking.status, booking.paymentMethod);
    final statusLabel = _statusLabel(booking.status, booking.paymentMethod);
    final clientName = booking.userDisplayName ?? 'Cliente';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (booking.participants != null &&
                        booking.participants!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.group, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.participants!,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (booking.sport != null) ...[
                      const SizedBox(height: 4),
                      _buildSportChip(booking.sport!),
                    ],
                    if (booking.startTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14,
                              color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            booking.startTime!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (priceText.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.attach_money, size: 14,
                                color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              priceText,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (booking.isPending) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _confirmAction(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                              child: const Text('Confirmar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _rejectAction(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Recusar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
