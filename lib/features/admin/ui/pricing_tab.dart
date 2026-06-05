import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/price_tier_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/widgets/sport_btn.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_state.dart';

// ── Day abbreviations (uppercase, for display) ───────────────────────────────
const _dayAbbrevUp = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

/// Converts daysOfWeek list to a readable label.
String _daysLabel(List<int> days) {
  if (days.isEmpty || days.length == 7) { return 'TODOS'; }
  final sorted = [...days]..sort();
  if (sorted.length == 5 && sorted.every((d) => d >= 1 && d <= 5) &&
      sorted.join() == '12345') { return 'SEG–SEX'; }
  if (sorted.length == 2 && sorted[0] == 6 && sorted[1] == 7) { return 'SÁB·DOM'; }
  return sorted.map((d) => _dayAbbrevUp[d - 1]).join('·');
}

/// Formats an hour int as HH:00.
String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

// ── PricingTab ────────────────────────────────────────────────────────────────

class PricingTab extends StatelessWidget {
  const PricingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PricingCubit, PricingState>(
      builder: (context, state) {
        return switch (state) {
          PricingInitial() =>
            const Center(child: CircularProgressIndicator()),
          PricingError(:final message) =>
            Center(child: Text(message, style: const TextStyle(color: Colors.red))),
          PricingLoaded(:final tiers) => _PricingEditor(tiers: tiers),
        };
      },
    );
  }
}

// ── _PricingEditor ────────────────────────────────────────────────────────────

class _PricingEditor extends StatefulWidget {
  final List<PriceTierModel> tiers;
  const _PricingEditor({required this.tiers});

  @override
  State<_PricingEditor> createState() => _PricingEditorState();
}

