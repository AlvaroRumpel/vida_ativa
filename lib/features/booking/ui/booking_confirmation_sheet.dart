import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/booking/ui/pix_payment_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/widgets/sport_btn.dart';
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
  final List<String> sports; // SPORT-01 — D-04: vazia = dropdown escondido

  const BookingConfirmationSheet({
    super.key,
    required this.viewModel,
    required this.bookingCubit,
    this.pixEnabled = true,
    this.sports = const <String>[],
  });

  @override
  State<BookingConfirmationSheet> createState() =>
      _BookingConfirmationSheetState();
}

class _BookingConfirmationSheetState extends State<BookingConfirmationSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;
  final TextEditingController _participantsController = TextEditingController();
  String? _selectedSport;
  bool _isRecurrent = false;
  List<RecurrenceEntry> _availableRecurrenceEntries = [];
  bool _requiresConfirmation = true;

  @override
  void initState() {
    super.initState();
    _fetchConfirmationMode();
  }

  Future<void> _fetchConfirmationMode() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('config')
          .doc('booking')
          .get();
      final mode = snap.data()?['confirmationMode'] ?? 'manual';
      if (mounted) setState(() => _requiresConfirmation = mode != 'automatic');
    } catch (e) {
      debugPrint('Failed to fetch confirmation mode: $e');
      // keep default true (_requiresConfirmation stays true)
    }
  }

  /// WR-02: Centralises string-based error classification in one place.
  /// If the backend changes error message format, only this method needs updating.
  String _classifyBookingError(String errorStr) {
    if (errorStr.contains('slot_already_booked')) {
      return 'Este horario acabou de ser reservado.';
    }
    if (errorStr.contains('slot_already_passed')) {
      return 'Este horario ja passou.';
    }
    return 'Falha na conexao. Tente novamente.';
  }

  /// Returns true for known/expected booking errors that should not be sent to Sentry.
  bool _isExpectedBookingError(String errorStr) {
    return errorStr.contains('slot_already_booked') ||
        errorStr.contains('slot_already_passed');
  }

  Future<void> _handleConfirmRecurring() async {
    if (_availableRecurrenceEntries.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final rawAuthState = context.read<AuthCubit>().state;
    if (rawAuthState is! AuthAuthenticated) {
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      final authState = rawAuthState;
      final outcomes = await widget.bookingCubit.bookRecurring(
        entries: _availableRecurrenceEntries,
        startTime: widget.viewModel.slot.startTime,
        userDisplayName: authState.user.displayName.isNotEmpty
            ? authState.user.displayName
            : authState.user.email,
        paymentMethod: 'on_arrival',
        participants: _participantsController.text.trim().isEmpty
            ? null
            : _participantsController.text.trim(),
        sport: _selectedSport,
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

  /// Fluxo Pix: cria booking com pending_payment, navega para PixPaymentScreen.
  Future<void> _handlePayPix() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final rawAuthState = context.read<AuthCubit>().state;
    if (rawAuthState is! AuthAuthenticated) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final authState = rawAuthState;

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
        sport: _selectedSport,
      );
    } on Exception catch (e, s) {
      final str = e.toString();
      if (!_isExpectedBookingError(str)) await Sentry.captureException(e, stackTrace: s);
      final msg = _classifyBookingError(str);
      if (mounted) setState(() { _isSubmitting = false; _errorMessage = msg; });
      return;
    }

    if (!mounted) return;
    // WR-05: generate bookingId after successful bookSlot to avoid computing it on failure
    final bookingId = BookingModel.generateId(
      widget.viewModel.slot.id,
      widget.viewModel.dateString,
    );
    final rootNav = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {  // WR-03: double-check mounted before push
        rootNav.push(MaterialPageRoute(
          builder: (_) => PixPaymentScreen(bookingId: bookingId),
        ));
      }
    });
  }

  /// Fluxo presencial: cria booking com on_arrival, fecha sheet.
  Future<void> _handlePayOnArrival() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final rawAuthState = context.read<AuthCubit>().state;
    if (rawAuthState is! AuthAuthenticated) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final authState = rawAuthState;
    try {
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
        sport: _selectedSport,
      );
      if (!mounted) return;
      Navigator.pop(context);
      SnackHelper.success(context, 'Reserva confirmada!');
    } on Exception catch (e, s) {
      final str = e.toString();
      if (!_isExpectedBookingError(str)) await Sentry.captureException(e, stackTrace: s);
      final msg = _classifyBookingError(str);
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

  // ── Hero block: eyebrow mono date + Anton 88px hour + mono price ──────────
  Widget _buildHeroBlock() {
    final slotDate = DateTime.parse(widget.viewModel.dateString);
    final eyebrow = DateFormat('E, d MMM', 'pt_BR')
        .format(slotDate)
        .toUpperCase(); // "QUA, 28 MAI"
    final timeDisplay = widget.viewModel.slot.startTime; // "18:00"
    final priceDisplay = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(widget.viewModel.slot.price); // "R$ 50,00"

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
        const SizedBox(height: 8),
        Text(timeDisplay, style: AppTheme.display(size: 88, color: AppTheme.ink)),
        const SizedBox(height: 8),
        Text(priceDisplay, style: AppTheme.mono(size: 16, color: AppTheme.concrete)),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.lineHair, height: 1, thickness: 0.5),
      ],
    );
  }

  // ── Approval banner: 2px orange left stripe, no colored background ────────
  Widget _buildApprovalBanner() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 2, color: AppTheme.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Esta reserva será confirmada após aprovação do estabelecimento.',
                style: AppTheme.ui(size: 13, color: AppTheme.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hero block — BOOK-07: Anton 88px hour as primary visual element
            _buildHeroBlock(),
            const SizedBox(height: 16),

            // Approval banner — BOOK-08: 2px orange left stripe, no colored background
            if (_requiresConfirmation && !widget.pixEnabled) ...[
              _buildApprovalBanner(),
              const SizedBox(height: 16),
            ],

            // Recurrence toggle — D-11: Switch uses AppTheme.lightTheme.switchTheme (no activeThumbColor)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reservar semanalmente', style: AppTheme.ui(size: 15)),
                Switch(
                  value: _isRecurrent,
                  onChanged: (v) => setState(() => _isRecurrent = v),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Animated recurrence section (unchanged)
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

            // Participants TextField — D-10: UnderlineInputBorder via theme (no explicit border overrides)
            TextField(
              controller: _participantsController,
              decoration: const InputDecoration(
                labelText: 'QUEM VAI JOGAR?',
                hintText: 'Ex: João, Maria, Pedro',
                // No border: — theme applies UnderlineInputBorder automatically
              ),
              maxLength: 200,
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),

            // Sport dropdown — D-10: UnderlineInputBorder via theme (no explicit border overrides)
            // WR-06: null sport is intentional — "Não informado" is a valid selection
            // passed as-is to bookSlot; downstream accepts null sport.
            if (widget.sports.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedSport,
                decoration: const InputDecoration(
                  labelText: 'ESPORTE',
                  // No border: — theme applies UnderlineInputBorder automatically
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Não informado'),
                  ),
                  ...widget.sports.map(
                    (s) => DropdownMenuItem<String?>(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedSport = v),
              ),
            ],

            // Error message (unchanged)
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTheme.ui(size: 13, color: AppTheme.orangeDk),
              ),
            ],
            const SizedBox(height: 24),

            // Action buttons — BOOK-09: SportBtn for all payment/confirm actions
            if (!_isRecurrent) ...[
              if (widget.pixEnabled) ...[
                Text('Como você prefere pagar?', style: AppTheme.ui(size: 15)),
                const SizedBox(height: 12),
                SportBtn.filled(
                  'PAGAR COM PIX',
                  onPressed: _isSubmitting ? null : _handlePayPix,
                ),
                const SizedBox(height: 10),
                SportBtn.outlined(
                  'PAGAR NA HORA',
                  onPressed: _isSubmitting ? null : _handlePayOnArrival,
                ),
              ] else ...[
                if (_isSubmitting)
                  const Center(child: CircularProgressIndicator())
                else
                  SportBtn.filled(
                    'CONFIRMAR RESERVA',
                    onPressed: _handlePayOnArrival,
                  ),
              ],
            ] else ...[
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                SportBtn.filled(
                  _availableRecurrenceEntries.isEmpty
                      ? 'RESERVAR SEMANALMENTE'
                      : 'RESERVAR ${_availableRecurrenceEntries.length} RESERVA${_availableRecurrenceEntries.length != 1 ? "S" : ""}',
                  onPressed: _handleConfirmRecurring,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
