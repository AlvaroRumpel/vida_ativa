import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isFuture;
  final VoidCallback? onCancel;
  final BookingCubit? bookingCubit;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isFuture,
    required this.onCancel,
    this.bookingCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _statusColor(booking.status)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(booking.date),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (booking.startTime != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFF9E9A95),
                          ),
                          const SizedBox(width: 4),
                          Text(booking.startTime!),
                        ],
                      ),
                    if (booking.price != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Color(0xFF9E9A95),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormat.currency(
                              locale: 'pt_BR',
                              symbol: 'R\$',
                            ).format(booking.price!),
                          ),
                        ],
                      ),
                    if (booking.participants != null &&
                        booking.participants!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group,
                              size: 16,
                              color: Color(0xFF9E9A95),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.participants!,
                                style: const TextStyle(
                                  color: Color(0xFF9E9A95),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statusBadge(booking.status, booking: booking),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!booking.isCancelled &&
                                booking.status != 'rejected')
                              IconButton(
                                icon: const Icon(Icons.share, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Compartilhar via WhatsApp',
                                onPressed: _shareWhatsApp,
                              ),
                            if (!booking.isCancelled &&
                                bookingCubit != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _showEditParticipantsDialog(context),
                              ),
                            ],
                            if (isFuture && !booking.isCancelled)
                              TextButton(
                                onPressed: onCancel,
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Color(0xFFC62828)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (booking.recurrenceGroupId != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Recorrente',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Future<void> _shareWhatsApp() async {
    final nome = booking.userDisplayName ?? '';
    final data = _formatDate(booking.date);
    final horario = booking.startTime ?? '';

    final buffer = StringBuffer();
    buffer.writeln('Reserva confirmada para $nome — Arena Vida Ativa');
    buffer.writeln();
    buffer.writeln('$data, as $horario');
    if (booking.participants != null && booking.participants!.isNotEmpty) {
      buffer.writeln('Participantes: ${booking.participants}');
    }
    buffer.writeln();
    buffer.write('Nos vemos na quadra!');

    final url = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/',
      queryParameters: {'text': buffer.toString()},
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showEditParticipantsDialog(BuildContext context) async {
    final controller = TextEditingController(text: booking.participants ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Participantes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: Joao, Maria, Pedro',
            border: OutlineInputBorder(),
          ),
          maxLength: 200,
          maxLines: 2,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await bookingCubit!.updateParticipants(
        booking.id,
        result.isEmpty ? null : result,
      );
    }
  }

  String _formatDate(String dateString) {
    final formatted = DateFormat(
      'EEEE, d \'de\' MMMM',
      'pt_BR',
    ).format(DateTime.parse(dateString));
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  Color _statusColor(String status) => switch (status) {
    'pending' => const Color(0xFFD4860A),
    'pending_payment' => const Color(0xFFE65100),
    'confirmed' => AppTheme.primaryGreen,
    'expired' => Colors.grey,
    'rejected' => Colors.red,
    _ => Colors.grey,
  };

  String _statusLabel(String status) => switch (status) {
    'pending' => 'Aguardando',
    'pending_payment' => 'Aguardando Pix',
    'confirmed' => 'Confirmado',
    'expired' => 'Expirada',
    'rejected' => 'Recusado',
    _ => 'Cancelado',
  };

  Widget _statusBadge(String status, {BookingModel? booking}) {
    // Special case: on_arrival confirmed bookings show different badge
    if (booking != null && booking.isOnArrival) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Pagar na hora',
          style: TextStyle(
            color: Color(0xFF1565C0),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
