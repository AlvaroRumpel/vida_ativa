import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';

class RecurrenceSection extends StatefulWidget {
  final String anchorDateString; // "YYYY-MM-DD" — source slot date (NOT repeated in recurrence)
  final int anchorWeekday; // 1=Mon..7=Sun — pre-selected day chip
  final String startTime; // "HH:mm" — same time for all recurring slots
  final double slotPrice; // price for all recurring bookings
  final FirebaseFirestore firestore; // for preview availability checks
  final ValueChanged<List<RecurrenceEntry>> onAvailableEntriesChanged; // called when preview updates

  const RecurrenceSection({
    super.key,
    required this.anchorDateString,
    required this.anchorWeekday,
    required this.startTime,
    required this.slotPrice,
    required this.firestore,
    required this.onAvailableEntriesChanged,
  });

  @override
  State<RecurrenceSection> createState() => _RecurrenceSectionState();
}

class _RecurrenceSectionState extends State<RecurrenceSection> {
  static const List<String> _dayLabels = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'
  ];

  late Set<int> _selectedDays; // 1=Mon..7=Sun
  int _weeks = 4;
  bool _isLoadingPreview = false;
  List<_PreviewItem> _previewItems = [];

  @override
  void initState() {
    super.initState();
    _selectedDays = {widget.anchorWeekday};
    _refreshPreview();
  }

  String _endDateLabel(int weeks) {
    final anchor = DateTime.parse(widget.anchorDateString);
    final endDate = anchor.add(Duration(days: 7 * weeks));
    final dayName = DateFormat('EEE', 'pt_BR').format(endDate);
    final day = endDate.day.toString().padLeft(2, '0');
    final month = DateFormat('MMM', 'pt_BR').format(endDate);
    final dayCap = '${dayName[0].toUpperCase()}${dayName.substring(1)}';
    return '$weeks semana${weeks > 1 ? 's' : ''} (até $dayCap $day/$month)';
  }

  List<String> _generateCandidateDates() {
    final anchor = DateTime.parse(widget.anchorDateString);
    final candidates = <String>[];

    for (int w = 1; w <= _weeks; w++) {
      for (final dow in _selectedDays) {
        final weekStart = anchor.add(Duration(days: 7 * w));
        final daysOffset = (dow - weekStart.weekday + 7) % 7;
        final targetDate = weekStart.add(Duration(days: daysOffset));
        final dateStr =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        candidates.add(dateStr);
      }
    }

    candidates.sort();
    return candidates;
  }

  Future<void> _refreshPreview() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPreview = true;
    });

    final candidates = _generateCandidateDates();
    final results = await Future.wait(
      candidates.map((dateStr) => _checkDate(dateStr)),
    );

    final available = results
        .where((item) => item.status == _PreviewStatus.available)
        .map((item) => RecurrenceEntry(
              slotId: item.slotId!,
              dateString: item.dateString,
              price: widget.slotPrice,
            ))
        .toList();

    if (!mounted) return;
    setState(() {
      _isLoadingPreview = false;
      _previewItems = results;
    });
    widget.onAvailableEntriesChanged(available);
  }

  Future<_PreviewItem> _checkDate(String dateStr) async {
    final slotSnap = await widget.firestore
        .collection('slots')
        .where('date', isEqualTo: dateStr)
        .where('startTime', isEqualTo: widget.startTime)
        .limit(1)
        .get();

    if (slotSnap.docs.isEmpty) {
      return _PreviewItem(
          dateString: dateStr, status: _PreviewStatus.notFound);
    }

    final slotId = slotSnap.docs.first.id;
    final bookingId = BookingModel.generateId(slotId, dateStr);
    final bookingSnap = await widget.firestore
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (bookingSnap.exists) {
      final data = bookingSnap.data();
      final status = data?['status'] as String?;
      if (status != null && status != 'cancelled' && status != 'refunded') {
        return _PreviewItem(
            dateString: dateStr, status: _PreviewStatus.alreadyBooked);
      }
    }

    return _PreviewItem(
        dateString: dateStr,
        status: _PreviewStatus.available,
        slotId: slotId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day chips row
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: List.generate(7, (i) {
            final dow = i + 1; // 1=Mon..7=Sun
            return FilterChip(
              label: Text(_dayLabels[i]),
              selected: _selectedDays.contains(dow),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(dow);
                    _refreshPreview();
                  } else if (_selectedDays.length > 1) {
                    _selectedDays.remove(dow);
                    _refreshPreview();
                  }
                });
              },
            );
          }),
        ),

        const SizedBox(height: AppSpacing.md),

        // Slider + label
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _endDateLabel(_weeks),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: _weeks.toDouble(),
              min: 1,
              max: 52,
              divisions: 51,
              activeColor: AppTheme.primaryGreen,
              onChanged: (v) => setState(() => _weeks = v.round()),
              onChangeEnd: (_) => _refreshPreview(),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Preview list
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: _isLoadingPreview
              ? const Text(
                  'Verificando disponibilidade...',
                  style: TextStyle(color: Color(0xFF9E9A95)),
                )
              : _previewItems.isEmpty
                  ? const Text(
                      'Nenhum horário disponível nas datas selecionadas',
                      style: TextStyle(color: Color(0xFF9E9A95)),
                    )
                  : ListView(
                      shrinkWrap: true,
                      physics: _previewItems.length <= 6
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      children: [
                        ...List.generate(
                          _previewItems.length < 6
                              ? _previewItems.length
                              : 6,
                          (i) => _PreviewDateItem(item: _previewItems[i]),
                        ),
                        if (_previewItems.length > 6)
                          _HiddenItemsSummary(items: _previewItems.sublist(6)),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _PreviewDateItem extends StatelessWidget {
  final _PreviewItem item;
  const _PreviewDateItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat("EEE, d 'de' MMM", 'pt_BR')
        .format(DateTime.parse(item.dateString));
    final dateDisplay = '${formatted[0].toUpperCase()}${formatted.substring(1)}';
    final isAvailable = item.status == _PreviewStatus.available;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: isAvailable
                ? AppTheme.primaryGreen
                : const Color(0xFF9E9A95),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            dateDisplay,
            style: TextStyle(
              color: isAvailable ? null : const Color(0xFF9E9A95),
              fontSize: 14,
            ),
          ),
          if (item.status == _PreviewStatus.alreadyBooked)
            const Text(
              ' · Já reservado',
              style: TextStyle(color: Color(0xFF9E9A95), fontSize: 12),
            ),
          if (item.status == _PreviewStatus.notFound)
            const Text(
              ' · Horário não cadastrado',
              style: TextStyle(color: Color(0xFF9E9A95), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _HiddenItemsSummary extends StatelessWidget {
  final List<_PreviewItem> items;
  const _HiddenItemsSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    final available = items.where((i) => i.status == _PreviewStatus.available).length;
    final unavailable = items.length - available;
    final parts = <String>[];
    if (available > 0) parts.add('+ $available disponíveis');
    if (unavailable > 0) parts.add('$unavailable sem horário');
    return Text(
      parts.join(' · '),
      style: const TextStyle(color: Color(0xFF9E9A95), fontSize: 12),
    );
  }
}

enum _PreviewStatus { available, alreadyBooked, notFound }

class _PreviewItem {
  final String dateString;
  final _PreviewStatus status;
  final String? slotId; // non-null only for available

  const _PreviewItem({
    required this.dateString,
    required this.status,
    this.slotId,
  });
}
