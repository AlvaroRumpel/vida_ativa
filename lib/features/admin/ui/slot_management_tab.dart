import 'dart:math';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/features/admin/ui/slot_batch_sheet.dart';
import 'package:vida_ativa/features/admin/ui/slot_form_sheet.dart';

const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

// Fixed reference week — DayView needs real dates but we suppress the header
final _referenceMonday = DateTime(2024, 1, 1);

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
          AdminSlotLoaded(:final slots) => _SlotDayView(slots: slots),
        };
      },
    );
  }
}

class _SlotDayView extends StatefulWidget {
  final List<SlotModel> slots;
  const _SlotDayView({required this.slots});

  @override
  State<_SlotDayView> createState() => _SlotDayViewState();
}

class _SlotDayViewState extends State<_SlotDayView> {
  int _selectedDayOfWeek = 1;
  late EventController<SlotModel> _controller;

  @override
  void initState() {
    super.initState();
    _controller = EventController<SlotModel>();
    // Defer until after the first frame so DayView has attached the controller
    // before we call add/removeWhere (avoids LateInitializationError on
    // _handledContextLostEvent in calendar_view 2.0.0).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncEvents();
    });
  }

  @override
  void didUpdateWidget(_SlotDayView old) {
    super.didUpdateWidget(old);
    if (old.slots != widget.slots) _syncEvents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _refDate(int dayOfWeek) =>
      _referenceMonday.add(Duration(days: dayOfWeek - 1));

  void _syncEvents() {
    _controller.removeWhere((_) => true);
    for (int dow = 1; dow <= 7; dow++) {
      final ref = _refDate(dow);
      for (final slot in widget.slots.where((s) => s.dayOfWeek == dow)) {
        final parts = slot.startTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final start = DateTime(ref.year, ref.month, ref.day, hour, minute);
        _controller.add(CalendarEventData<SlotModel>(
          date: ref,
          startTime: start,
          endTime: start.add(const Duration(hours: 1)),
          title: slot.startTime,
          color: slot.isActive ? AppTheme.primaryGreen : Colors.grey.shade400,
          event: slot,
        ));
      }
    }
  }

  void _openSheet(BuildContext context, SlotModel? existing) {
    final cubit = context.read<AdminSlotCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SlotFormSheet(existing: existing, slotCubit: cubit),
    );
  }

  void _openBatchSheet(BuildContext context) {
    final cubit = context.read<AdminSlotCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<PricingCubit>(),
        child: SlotBatchSheet(slotCubit: cubit),
      ),
    );
  }

  int _startHour() {
    final times = widget.slots
        .where((s) => s.dayOfWeek == _selectedDayOfWeek)
        .map((s) => int.parse(s.startTime.split(':')[0]));
    if (times.isEmpty) return 8;
    return (times.reduce(min) - 1).clamp(0, 23);
  }

  int _endHour() {
    final times = widget.slots
        .where((s) => s.dayOfWeek == _selectedDayOfWeek)
        .map((s) => int.parse(s.startTime.split(':')[0]) + 1);
    if (times.isEmpty) return 22;
    return (times.reduce(max) + 1).clamp(1, 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: List.generate(7, (i) {
                final dow = i + 1;
                final isSelected = dow == _selectedDayOfWeek;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_dayLabels[i],
                        style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: const Color(0xFFF0EDE8),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: isSelected
                        ? BorderSide.none
                        : const BorderSide(color: Color(0xFFCFC5B0), width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedDayOfWeek = dow),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: DayView<SlotModel>(
              key: ValueKey(_selectedDayOfWeek),
              controller: _controller,
              initialDay: _refDate(_selectedDayOfWeek),
              startHour: _startHour(),
              endHour: _endHour(),
              heightPerMinute: 1.0,
              backgroundColor: Colors.white,
              dayTitleBuilder: (_) => const SizedBox.shrink(),
              timeStringBuilder: (dt, {secondaryDate}) =>
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
              eventTileBuilder:
                  (date, events, boundary, startDuration, endDuration) {
                if (events.isEmpty) return const SizedBox.shrink();
                final slot = events.first.event!;
                return _AdminSlotTile(
                  slot: slot,
                  onTap: () => _openSheet(context, slot),
                );
              },
              onEventTap: (events, date) {
                if (events.isEmpty) return;
                final slot = events.first.event;
                if (slot != null) _openSheet(context, slot);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'batch',
            onPressed: () => _openBatchSheet(context),
            tooltip: 'Adicionar em lote',
            child: const Icon(Icons.playlist_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'single',
            onPressed: () => _openSheet(context, null),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _AdminSlotTile extends StatelessWidget {
  final SlotModel slot;
  final VoidCallback onTap;

  const _AdminSlotTile({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceText =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(slot.price);
    final color = slot.isActive ? AppTheme.primaryGreen : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border(left: BorderSide(color: color, width: 3)),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot.startTime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    priceText,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
            Switch(
              value: slot.isActive,
              onChanged: (value) =>
                  context.read<AdminSlotCubit>().setSlotActive(slot.id, value),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
