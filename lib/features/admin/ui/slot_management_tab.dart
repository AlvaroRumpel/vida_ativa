import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/features/admin/ui/admin_booking_detail_sheet.dart';
import 'package:vida_ativa/features/admin/ui/slot_batch_sheet.dart';
import 'package:vida_ativa/features/admin/ui/slot_form_sheet.dart';

// ── Day labels ───────────────────────────────────────────────────────────────
const _dayAbbrevs = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

// ── SlotManagementTab ────────────────────────────────────────────────────────

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

// ── AdminDaySelector ─────────────────────────────────────────────────────────

/// Horizontal day selector with week navigation.
///
/// Shows 7 days for the current week. The selected day gets an orange 2px
/// underline. Left/right chevrons navigate between weeks.
class AdminDaySelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const AdminDaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<AdminDaySelector> createState() => _AdminDaySelectorState();
}

class _AdminDaySelectorState extends State<AdminDaySelector> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getMonday(widget.selectedDate);
  }

  @override
  void didUpdateWidget(AdminDaySelector old) {
    super.didUpdateWidget(old);
    if (_getMonday(widget.selectedDate) != _weekStart) {
      _weekStart = _getMonday(widget.selectedDate);
    }
  }

  DateTime _getMonday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  void _previousWeek() {
    // Compute new week start first so the onDateChanged call is unambiguous
    // and doesn't rely on setState having already mutated _weekStart.
    final newWeekStart = _weekStart.subtract(const Duration(days: 7));
    setState(() => _weekStart = newWeekStart);
    // Keep same day-of-week in new week
    final dayOffset = widget.selectedDate.weekday - 1;
    widget.onDateChanged(newWeekStart.add(Duration(days: dayOffset)));
  }

  void _nextWeek() {
    final newWeekStart = _weekStart.add(const Duration(days: 7));
    setState(() => _weekStart = newWeekStart);
    final dayOffset = widget.selectedDate.weekday - 1;
    widget.onDateChanged(newWeekStart.add(Duration(days: dayOffset)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // ← previous week
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousWeek,
            visualDensity: VisualDensity.compact,
            color: AppTheme.ink,
          ),
          // 7-day row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final day = _weekStart.add(Duration(days: i));
                final isSelected =
                    day.year == widget.selectedDate.year &&
                    day.month == widget.selectedDate.month &&
                    day.day == widget.selectedDate.day;

                return GestureDetector(
                  onTap: () => widget.onDateChanged(day),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dayAbbrevs[i],
                        style: AppTheme.mono(
                          size: 11,
                          color: isSelected ? AppTheme.orange : AppTheme.concrete,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: AppTheme.display(
                          size: 32,
                          color: isSelected ? AppTheme.orange : AppTheme.ink,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 20,
                          height: 2,
                          decoration: const BoxDecoration(
                            color: AppTheme.orange,
                          ),
                        )
                      else
                        const SizedBox(height: 2),
                    ],
                  ),
                );
              }),
            ),
          ),
          // → next week
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextWeek,
            visualDensity: VisualDensity.compact,
            color: AppTheme.ink,
          ),
        ],
      ),
    );
  }
}

// ── SlotRow ──────────────────────────────────────────────────────────────────

/// A single hairline row for an admin slot.
///
/// - Empty slot: price + Switch (active/inactive toggle)
/// - Booked slot: booker name + sport; Switch disabled
class SlotRow extends StatelessWidget {
  final SlotModel slot;
  final bool isBooked;
  final String? bookedByName;
  final String? sport;
  final int index;
  final VoidCallback onTap;
  final ValueChanged<bool>? onSwitchToggle;

