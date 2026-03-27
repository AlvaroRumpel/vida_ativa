import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/price_tier_model.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_state.dart';

const _dayAbbrev = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

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
      await context.read<PricingCubit>().saveTiers(tiers);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preços salvos.')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Faixas de preço',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Define o preço por hora conforme o período do dia e dias da semana. '
            'Usado automaticamente na criação em lote. '
            'Se houver sobreposição, o maior preço é aplicado.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._drafts.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return _TierRow(
              key: ValueKey(i),
              draft: d,
              onChanged: (updated) => setState(() => _drafts[i] = updated),
              onRemove: () => _removeTier(i),
              currency: currency,
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _addTier,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar faixa'),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

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

class _TierRow extends StatelessWidget {
  final _TierDraft draft;
  final ValueChanged<_TierDraft> onChanged;
  final VoidCallback onRemove;
  final NumberFormat currency;

  const _TierRow({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // From hour
                _HourPicker(
                  label: 'De',
                  hour: draft.fromHour,
                  onChanged: (h) => onChanged(draft.copyWith(fromHour: h)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('→'),
                ),
                // To hour
                _HourPicker(
                  label: 'Até',
                  hour: draft.toHour,
                  onChanged: (h) => onChanged(draft.copyWith(toHour: h)),
                ),
                const SizedBox(width: 12),
                // Price
                Expanded(
                  child: TextFormField(
                    initialValue:
                        draft.price > 0 ? draft.price.toStringAsFixed(2) : '',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'R\$',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed != null) onChanged(draft.copyWith(price: parsed));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Day of week selection
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(7, (i) {
                final dow = i + 1;
                final selected = draft.daysOfWeek.contains(dow);
                return FilterChip(
                  label: Text(_dayAbbrev[i],
                      style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                  ),
                  onSelected: (v) {
                    final updated = v
                        ? [...draft.daysOfWeek, dow]
                        : draft.daysOfWeek
                            .where((d) => d != dow)
                            .toList();
                    onChanged(draft.copyWith(daysOfWeek: updated));
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                );
              }),
            ),
            if (draft.daysOfWeek.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Todos os dias',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HourPicker extends StatelessWidget {
  final String label;
  final int hour;
  final ValueChanged<int> onChanged;

  const _HourPicker({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        DropdownButton<int>(
          value: hour,
          isDense: true,
          underline: const SizedBox.shrink(),
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
