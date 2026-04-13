import 'dart:math';

import 'package:calendar_view/calendar_view.dart' hide WeekHeader;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/features/admin/ui/admin_booking_detail_sheet.dart';
import 'package:vida_ativa/features/admin/ui/slot_batch_sheet.dart';
import 'package:vida_ativa/features/admin/ui/slot_form_sheet.dart';
import 'package:vida_ativa/features/schedule/ui/week_header.dart';

const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];


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
  late DateTime _selectedWeekStart;
  late EventController<SlotModel> _controller;
  late AdminSlotCubit _slotCubit;
  late AdminBookingCubit _bookingCubit;
  Set<String> _bookedSlotIds = {};

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _toDateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slotCubit = context.read<AdminSlotCubit>();
    _bookingCubit = context.read<AdminBookingCubit>();
  }

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _getMonday(DateTime.now());
    _controller = EventController<SlotModel>();
    // Defer until after the first frame so DayView has attached the controller
    // before we call add/removeWhere (avoids LateInitializationError on
    // _handledContextLostEvent in calendar_view 2.0.0).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncEvents();
        _loadBookingsForDay();
      }
    });
  }

  @override
  void didUpdateWidget(_SlotDayView old) {
    super.didUpdateWidget(old);
    if (old.slots != widget.slots) {
      _syncEvents();
      _loadBookingsForDay();
    }
  }

  Future<void> _loadBookingsForDay() async {
    final dateStr = _toDateString(_refDate(_selectedDayOfWeek));
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('date', isEqualTo: dateStr)
        .get();
    if (!mounted) return;
    final booked = snap.docs
        .where((d) {
          final status = d['status'] as String;
          return status != 'cancelled' && status != 'rejected' && status != 'refunded';
        })
        .map((d) => d['slotId'] as String)
        .toSet();
    setState(() => _bookedSlotIds = booked);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _refDate(int dayOfWeek) =>
      _selectedWeekStart.add(Duration(days: dayOfWeek - 1));

  void _syncEvents() {
    _controller.removeWhere((_) => true);
    for (final slot in widget.slots) {
      final parts = slot.date.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final timeParts = slot.startTime.split(':');
      final start = DateTime(date.year, date.month, date.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]));
      _controller.add(CalendarEventData<SlotModel>(
        date: date,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        title: slot.startTime,
        color: slot.isActive ? AppTheme.primaryGreen : Colors.grey.shade400,
        event: slot,
      ));
    }
  }

  Future<void> _openSheet(SlotModel? existing) async {
    if (existing != null) {
      final docId = BookingModel.generateId(existing.id, existing.date);
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .get();
      if (!mounted) return;
      if (snap.exists) {
        final booking = BookingModel.fromFirestore(snap);
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => AdminBookingDetailSheet(
            booking: booking,
            adminBookingCubit: _bookingCubit,
          ),
        );
        if (mounted) _loadBookingsForDay();
        return;
      }
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SlotFormSheet(
        existing: existing,
        slotCubit: _slotCubit,
        initialDate: existing == null ? _refDate(_selectedDayOfWeek) : null,
      ),
    );
  }

  void _openBatchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<PricingCubit>(),
        child: SlotBatchSheet(slotCubit: _slotCubit),
      ),
    );
  }

  void _onPreviousWeek() {
    setState(() {
      _selectedWeekStart =
          _selectedWeekStart.subtract(const Duration(days: 7));
    });
    _slotCubit.loadSlotsForWeek(_selectedWeekStart);
  }

  void _onNextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
    _slotCubit.loadSlotsForWeek(_selectedWeekStart);
  }

  int _startHour() {
    final selectedDate = _toDateString(_refDate(_selectedDayOfWeek));
    final times = widget.slots
        .where((s) => s.date == selectedDate)
        .map((s) => int.parse(s.startTime.split(':')[0]));
    if (times.isEmpty) return 8;
    return (times.reduce(min) - 1).clamp(0, 23);
  }

  int _endHour() {
    final selectedDate = _toDateString(_refDate(_selectedDayOfWeek));
    final times = widget.slots
        .where((s) => s.date == selectedDate)
        .map((s) => int.parse(s.startTime.split(':')[0]) + 1);
    if (times.isEmpty) return 22;
    return (times.reduce(max) + 1).clamp(1, 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WeekHeader(
            weekStart: _selectedWeekStart,
            onPreviousWeek: _onPreviousWeek,
            onNextWeek: _onNextWeek,
          ),
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
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _dayLabels[i],
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          _refDate(dow).day.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
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
                    onSelected: (_) {
                      setState(() => _selectedDayOfWeek = dow);
                      _loadBookingsForDay();
                    },
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
                  isBooked: _bookedSlotIds.contains(slot.id),
                  onTap: () => _openSheet(slot),
                );
              },
              onEventTap: (events, date) {
                if (events.isEmpty) return;
                final slot = events.first.event;
                if (slot != null) _openSheet(slot);
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
            onPressed: () => _openSheet(null),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _AdminSlotTile extends StatelessWidget {
  final SlotModel slot;
  final bool isBooked;
  final VoidCallback onTap;

  const _AdminSlotTile({
    required this.slot,
    required this.isBooked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (isBooked) {
      color = const Color(0xFFB87333);
    } else {
      color = slot.isActive ? AppTheme.primaryGreen : Colors.grey.shade500;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isBooked ? 0.18 : 0.12),
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
                    isBooked
                        ? 'Reservado'
                        : NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                            .format(slot.price),
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
            if (isBooked)
              Icon(Icons.person, size: 18, color: color)
            else
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