  const SlotRow({
    super.key,
    required this.slot,
    required this.isBooked,
    this.bookedByName,
    this.sport,
    required this.index,
    required this.onTap,
    this.onSwitchToggle,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : const Border(
                top: BorderSide(color: AppTheme.lineHair, width: 0.5),
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Time — Anton 32px, orange if booked, ink if empty
              Text(
                slot.startTime,
                style: AppTheme.display(
                  size: 32,
                  color: isBooked ? AppTheme.orange : AppTheme.ink,
                ),
              ),
              const SizedBox(width: 16),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBooked && bookedByName != null)
                      Text(
                        bookedByName!,
                        style: AppTheme.ui(
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                    if (isBooked && sport != null)
                      Text(
                        sport!,
                        style: AppTheme.ui(size: 14, color: AppTheme.concrete),
                      ),
                    if (!isBooked)
                      Text(
                        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                            .format(slot.price),
                        style: AppTheme.ui(size: 14, color: AppTheme.concrete),
                      ),
                  ],
                ),
              ),
              // Switch — disabled when booked
              Switch(
                value: slot.isActive,
                onChanged: isBooked ? null : onSwitchToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _SlotDayView ─────────────────────────────────────────────────────────────

class _SlotDayView extends StatefulWidget {
  final List<SlotModel> slots;
  const _SlotDayView({required this.slots});

  @override
  State<_SlotDayView> createState() => _SlotDayViewState();
}

class _SlotDayViewState extends State<_SlotDayView> {
  late DateTime _selectedDate;
  late AdminSlotCubit _slotCubit;
  late AdminBookingCubit _bookingCubit;
  Set<String> _bookedSlotIds = {};
  Map<String, String> _bookedByNames = {};
  Map<String, String?> _bookedBySports = {};

  DateTime _getMonday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

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
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookingsForDay();
      }
    });
  }

  @override
  void didUpdateWidget(_SlotDayView old) {
    super.didUpdateWidget(old);
    if (old.slots != widget.slots) {
      _loadBookingsForDay();
    }
  }

  Future<void> _loadBookingsForDay() async {
    final dateStr = _toDateString(_selectedDate);
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('date', isEqualTo: dateStr)
        .get();
    if (!mounted) return;
    final booked = <String>{};
    final byNames = <String, String>{};
    final bySports = <String, String?>{};
    for (final doc in snap.docs) {
      final status = doc['status'] as String;
      if (status == 'cancelled' || status == 'rejected' || status == 'refunded') {
        continue;
      }
      final slotId = doc['slotId'] as String;
      booked.add(slotId);
      final name = doc.data()['userDisplayName'] as String?;
      if (name != null) byNames[slotId] = name;
      final sport = doc.data()['sport'] as String?;
      bySports[slotId] = sport;
    }
    setState(() {
      _bookedSlotIds = booked;
      _bookedByNames = byNames;
      _bookedBySports = bySports;
    });
  }

  Future<void> _openSheet(SlotModel? existing) async {
    if (existing != null) {
      // Use _selectedDate (the date visible in the UI), not existing.date
      // (the template date stored on the slot), to avoid missing active bookings
      // when slot.date diverges from the admin-selected date.
      final docId = BookingModel.generateId(existing.id, _toDateString(_selectedDate));
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
        initialDate: existing == null ? _selectedDate : null,
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

  List<SlotModel> get _slotsForSelectedDay {
    final dateStr = _toDateString(_selectedDate);
    return widget.slots
        .where((s) => s.date == dateStr)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    final daySlots = _slotsForSelectedDay;
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: Column(
        children: [
          AdminDaySelector(
            selectedDate: _selectedDate,
            onDateChanged: (d) {
              setState(() => _selectedDate = d);
              _slotCubit.loadSlotsForWeek(_getMonday(d));
              _loadBookingsForDay();
            },
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppTheme.lineHair,
          ),
          Expanded(
            child: daySlots.isEmpty
                ? Center(
                    child: Text(
                      'Sem slots para este dia',
                      style: AppTheme.ui(size: 14, color: AppTheme.concrete),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: daySlots.length,
                    itemBuilder: (context, index) {
                      final slot = daySlots[index];
                      final isBooked = _bookedSlotIds.contains(slot.id);
                      return SlotRow(
                        slot: slot,
                        isBooked: isBooked,
                        bookedByName: _bookedByNames[slot.id],
                        sport: _bookedBySports[slot.id],
                        index: index,
                        onTap: () => _openSheet(slot),
                        onSwitchToggle: (value) =>
                            _slotCubit.setSlotActive(slot.id, value),
                      );
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
