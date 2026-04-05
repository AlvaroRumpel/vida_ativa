import 'dart:math';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/ui/booking_confirmation_sheet.dart';
import 'package:vida_ativa/features/booking/ui/client_booking_detail_sheet.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_state.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';
import 'package:vida_ativa/features/schedule/ui/slot_event_tile.dart';

class SlotDayView extends StatefulWidget {
  final ScheduleState state;
  final DateTime selectedDay;

  const SlotDayView({
    super.key,
    required this.state,
    required this.selectedDay,
  });

  @override
  State<SlotDayView> createState() => _SlotDayViewState();
}

class _SlotDayViewState extends State<SlotDayView> {
  late EventController<SlotViewModel> _eventController;
  BookingCubit? _bookingCubit;

  @override
  void initState() {
    super.initState();
    _eventController = EventController<SlotViewModel>();
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  void _updateEvents(List<SlotViewModel> slots, DateTime day) {
    _eventController.removeWhere((_) => true);
    for (final vm in slots) {
      final parts = vm.slot.startTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final start = DateTime(day.year, day.month, day.day, hour, minute);
      final end = start.add(const Duration(hours: 1));
      _eventController.add(
        CalendarEventData<SlotViewModel>(
          date: day,
          startTime: start,
          endTime: end,
          title: vm.slot.startTime,
          color: _colorForStatus(vm.status),
          event: vm,
        ),
      );
    }
  }

  Color _colorForStatus(SlotStatus status) => switch (status) {
        SlotStatus.available => AppTheme.primaryGreen.withValues(alpha: 0.2),
        SlotStatus.booked => Colors.grey.shade200,
        SlotStatus.myBooking => AppTheme.primaryGreen,
        SlotStatus.blocked => const Color(0xFFE53935).withValues(alpha: 0.2),
      };

  int _computeStartHour(List<SlotViewModel> slots) {
    if (slots.isEmpty) return 6;
    final hours = slots.map((vm) => int.parse(vm.slot.startTime.split(':')[0]));
    return (hours.reduce(min) - 1).clamp(0, 23);
  }

  int _computeEndHour(List<SlotViewModel> slots) {
    if (slots.isEmpty) return 22;
    final hours =
        slots.map((vm) => int.parse(vm.slot.startTime.split(':')[0]) + 1);
    return (hours.reduce(max) + 1).clamp(1, 24);
  }

  void _showBookingSheet(SlotViewModel viewModel) {
    final bookingCubit = _bookingCubit;
    if (bookingCubit == null) return;

    if (viewModel.status == SlotStatus.myBooking && viewModel.booking != null) {
      final booking = viewModel.booking!;
      final isFuture = DateTime.parse(booking.date).isAfter(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => ClientBookingDetailSheet(
          booking: booking,
          bookingCubit: bookingCubit,
          isFuture: isFuture,
        ),
      );
      return;
    }

    if (viewModel.status == SlotStatus.booked) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _OccupiedSlotSheet(startTime: viewModel.slot.startTime),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BookingConfirmationSheet(
        viewModel: viewModel,
        bookingCubit: bookingCubit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Capture BookingCubit before building DayView — required by Phase 4 pattern
    // (DayView subtree does not inherit BlocProviders).
    _bookingCubit = context.read<BookingCubit>();

    return switch (widget.state) {
      ScheduleInitial() || ScheduleLoading() => const _TimelineSkeleton(),
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
      ScheduleLoaded(:final slots) => _buildDayView(slots),
    };
  }

  Widget _buildDayView(List<SlotViewModel> slots) {
    // Defer event sync to after this frame so DayView has time to attach the
    // controller and initialize _handledContextLostEvent (calendar_view 2.0.0).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateEvents(slots, widget.selectedDay);
    });
    final startHour = _computeStartHour(slots);
    final endHour = _computeEndHour(slots);

    return DayView<SlotViewModel>(
      key: ValueKey(widget.selectedDay),
      controller: _eventController,
      initialDay: widget.selectedDay,
      startHour: startHour,
      endHour: endHour,
      heightPerMinute: 1.0,
      showLiveTimeLineInAllDays: true,
      backgroundColor: Colors.white,
      dayTitleBuilder: (_) => const SizedBox.shrink(),
      timeStringBuilder: (dt, {secondaryDate}) =>
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      eventTileBuilder: (date, events, boundary, startDuration, endDuration) {
        if (events.isEmpty) return const SizedBox.shrink();
        final vm = events.first.event!;
        final tappable = vm.status == SlotStatus.available ||
            vm.status == SlotStatus.myBooking ||
            vm.status == SlotStatus.booked;
        return SlotEventTile(
          viewModel: vm,
          onTap: tappable ? () => _showBookingSheet(vm) : null,
        );
      },
      onEventTap: (events, date) {
        if (events.isEmpty) return;
        final vm = events.first.event;
        if (vm == null) return;
        final tappable = vm.status == SlotStatus.available ||
            vm.status == SlotStatus.myBooking ||
            vm.status == SlotStatus.booked;
        if (tappable) _showBookingSheet(vm);
      },
    );
  }
}

/// Private shimmer-style skeleton for the DayView loading state.
/// Adapts the opacity-pulse pattern from SlotSkeleton for a timeline layout.
class _TimelineSkeleton extends StatefulWidget {
  const _TimelineSkeleton();

  @override
  State<_TimelineSkeleton> createState() => _TimelineSkeletonState();
}

class _TimelineSkeletonState extends State<_TimelineSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: List.generate(3, (index) {
              return Opacity(
                opacity: _opacity.value,
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _OccupiedSlotSheet extends StatelessWidget {
  final String startTime;
  const _OccupiedSlotSheet({required this.startTime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            'Horário $startTime',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text('Este horário já está reservado.'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
