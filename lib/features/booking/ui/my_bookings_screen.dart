import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/widgets/sport_btn.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/cubit/booking_state.dart';
import 'package:vida_ativa/features/booking/ui/client_booking_detail_sheet.dart';
import 'package:vida_ativa/features/booking/ui/hairline_booking_row.dart';
import 'package:vida_ativa/features/booking/ui/pix_payment_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<BookingCubit, BookingState>(
                builder: (context, state) => switch (state) {
                  BookingInitial() || BookingLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  BookingError(:final message) => Center(
                      child: Text(
                        message,
                        style: AppTheme.ui(size: 14, color: AppTheme.orangeDk),
                      ),
                    ),
                  BookingLoaded(:final bookings) =>
                    _buildBookingsList(context, bookings),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('VIDA', style: AppTheme.display(size: 18, color: AppTheme.ink)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ATIVA',
              style: AppTheme.display(size: 18, color: AppTheme.paper),
            ),
          ),
          const Spacer(),
          Text(
            'MINHAS RESERVAS',
            style: AppTheme.mono(size: 11, color: AppTheme.concrete),
          ),
        ],
      ),
    );
  }

  String _heroEyebrow(String bookingDate) {
    final today = DateTime.now();
    final date = DateTime.parse(bookingDate);
    final todayNorm = DateTime(today.year, today.month, today.day);
    final dateNorm = DateTime(date.year, date.month, date.day);
    final diff = dateNorm.difference(todayNorm).inDays;
    if (diff == 0) return 'PRÓXIMO · HOJE';
    if (diff == 1) return 'PRÓXIMO · AMANHÃ';
    final abbr = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'][date.weekday - 1];
    return 'PRÓXIMO · $abbr';
  }

  Widget _buildHeroBlock(BuildContext context, BookingModel booking) {
    final eyebrow = _heroEyebrow(booking.date);
    final timeDisplay = booking.startTime ?? '';
    final dateFormatted = DateFormat('E, d MMM', 'pt_BR')
        .format(DateTime.parse(booking.date))
        .toUpperCase();

    void onTap() {
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
        _showDetailSheet(context, booking, true);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.lineHair, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppTheme.mono(size: 11, color: AppTheme.orange),
              ),
              const SizedBox(height: 4),
              Text(
                timeDisplay,
                style: AppTheme.display(size: 72, color: AppTheme.ink),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormatted,
                style: AppTheme.mono(size: 11, color: AppTheme.concrete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.lineHair, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: AppTheme.mono(size: 10, color: AppTheme.concrete, letterSpacing: 1.6),
        ),
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, List<BookingModel> bookings) {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final upcoming = bookings
        .where((b) => b.date.compareTo(todayString) >= 0 && !b.isCancelled && !b.isRefunded)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final past = bookings
        .where((b) => b.date.compareTo(todayString) < 0 || b.isCancelled || b.isRefunded)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (upcoming.isEmpty && past.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 48, color: AppTheme.concrete),
              const SizedBox(height: 16),
              Text(
                'Nenhuma reserva',
                style: AppTheme.ui(
                    size: 16, weight: FontWeight.w700, color: AppTheme.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Vá para a agenda para reservar um horário.',
                style: AppTheme.ui(size: 14, color: AppTheme.concrete),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SportBtn.outlined(
                'VER AGENDA',
                onPressed: () =>
                    StatefulNavigationShell.of(context).goBranch(0),
              ),
            ],
          ),
        ),
      );
    }

    // Hero = first upcoming booking (BOOK-10)
    final hero = upcoming.isNotEmpty ? upcoming.first : null;
    final remainingUpcoming =
        upcoming.length > 1 ? upcoming.sublist(1) : <BookingModel>[];

    return ListView(
      children: [
        // Hero block (BOOK-10)
        if (hero != null) _buildHeroBlock(context, hero),

        // "EM SEGUIDA" section (BOOK-12, BOOK-11)
        if (remainingUpcoming.isNotEmpty) ...[
          _buildSectionHeader('EM SEGUIDA'),
          ...remainingUpcoming.asMap().entries.map(
                (entry) => HairlineBookingRow(
                  booking: entry.value,
                  bookingCubit: context.read<BookingCubit>(),
                  index: entry.key,
                  isFuture: true,
                ),
              ),
        ],

        // "HISTÓRICO" section (BOOK-12, BOOK-11)
        if (past.isNotEmpty) ...[
          _buildSectionHeader('HISTÓRICO'),
          ...past.asMap().entries.map(
                (entry) => HairlineBookingRow(
                  booking: entry.value,
                  bookingCubit: context.read<BookingCubit>(),
                  index: entry.key,
                  isFuture: false,
                ),
              ),
        ],
      ],
    );
  }

  void _showDetailSheet(
      BuildContext context, BookingModel booking, bool isFuture) {
    final bookingCubit = context.read<BookingCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ClientBookingDetailSheet(
        booking: booking,
        bookingCubit: bookingCubit,
        isFuture: isFuture,
      ),
    );
  }

}
