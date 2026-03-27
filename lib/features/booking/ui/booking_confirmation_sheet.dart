import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';
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
  final TextEditingController _participantsController = TextEditingController();

  Future<void> _handleConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final authState = context.read<AuthCubit>().state as AuthAuthenticated;
      await widget.bookingCubit.bookSlot(
        slotId: widget.viewModel.slot.id,
        dateString: widget.viewModel.dateString,
        price: widget.viewModel.slot.price,
        startTime: widget.viewModel.slot.startTime,
        userDisplayName: authState.user.displayName,
        participants: _participantsController.text.trim().isEmpty
            ? null
            : _participantsController.text.trim(),
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
          : e.toString().contains('slot_already_passed')
              ? 'Este horario ja passou.'
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
  void dispose() {
    _participantsController.dispose();
    super.dispose();
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
        Text(text),
      ],
    );
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
                color: const Color(0xFFD0CAC0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirmar Reserva',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.calendar_today, dateDisplay),
          const SizedBox(height: 10),
          _infoRow(Icons.access_time, widget.viewModel.slot.startTime),
          const SizedBox(height: 10),
          _infoRow(
            Icons.attach_money,
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                .format(widget.viewModel.slot.price),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _participantsController,
            decoration: const InputDecoration(
              labelText: 'Quem vai jogar? (opcional)',
              hintText: 'Ex: Joao, Maria, Pedro',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            maxLength: 200,
            maxLines: 2,
            textCapitalization: TextCapitalization.words,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFC62828)),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _handleConfirm,
            style: FilledButton.styleFrom(
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
                : const Text('Reservar'),
          ),
        ],
      ),
    );
  }
}
