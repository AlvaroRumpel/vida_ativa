import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';

class ClientBookingDetailSheet extends StatefulWidget {
  final BookingModel booking;
  final BookingCubit bookingCubit;
  final bool isFuture;

  const ClientBookingDetailSheet({
    super.key,
    required this.booking,
    required this.bookingCubit,
    required this.isFuture,
  });

  @override
  State<ClientBookingDetailSheet> createState() =>
      _ClientBookingDetailSheetState();
}

class _ClientBookingDetailSheetState extends State<ClientBookingDetailSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Color _statusColor(String status) => switch (status) {
    'pending' => const Color(0xFFD4860A),
    'confirmed' => AppTheme.primaryGreen,
    'rejected' => Colors.red,
    'pending_payment' => Colors.amber,
    'expired' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String status) => switch (status) {
    'pending' => 'Aguardando',
    'confirmed' => 'Confirmado',
    'rejected' => 'Recusado',
    'pending_payment' => 'Aguardando Pix',
    'expired' => 'Expirada',
    _ => 'Cancelado',
  };

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

  Future<void> _handleCancel() async {
    if (widget.booking.recurrenceGroupId != null) {
      await _handleCancelRecurrent();
    } else {
      await _handleCancelSingle();
    }
  }

  Future<void> _handleCancelSingle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva?'),
        content: const Text('Tem certeza que deseja cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() { _isSubmitting = true; _errorMessage = null; });
    try {
      await widget.bookingCubit.cancelBooking(widget.booking);
      if (mounted) Navigator.pop(context);
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Erro ao cancelar. Tente novamente.';
        });
      }
    }
  }

  Future<void> _handleCancelRecurrent() async {
    // 'single' = cancel only this booking; 'group' = cancel this + all future
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva recorrente?'),
        content: const Text(
          'Cancelar só esta reserva ou esta e todas as próximas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'single'),
            child: const Text('Cancelar só esta'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            onPressed: () => Navigator.pop(ctx, 'group'),
            child: const Text('Cancelar esta e as próximas'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    setState(() { _isSubmitting = true; _errorMessage = null; });
    try {
      if (choice == 'single') {
        await widget.bookingCubit.cancelBooking(widget.booking);
      } else {
        // Cancel this booking and all future bookings in the group.
        // fromDateInclusive = today (YYYY-MM-DD) to include this booking's date and forward.
        final now = DateTime.now();
        final today = '${now.year}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        await widget.bookingCubit.cancelGroupFuture(
          recurrenceGroupId: widget.booking.recurrenceGroupId!,
          fromDateInclusive: today,
        );
      }
      if (mounted) Navigator.pop(context);
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Erro ao cancelar. Tente novamente.';
        });
      }
    }
  }

  Future<void> _handleShare() async {
    final booking = widget.booking;
    final nome = booking.userDisplayName ?? '';
    final parsedDate = DateTime.parse(booking.date);
    final rawFormatted =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(parsedDate);
    final dateDisplay =
        '${rawFormatted[0].toUpperCase()}${rawFormatted.substring(1)}';
    final horario = booking.startTime ?? '';

    final buffer = StringBuffer();
    buffer.writeln('Reserva confirmada para $nome — Arena Vida Ativa');
    buffer.writeln();
    buffer.writeln('$dateDisplay, as $horario');
    if (booking.participants != null && booking.participants!.isNotEmpty) {
      buffer.writeln('Participantes: ${booking.participants}');
    }
    buffer.writeln();
    buffer.write('Nos vemos na quadra!');

    await launchUrl(
      Uri(
        scheme: 'https',
        host: 'wa.me',
        path: '/',
        queryParameters: {'text': buffer.toString()},
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);

    // Format date: "YYYY-MM-DD" -> "Quarta, 2 de abril"
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

    final bool showCancelButton =
        widget.isFuture && !booking.isCancelled && booking.status != 'rejected';
    final bool showActionButtons =
        !booking.isCancelled && booking.status != 'rejected';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
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
          // Action buttons
          if (showActionButtons) ...[
            const SizedBox(height: 24),
            if (showCancelButton)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _handleCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _handleShare,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Compartilhar'),
                    ),
                  ),
                ],
              )
            else
              FilledButton(
                onPressed: _isSubmitting ? null : _handleShare,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Compartilhar'),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
