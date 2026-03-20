import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';
import 'package:vida_ativa/features/admin/ui/slot_form_sheet.dart';

const _days = [
  'Segunda',
  'Terca',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sabado',
  'Domingo',
];

class SlotManagementTab extends StatelessWidget {
  const SlotManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSlotCubit, AdminSlotState>(
      builder: (context, state) {
        return switch (state) {
          AdminSlotInitial() => const Center(child: CircularProgressIndicator()),
          AdminSlotError(:final message) => Center(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          AdminSlotLoaded(:final slots) => _SlotList(slots: slots),
        };
      },
    );
  }
}

class _SlotList extends StatelessWidget {
  final List<SlotModel> slots;

  const _SlotList({required this.slots});

  void _openSheet(BuildContext context, SlotModel? existing) {
    final cubit = context.read<AdminSlotCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SlotFormSheet(existing: existing, slotCubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: slots.isEmpty
          ? const Center(child: Text('Nenhum slot cadastrado.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                return _SlotCard(
                  slot: slot,
                  onTap: () => _openSheet(context, slot),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final SlotModel slot;
  final VoidCallback onTap;

  const _SlotCard({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceText = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(slot.price);
    final dayName = _days[slot.dayOfWeek - 1];

    return Opacity(
      opacity: slot.isActive ? 1.0 : 0.5,
      child: Card(
        child: ListTile(
          onTap: onTap,
          title: Text('$dayName — ${slot.startTime}'),
          subtitle: Text(priceText),
          trailing: Switch(
            value: slot.isActive,
            onChanged: (value) =>
                context.read<AdminSlotCubit>().setSlotActive(slot.id, value),
          ),
        ),
      ),
    );
  }
}
