import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/price_tier_model.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_state.dart';

const _dayLabels = [
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom',
];

class SlotBatchSheet extends StatefulWidget {
  final AdminSlotCubit slotCubit;

  const SlotBatchSheet({super.key, required this.slotCubit});

  @override
  State<SlotBatchSheet> createState() => _SlotBatchSheetState();
}

class _SlotBatchSheetState extends State<SlotBatchSheet> {
  DateTime? _fromDate;
  DateTime? _toDate;
  int _fromHour = 8;
  int _toHour = 17;
  bool _isSubmitting = false;
  String? _error;

  static final _dateFmt = DateFormat('dd/MM/yyyy (EEE)', 'pt_BR');

  /// Returns unique weekdays (1=Mon…7=Sun) covered by [_fromDate]..[_toDate].
  /// Used only for the informational chips display.
  Set<int> _derivedDays() {
    if (_fromDate == null || _toDate == null) return {};
    if (_toDate!.isBefore(_fromDate!)) return {};
    final days = <int>{};
    var current = _fromDate!;
    while (!current.isAfter(_toDate!)) {
      days.add(current.weekday);
      current = current.add(const Duration(days: 1));
      if (days.length == 7) break;
    }
    return days;
  }

  String _toDateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns all date-specific slots to be created.
  List<({String date, String startTime, double? price})> _allSlots(
      List<PriceTierModel> tiers) {
    if (_fromDate == null || _toDate == null) return [];
    if (_toDate!.isBefore(_fromDate!) || _fromHour >= _toHour) return [];
    final result = <({String date, String startTime, double? price})>[];
    var current = _fromDate!;
    while (!current.isAfter(_toDate!)) {
      for (int h = _fromHour; h < _toHour; h++) {
        final st = '${h.toString().padLeft(2, '0')}:00';
        result.add((
          date: _toDateString(current),
          startTime: st,
          price: _priceFor(h, current.weekday, tiers),
        ));
      }
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_fromDate ?? now)
        : (_toDate ?? _fromDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        // If toDate is now before fromDate, reset it
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
      } else {
        _toDate = picked;
      }
    });
  }

  double? _priceFor(int hour, int dayOfWeek, List<PriceTierModel> tiers) {
    final matches = tiers.where((t) {
      final dayOk = t.daysOfWeek.isEmpty || t.daysOfWeek.contains(dayOfWeek);
      return dayOk && hour >= t.fromHour && hour < t.toHour;
    });
    if (matches.isEmpty) return null;
    return matches.map((t) => t.price).reduce(max);
  }

  /// Groups _allSlots by weekday for the preview display.
  Map<int, List<({String startTime, double? price})>> _preview(
      List<PriceTierModel> tiers) {
    final slots = _allSlots(tiers);
    if (slots.isEmpty) return {};
    final result = <int, List<({String startTime, double? price})>>{};
    for (final s in slots) {
      final dow = DateTime.parse(s.date).weekday;
      (result[dow] ??= []).add((startTime: s.startTime, price: s.price));
    }
    // Remove duplicates per dow (same startTime shown once)
    for (final dow in result.keys) {
      final seen = <String>{};
      result[dow] = result[dow]!.where((s) => seen.add(s.startTime)).toList();
    }
    return Map.fromEntries(result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Future<void> _create(List<PriceTierModel> tiers) async {
    if (_fromDate == null || _toDate == null) {
      setState(() => _error = 'Selecione um intervalo de datas válido.');
      return;
    }
    if (_fromHour >= _toHour) {
      setState(() => _error = 'Intervalo de horas inválido.');
      return;
    }
    final slots = _allSlots(tiers);
    if (slots.isEmpty) {
      setState(() => _error = 'Selecione um intervalo de datas válido.');
      return;
    }
    if (slots.any((s) => s.price == null)) {
      setState(() =>
          _error = 'Nenhuma faixa de preço cobre todos os horários selecionados.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final created = await widget.slotCubit.createBatchSlots(
        slots.map((s) => (date: s.date, startTime: s.startTime, price: s.price!)).toList(),
      );
      final skipped = slots.length - created;
      if (mounted) {
        Navigator.pop(context);
        SnackHelper.success(
          context,
          skipped > 0
              ? '$created slots criados, $skipped já existiam.'
              : '$created slots criados.',
        );
      }
    } catch (_) {
      setState(() {
        _error = 'Erro ao criar slots. Tente novamente.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return BlocBuilder<PricingCubit, PricingState>(
      builder: (context, state) {
        final tiers =
            state is PricingLoaded ? state.tiers : <PriceTierModel>[];
        final allSlots = _allSlots(tiers);
        final preview = _preview(tiers);
        final derivedDays = _derivedDays();
        final hasNullPrice = allSlots.any((s) => s.price == null);
        final totalSlots = allSlots.length;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Adicionar slots em lote',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),

                // Date range pickers
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerButton(
                        label: 'De',
                        date: _fromDate,
                        formatter: _dateFmt,
                        onTap: () => _pickDate(isFrom: true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('→'),
                    ),
                    Expanded(
                      child: _DatePickerButton(
                        label: 'Até',
                        date: _toDate,
                        formatter: _dateFmt,
                        onTap: () => _pickDate(isFrom: false),
                      ),
                    ),
                  ],
                ),

                // Derived weekdays chips (read-only, informational)
                if (derivedDays.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 4,
                    children: (derivedDays.toList()..sort()).map((dow) {
                      return Chip(
                        label: Text(_dayLabels[dow - 1],
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                        backgroundColor: AppTheme.primaryGreen,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Hour range
                Row(
                  children: [
                    Expanded(
                      child: _HourDropdown(
                        label: 'Das',
                        value: _fromHour,
                        max: 23,
                        onChanged: (v) => setState(() => _fromHour = v),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('→'),
                    ),
                    Expanded(
                      child: _HourDropdown(
                        label: 'Até',
                        value: _toHour,
                        max: 24,
                        onChanged: (v) => setState(() => _toHour = v),
                      ),
                    ),
                  ],
                ),

                // Preview grouped by day
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Preview — $totalSlots slot(s)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...preview.entries.map((entry) {
                    final dow = entry.key;
                    final slots = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 2),
                          child: Text(
                            _dayLabels[dow - 1],
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: slots.map((s) {
                            final label = s.price != null
                                ? '${s.startTime} · ${currency.format(s.price)}'
                                : '${s.startTime} · sem preço';
                            return Chip(
                              label: Text(label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        s.price == null ? Colors.red : null,
                                  )),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),
                  if (hasNullPrice)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Configure faixas de preço na aba "Preços" para cobrir todos os horários.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: AppSpacing.md),

                FilledButton(
                  onPressed: (_isSubmitting || hasNullPrice || totalSlots == 0)
                      ? null
                      : () => _create(tiers),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(totalSlots > 0
                          ? 'Criar $totalSlots slots'
                          : 'Criar slots'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          date != null ? formatter.format(date!) : '—',
          style: TextStyle(
            fontSize: 13,
            color: date != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _HourDropdown({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          items: List.generate(
            max + 1,
            (i) => DropdownMenuItem(
              value: i,
              child: Text('${i.toString().padLeft(2, '0')}:00'),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
