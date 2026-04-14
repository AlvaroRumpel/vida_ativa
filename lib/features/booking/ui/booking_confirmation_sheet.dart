import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/booking/ui/pix_payment_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/ui/recurrence_result_sheet.dart';
import 'package:vida_ativa/features/booking/ui/recurrence_section.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class BookingConfirmationSheet extends StatefulWidget {
  final SlotViewModel viewModel;
  final BookingCubit bookingCubit;
  final bool pixEnabled;

  const BookingConfirmationSheet({
    super.key,
    required this.viewModel,
    required this.bookingCubit,
    this.pixEnabled = true,
  });

  @override
  State<BookingConfirmationSheet> createState() =>
      _BookingConfirmationSheetState();
}

class _BookingConfirmationSheetState extends State<BookingConfirmationSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;
  final TextEditingController _participantsController = TextEditingController();
  bool _isRecurrent = false;
  List<RecurrenceEntry> _availableRecurrenceEntries = [];

  Future<void> _handleConfirmRecurring() async {
    if (_availableRecurrenceEntries.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final authState = context.read<AuthCubit>().state as AuthAuthenticated;
      final outcomes = await widget.bookingCubit.bookRecurring(
        entries: _availableRecurrenceEntries,
        startTime: widget.viewModel.slot.startTime,
        userDisplayName: authState.user.displayName.isNotEmpty
            ? authState.user.displayName
            : authState.user.email,
        paymentMethod: 'on_arrival', // TODO(17-02): replace with user-selected method
        participants: _participantsController.text.trim().isEmpty
            ? null
            : _participantsController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => RecurrenceResultSheet(
          outcomes: outcomes,
          onClose: () {
            Navigator.pop(context); // close result sheet
            Navigator.pop(context); // close confirmation sheet
          },
        ),
      );
    } on Exception catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Falha ao criar reservas. Tente novamente.';
        });
      }
    }
  }

  /// Fluxo Pix: cria booking com pending_payment, gera QR inline, navega para PixPaymentScreen.
  /// Se a geração do QR falhar, a reserva é cancelada e o erro é exibido na sheet.
  Future<void> _handlePayPix() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authState = context.read<AuthCubit>().state as AuthAuthenticated;
    final bookingId = BookingModel.generateId(
      widget.viewModel.slot.id,
      widget.viewModel.dateString,
    );

    // 1. Criar reserva
    try {
      await widget.bookingCubit.bookSlot(
        slotId: widget.viewModel.slot.id,
        dateString: widget.viewModel.dateString,
        price: widget.viewModel.slot.price,
        startTime: widget.viewModel.slot.startTime,
        userDisplayName: authState.user.displayName.isNotEmpty
            ? authState.user.displayName
            : authState.user.email,
        paymentMethod: 'pix',
        participants: _participantsController.text.trim().isEmpty
            ? null
            : _participantsController.text.trim(),
      );
    } on Exception catch (e, s) {
      final str = e.toString();
      final isExpected =
          str.contains('slot_already_booked') || str.contains('slot_already_passed');
      if (!isExpected) await Sentry.captureException(e, stackTrace: s);
      final msg = str.contains('slot_already_booked')
          ? 'Este horario acabou de ser reservado.'
          : str.contains('slot_already_passed')
              ? 'Este horario ja passou.'
              : 'Falha na conexao. Tente novamente.';
      if (mounted) setState(() { _isSubmitting = false; _errorMessage = msg; });
      return;
    }

    // 2. Navegar para PixPaymentScreen (ela chama createPixPayment internamente)
    if (!mounted) return;
    final rootNav = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context); // fecha a sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNav.push(MaterialPageRoute(
        builder: (_) => PixPaymentScreen(bookingId: bookingId),
      ));
    });
  }

  /// Fluxo presencial: cria booking com confirmed + on_arrival, fecha sheet.
  Future<void> _handlePayOnArrival() async {
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
        userDisplayName: authState.user.displayName.isNotEmpty
            ? authState.user.displayName
            : authState.user.email,
        paymentMethod: 'on_arrival',
        participants: _participantsController.text.trim().isEmpty
            ? null
            : _participantsController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      SnackHelper.success(context, 'Reserva confirmada!');
    } on Exception catch (e, s) {
      final str = e.toString();
      final isExpected =
          str.contains('slot_already_booked') || str.contains('slot_already_passed');
      if (!isExpected) await Sentry.captureException(e, stackTrace: s);
      final msg = str.contains('slot_already_booked')
          ? 'Este horario acabou de ser reservado.'
          : str.contains('slot_already_passed')
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

    return SingleChildScrollView(
      child: Padding(
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
            // Recurrence toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reservar semanalmente',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: _isRecurrent,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: (v) => setState(() => _isRecurrent = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Animated recurrence section
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isRecurrent
                  ? RecurrenceSection(
                      anchorDateString: widget.viewModel.dateString,
                      anchorWeekday:
                          DateTime.parse(widget.viewModel.dateString).weekday,
                      startTime: widget.viewModel.slot.startTime,
                      slotPrice: widget.viewModel.slot.price,
                      firestore: FirebaseFirestore.instance,
                      onAvailableEntriesChanged: (entries) {
                        setState(
                            () => _availableRecurrenceEntries = entries);
                      },
                    )
                  : const SizedBox.shrink(),
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
            if (!_isRecurrent) ...[
              if (widget.pixEnabled) ...[
                // Titulo da secao de pagamento
                const Text(
                  'Como voce prefere pagar?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                // Botao Pix
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handlePayPix,
                  icon: const Icon(Icons.qr_code, size: 20),
                  label: const Text('Pagar com Pix'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Botao na hora
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _handlePayOnArrival,
                  icon: const Icon(Icons.handshake_outlined, size: 20),
                  label: const Text('Pagar na hora'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else ...[
                // Pix desabilitado — botao unico de confirmacao
                FilledButton(
                  onPressed: _isSubmitting ? null : _handlePayOnArrival,
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
                      : const Text('Confirmar reserva'),
                ),
              ],
            ] else ...[
              // Recorrente continua com um unico botao (bookRecurring)
              FilledButton(
                onPressed: _isSubmitting ? null : _handleConfirmRecurring,
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
                    : Text(_availableRecurrenceEntries.isEmpty
                        ? 'Reservar semanalmente'
                        : 'Reservar ${_availableRecurrenceEntries.length} reserva${_availableRecurrenceEntries.length != 1 ? "s" : ""}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
