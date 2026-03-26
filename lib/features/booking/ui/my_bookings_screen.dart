import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/cubit/booking_state.dart';
import 'package:vida_ativa/features/booking/ui/booking_card.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Reservas')),
      body: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) => switch (state) {
          BookingInitial() || BookingLoading() =>
            const Center(child: CircularProgressIndicator()),
          BookingError(:final message) => Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          BookingLoaded(:final bookings) =>
            _buildBookingsList(context, bookings),
        },
      ),
    );
  }

  Widget _buildBookingsList(
      BuildContext context, List<BookingModel> bookings) {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final upcoming = bookings
        .where((b) => b.date.compareTo(todayString) >= 0 && !b.isCancelled)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final past = bookings
        .where((b) => b.date.compareTo(todayString) < 0 || b.isCancelled)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (upcoming.isEmpty && past.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Voce nao tem nenhuma reserva ainda.'),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () =>
                  StatefulNavigationShell.of(context).goBranch(0),
              child: const Text('Ver Agenda'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (upcoming.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Text(
              'Proximas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...upcoming.map(
            (b) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: BookingCard(
                booking: b,
                isFuture: true,
                onCancel: () => _confirmCancel(context, b),
                bookingCubit: context.read<BookingCubit>(),
              ),
            ),
          ),
        ],
        if (past.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Text(
              'Passadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...past.map(
            (b) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: BookingCard(
                booking: b,
                isFuture: false,
                onCancel: null,
                bookingCubit: context.read<BookingCubit>(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _confirmCancel(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar reserva?'),
        content:
            const Text('Tem certeza que deseja cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nao'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<BookingCubit>().cancelBooking(booking.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reserva cancelada.')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erro ao cancelar. Tente novamente.')),
                  );
                }
              }
            },
            child: const Text('Sim', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
