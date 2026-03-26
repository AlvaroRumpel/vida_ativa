import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';

import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_state.dart';
import 'package:vida_ativa/features/admin/ui/admin_booking_card.dart';

class BookingManagementTab extends StatelessWidget {
  const BookingManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBookingCubit, AdminBookingState>(
      builder: (context, state) {
        return switch (state) {
          AdminBookingInitial() =>
            const Center(child: CircularProgressIndicator()),
          AdminBookingError(:final message) => Center(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          AdminBookingLoaded() => _BookingManagementView(state: state),
        };
      },
    );
  }
}

class _BookingManagementView extends StatelessWidget {
  final AdminBookingLoaded state;

  const _BookingManagementView({required this.state});

  String _formatDate(DateTime date) {
    final formatted = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(date);
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<AdminBookingCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      cubit.selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminBookingCubit>();

    return Column(
      children: [
        // Date selector row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => cubit.selectDate(
                  state.selectedDate.subtract(const Duration(days: 1)),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _pickDate(context),
                  child: Text(
                    _formatDate(state.selectedDate),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => cubit.selectDate(
                  state.selectedDate.add(const Duration(days: 1)),
                ),
              ),
            ],
          ),
        ),
        // Confirmation mode toggle
        SwitchListTile(
          title: const Text('Confirmacao automatica'),
          subtitle: Text(
            state.confirmationMode == 'automatic'
                ? 'Reservas sao confirmadas automaticamente'
                : 'Reservas aguardam aprovacao manual',
          ),
          value: state.confirmationMode == 'automatic',
          onChanged: (value) {
            cubit.setConfirmationMode(value ? 'automatic' : 'manual');
          },
        ),
        const Divider(),
        // Bookings list
        Expanded(
          child: state.bookings.isEmpty
              ? const Center(child: Text('Nenhuma reserva para esta data.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: state.bookings.length,
                  itemBuilder: (context, index) {
                    return AdminBookingCard(
                      booking: state.bookings[index],
                      bookingCubit: cubit,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