class _PricingEditorState extends State<_PricingEditor> {
  late List<_TierDraft> _drafts;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _drafts = widget.tiers
        .map((t) => _TierDraft(
              daysOfWeek: List<int>.from(t.daysOfWeek),
              fromHour: t.fromHour,
              toHour: t.toHour,
              price: t.price,
            ))
        .toList();
  }

  @override
  void didUpdateWidget(_PricingEditor old) {
    super.didUpdateWidget(old);
    if (old.tiers != widget.tiers) {
      _drafts = widget.tiers
          .map((t) => _TierDraft(
                daysOfWeek: List<int>.from(t.daysOfWeek),
                fromHour: t.fromHour,
                toHour: t.toHour,
                price: t.price,
              ))
          .toList();
    }
  }

  void _addTier() {
    setState(() {
      _drafts.add(_TierDraft(daysOfWeek: [], fromHour: 8, toHour: 17, price: 0));
      _error = null;
    });
  }

  void _removeTier(int index) {
    setState(() => _drafts.removeAt(index));
  }

  /// Opens an inline edit dialog for the tier at [index].
  void _editTier(int index) {
    final draft = _drafts[index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _TierEditSheet(
        draft: draft,
        index: index,
        onSave: (updated) {
          setState(() => _drafts[index] = updated);
          Navigator.of(ctx).pop();
        },
        onRemove: () {
          _removeTier(index);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  String? _validate() {
    for (int i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      if (d.toHour <= d.fromHour) {
        return 'Faixa ${i + 1}: horário de fim deve ser maior que o de início.';
      }
      if (d.price <= 0) {
        return 'Faixa ${i + 1}: preço deve ser maior que zero.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final tiers = _drafts
          .map((d) => PriceTierModel(
                daysOfWeek: d.daysOfWeek,
                fromHour: d.fromHour,
                toHour: d.toHour,
                price: d.price,
              ))
          .toList();
      final updatedCount = await context.read<PricingCubit>().saveTiers(tiers);
      if (mounted) {
        final msg = updatedCount > 0
            ? 'Preços salvos. $updatedCount slot${updatedCount != 1 ? "s" : ""} atualizado${updatedCount != 1 ? "s" : ""}.'
            : 'Preços salvos.';
        SnackHelper.success(context, msg);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _addTierRow() {
    return GestureDetector(
      onTap: _addTier,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.lineHair, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16, color: AppTheme.concrete),
              const SizedBox(width: 10),
              Text(
                'ADICIONAR FAIXA',
                style: AppTheme.mono(size: 10.5, color: AppTheme.concrete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Description
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          child: Text(
            'Faixas por período. Aplica automático no lote — sobreposição prevalece o maior preço.',
            style: AppTheme.ui(size: 12.5, color: AppTheme.concrete),
          ),
        ),
        // Scrollable tier list
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ..._drafts.asMap().entries.map(
                    (e) => _TierDisplayRow(
                      key: ValueKey(e.key),
                      index: e.key,
                      draft: e.value,
                      onTap: () => _editTier(e.key),
                    ),
                  ),
              _addTierRow(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                  child: Text(
                    _error!,
                    style: AppTheme.ui(size: 12, color: AppTheme.orangeDk),
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        // Sticky footer
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.sand,
            border: Border(
              top: BorderSide(color: AppTheme.lineHair, width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
            child: SportBtn.filledInk(
              'SALVAR TABELA',
              onPressed: _isSaving ? null : _save,
            ),
          ),
        ),
      ],
    );
  }
}

// ── _TierDisplayRow ───────────────────────────────────────────────────────────

class _TierDisplayRow extends StatelessWidget {
  final int index;
  final _TierDraft draft;
  final VoidCallback onTap;

  const _TierDisplayRow({
    super.key,
    required this.index,
    required this.draft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tierLabel =
        'FAIXA ${(index + 1).toString().padLeft(2, '0')} · ${_daysLabel(draft.daysOfWeek)}';
    final priceNumber = NumberFormat('#,##0.00', 'pt_BR').format(draft.price);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.lineHair, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + price row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: label + hours
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tierLabel,
                        style: AppTheme.mono(size: 9.5, color: AppTheme.concrete),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _hourLabel(draft.fromHour),
                            style: AppTheme.display(size: 30, color: AppTheme.ink),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '→',
                            style: AppTheme.display(size: 20, color: AppTheme.concrete),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _hourLabel(draft.toHour),
                            style: AppTheme.display(size: 30, color: AppTheme.ink),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Right: price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'R\$',
                        style: AppTheme.mono(size: 14, color: AppTheme.concrete),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        priceNumber,
                        style: AppTheme.display(size: 44, color: AppTheme.ink),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Timeline bar
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final total = constraints.maxWidth;
                  final left = (draft.fromHour / 24) * total;
                  final width =
                      ((draft.toHour - draft.fromHour) / 24) * total;
                  return Stack(
                    children: [
                      Container(height: 3, color: AppTheme.lineHair),
                      Positioned(
                        left: left,
                        width: width,
                        top: 0,
                        bottom: 0,
                        child: Container(color: AppTheme.orange),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _TierDraft ────────────────────────────────────────────────────────────────

class _TierDraft {
  List<int> daysOfWeek;
  int fromHour;
  int toHour;
  double price;

  _TierDraft({
    required this.daysOfWeek,
    required this.fromHour,
    required this.toHour,
    required this.price,
  });

  _TierDraft copyWith({
    List<int>? daysOfWeek,
    int? fromHour,
    int? toHour,
    double? price,
  }) =>
      _TierDraft(
        daysOfWeek: daysOfWeek ?? List<int>.from(this.daysOfWeek),
        fromHour: fromHour ?? this.fromHour,
        toHour: toHour ?? this.toHour,
        price: price ?? this.price,
      );
}

// ── _TierEditSheet ────────────────────────────────────────────────────────────

/// Bottom sheet for editing a pricing tier inline.
/// Opened by tapping a _TierDisplayRow.
class _TierEditSheet extends StatefulWidget {
  final _TierDraft draft;
  final int index;
  final ValueChanged<_TierDraft> onSave;
  final VoidCallback onRemove;

  const _TierEditSheet({
    required this.draft,
    required this.index,
    required this.onSave,
    required this.onRemove,
  });

  @override
  State<_TierEditSheet> createState() => _TierEditSheetState();
}

class _TierEditSheetState extends State<_TierEditSheet> {
  late _TierDraft _draft;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft.copyWith();
    _priceCtrl = TextEditingController(
      text: _draft.price > 0 ? _draft.price.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  static const _dayAbbrevDisplay = [
    'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'
  ];

  @override
  Widget build(BuildContext context) {
    final tierLabel =
        'FAIXA ${(widget.index + 1).toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tierLabel,
                    style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.concrete, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppTheme.lineHair),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hours row
                Row(
                  children: [
                    _HourSelector(
                      label: 'DE',
                      hour: _draft.fromHour,
                      onChanged: (h) => setState(() => _draft = _draft.copyWith(fromHour: h)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('→',
                          style: AppTheme.display(size: 20, color: AppTheme.concrete)),
                    ),
                    _HourSelector(
                      label: 'ATÉ',
                      hour: _draft.toHour,
                      onChanged: (h) => setState(() => _draft = _draft.copyWith(toHour: h)),
                    ),
                    const Spacer(),
                    // Price field
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTheme.display(size: 22, color: AppTheme.ink),
                        decoration: InputDecoration(
                          labelText: 'R\$',
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v.replaceAll(',', '.'));
                          if (parsed != null) {
                            _draft = _draft.copyWith(price: parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Days of week
                Text('DIAS', style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (i) {
                    final dow = i + 1;
                    final selected = _draft.daysOfWeek.contains(dow);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          final updated = selected
                              ? _draft.daysOfWeek.where((d) => d != dow).toList()
                              : [..._draft.daysOfWeek, dow];
                          _draft = _draft.copyWith(daysOfWeek: updated);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.ink : Colors.transparent,
                          border: Border.all(
                            color: selected ? AppTheme.ink : AppTheme.lineHair,
                            width: selected ? 1.5 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _dayAbbrevDisplay[i],
                          style: AppTheme.mono(
                            size: 9.5,
                            color: selected ? AppTheme.paper : AppTheme.concrete,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: SportBtn.filledInk(
                        'SALVAR',
                        onPressed: () => widget.onSave(_draft.copyWith(
                          price: double.tryParse(
                                  _priceCtrl.text.replaceAll(',', '.')) ??
                              _draft.price,
                        )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.orangeDk,
                      onPressed: widget.onRemove,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _HourSelector ─────────────────────────────────────────────────────────────

class _HourSelector extends StatelessWidget {
  final String label;
  final int hour;
  final ValueChanged<int> onChanged;

  const _HourSelector({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
        const SizedBox(height: 4),
        DropdownButton<int>(
          value: hour,
          isDense: true,
          underline: const SizedBox.shrink(),
          style: AppTheme.display(size: 22, color: AppTheme.ink),
          items: List.generate(25, (i) {
            return DropdownMenuItem(
              value: i,
              child: Text('${i.toString().padLeft(2, '0')}:00'),
            );
          }),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
