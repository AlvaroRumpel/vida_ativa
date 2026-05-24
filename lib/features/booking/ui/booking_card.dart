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
    final parsed = DateTime.tryParse(booking.date);
    final dayAbbrev = parsed != null
        ? DateFormat('EEE', 'pt_BR').format(parsed).toUpperCase().substring(0, 3)
        : '';
    final monthAbbrev = parsed != null
        ? DateFormat('MMM', 'pt_BR').format(parsed).toUpperCase()
        : '';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lineHair)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date column
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayAbbrev,
                    style: AppTheme.mono(size: 9, color: AppTheme.concrete, letterSpacing: 1.44)),
                if (parsed != null) ...[
                  Text(
                    parsed.day.toString().padLeft(2, '0'),
                    style: AppTheme.display(size: 30, color: AppTheme.ink),
                  ),
                  Text(monthAbbrev,
                      style: AppTheme.mono(size: 8.5, color: AppTheme.concrete, letterSpacing: 1.44)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (booking.startTime != null)
                  Text(
                    booking.startTime!,
                    style: AppTheme.display(size: 26, color: AppTheme.ink),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatusPill(status: booking.status, isOnArrival: booking.isOnArrival),
                    if (booking.recurrenceGroupId != null) ...[
                      const SizedBox(width: 8),
                      _QuietPill(label: 'Recorrente'),
                    ],
                  ],
                ),
                if (booking.participants != null && booking.participants!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    booking.participants!,
                    style: AppTheme.ui(size: 12, color: AppTheme.concrete),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right: price + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (booking.price != null)
                _SportPrice(value: booking.price!),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!booking.isCancelled && !booking.isRefunded && booking.status != 'rejected')
                    _ActionIcon(icon: Icons.share_outlined, onTap: _shareWhatsApp),
                  if (!booking.isCancelled && !booking.isRefunded && bookingCubit != null) ...[
                    const SizedBox(width: 4),
                    _ActionIcon(
                      icon: Icons.edit_outlined,
                      onTap: () => _showEditParticipantsDialog(context),
                    ),
                  ],
                  if (isFuture && !booking.isCancelled) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onCancel,
                      child: Text(
                        'Cancelar',
                        style: AppTheme.mono(size: 9, color: AppTheme.orangeDk, letterSpacing: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp() async {
    final nome = booking.userDisplayName ?? '';
    final data = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(DateTime.parse(booking.date));
    final horario = booking.startTime ?? '';
    final buffer = StringBuffer()
      ..writeln('Reserva confirmada para $nome — Arena Vida Ativa')
      ..writeln()
      ..writeln('$data, às $horario');
    if (booking.participants != null && booking.participants!.isNotEmpty) {
      buffer.writeln('Participantes: ${booking.participants}');
    }
    buffer..writeln()..write('Nos vemos na quadra!');
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
            hintText: 'Ex: João, Maria, Pedro',
            border: OutlineInputBorder(),
          ),
          maxLength: 200,
          maxLines: 2,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await bookingCubit!.updateParticipants(booking.id, result.isEmpty ? null : result);
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool isOnArrival;
  const _StatusPill({required this.status, required this.isOnArrival});

  @override
  Widget build(BuildContext context) {
    final (label, color) = isOnArrival
        ? ('Pagar na hora', AppTheme.concrete)
        : switch (status) {
            'pending' => ('Aguardando', AppTheme.orange),
            'pending_payment' => ('Aguardando Pix', AppTheme.orange),
            'confirmed' => ('Confirmado', AppTheme.court),
            'expired' => ('Expirada', AppTheme.concrete),
            'rejected' => ('Recusado', AppTheme.orangeDk),
            'refunded' => ('Reembolsado', AppTheme.concrete),
            _ => ('Cancelado', AppTheme.concrete),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.mono(size: 9, color: color, letterSpacing: 1.6),
      ),
    );
  }
}

class _QuietPill extends StatelessWidget {
  final String label;
  const _QuietPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.mono(size: 9, color: AppTheme.concrete, letterSpacing: 1.6),
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
          padding: const EdgeInsets.only(top: 2),
          child: Text('R\$',
              style: AppTheme.mono(size: 10, color: AppTheme.concrete, letterSpacing: 0)),
        ),
        const SizedBox(width: 2),
        Text(value.toStringAsFixed(0), style: AppTheme.display(size: 22, color: AppTheme.concrete)),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 18, color: AppTheme.concrete),
    );
  }
}
