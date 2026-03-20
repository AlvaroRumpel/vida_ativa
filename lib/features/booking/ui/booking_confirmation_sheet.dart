import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class BookingConfirmationSheet extends StatefulWidget {
  final SlotViewModel viewModel;
  final BookingCubit bookingCubit;

  const BookingConfirmationSheet({
    super.key,
    required this.viewModel,
    required this.bookingCubit,
  });

  @override
  State<BookingConfirmationSheet> createState() =>
      _BookingConfirmationSheetState();
}

class _BookingConfirmationSheetState extends State<BookingConfirmationSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.bookingCubit.bookSlot(
        slotId: widget.viewModel.slot.id,
        dateString: widget.viewModel.dateString,
        price: widget.viewModel.slot.price,
        startTime: widget.viewModel.slot.startTime,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva feita!')),
        );
      }
    } on Exception catch (e) {
      final msg = e.toString().contains('slot_already_booked')
          ? 'Este horario acabou de ser reservado.'
          : 'Falha na conexao. Tente novamente.';
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR')
        .format(DateTime.parse(widget.viewModel.dateString));
    final dateDisplay =
        '${formatted[0].toUpperCase()}${formatted.substring(1)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirmar Reserva',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Date row
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Text(dateDisplay),
            ],
          ),
          const SizedBox(height: 8),
          // Time row
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 8),
              Text(widget.viewModel.slot.startTime),
            ],
          ),
          const SizedBox(height: 8),
          // Price row
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16),
              const SizedBox(width: 8),
              Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                    .format(widget.viewModel.slot.price),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _handleConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              minimumSize: const Size(double.infinity, 48),
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
                : const Text('Reservar'),
          ),
        ],
      ),
    );
  }
}
