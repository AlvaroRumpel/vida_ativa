import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';

class AdminBookingDetailSheet extends StatefulWidget {
  final BookingModel booking;
  final AdminBookingCubit adminBookingCubit;

  const AdminBookingDetailSheet({
    super.key,
    required this.booking,
    required this.adminBookingCubit,
  });

  @override
  State<AdminBookingDetailSheet> createState() =>
      _AdminBookingDetailSheetState();
}

class _AdminBookingDetailSheetState extends State<AdminBookingDetailSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Color _statusColor(String status, String? paymentMethod) {
    return switch ((status, paymentMethod)) {
      ('pending', _) => Colors.orange,
      ('pending_payment', _) => const Color(0xFFFFC107),
      ('confirmed', 'pix') => const Color(0xFF4CAF50),
      ('confirmed', 'on_arrival') => const Color(0xFF2196F3),
      ('confirmed', _) => AppTheme.primaryGreen,
      ('expired', _) => Colors.grey,
      ('rejected', _) => Colors.red,
      ('refunded', _) => Colors.purple,
      _ => Colors.grey,
    };
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
      ('refunded', _) => 'Reembolsado',
      _ => 'Cancelado',
    };
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(text)),
      ],
    );
  }

  Future<void> _handleManualConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('adminConfirmPixPayment');
      await callable.call({'bookingId': widget.booking.id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento confirmado manualmente.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Falha ao confirmar pagamento. Tente novamente.';
        });
      }
    }
  }

  Future<void> _handleConfirm() async {
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
    if (confirmed != true) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.adminBookingCubit.confirmBooking(widget.booking.id);
      if (mounted) Navigator.pop(context);
    } on Exception {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Falha ao confirmar reserva. Tente novamente.';
        });
      }
    }
  }

  Future<void> _handleReject() async {
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
    if (confirmed != true) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.adminBookingCubit.rejectBooking(widget.booking.id);
      if (mounted) Navigator.pop(context);
    } on Exception {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Falha ao recusar reserva. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusColor = _statusColor(booking.status, booking.paymentMethod);
    final statusLabel = _statusLabel(booking.status, booking.paymentMethod);

    // Format date: "YYYY-MM-DD" -> "Segunda, 31 de marco"
    final parsedDate = DateTime.parse(booking.date);
    final rawFormatted =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(parsedDate);
    final dateDisplay =
        '${rawFormatted[0].toUpperCase()}${rawFormatted.substring(1)}';

    // Format price
    final priceDisplay = booking.price != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
            .format(booking.price)
        : '\u2014';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0CAC0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalhes da Reserva',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 16),
          // Info rows
          _infoRow(Icons.person, booking.userDisplayName ?? 'Cliente'),
          const SizedBox(height: 10),
          _infoRow(Icons.calendar_today, dateDisplay),
          const SizedBox(height: 10),
          _infoRow(Icons.access_time, booking.startTime ?? '\u2014'),
          const SizedBox(height: 10),
          _infoRow(Icons.attach_money, priceDisplay),
          if (booking.participants != null &&
              booking.participants!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.group, booking.participants!),
          ],
          // Inline error
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 12,
              ),
            ),
          ],
          // Manual Pix confirm — visible only for pending_payment bookings
          if (booking.status == 'pending_payment') ...[
            const SizedBox(height: 24),
            const Text(
              'O QR code Pix sera invalidado apos a confirmacao.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _handleManualConfirm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text('Confirmar pagamento manual'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          // Buttons only for pending bookings
          if (booking.isPending) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _handleConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _handleReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
