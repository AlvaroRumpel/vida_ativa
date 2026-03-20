import 'package:flutter/material.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_state.dart';
import 'package:vida_ativa/features/schedule/ui/slot_card.dart';
import 'package:vida_ativa/features/schedule/ui/slot_skeleton.dart';

class SlotList extends StatelessWidget {
  final ScheduleState state;

  const SlotList({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ScheduleInitial() || ScheduleLoading() => const SlotSkeleton(),
      ScheduleError(:final message) => Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ScheduleLoaded(:final isBlocked) when isBlocked => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Dia bloqueado \u2014 sem hor\u00e1rios dispon\u00edveis.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ScheduleLoaded(:final slots) when slots.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nenhum hor\u00e1rio dispon\u00edvel para este dia.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ScheduleLoaded(:final slots) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: slots.length,
          itemBuilder: (context, index) => SlotCard(viewModel: slots[index]),
        ),
    };
  }
}
