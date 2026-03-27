import 'package:flutter/material.dart';

import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';

const _days = [
  'Segunda',
  'Terca',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sabado',
  'Domingo',
];

class SlotFormSheet extends StatefulWidget {
  final SlotModel? existing;
  final AdminSlotCubit slotCubit;

  const SlotFormSheet({
    super.key,
    this.existing,
    required this.slotCubit,
  });

  @override
  State<SlotFormSheet> createState() => _SlotFormSheetState();
}

class _SlotFormSheetState extends State<SlotFormSheet> {
  late int _dayOfWeek;
  late String _startTime;
  late double _price;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _dayOfWeek = existing.dayOfWeek;
      _startTime = existing.startTime;
      _price = existing.price;
    } else {
      _dayOfWeek = 1;
      _startTime = '08:00';
      _price = 0.0;
    }
  }

  Future<void> _pickTime() async {
    final parts = _startTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _startTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      if (existing == null) {
        await widget.slotCubit.createSlot(
          dayOfWeek: _dayOfWeek,
          startTime: _startTime,
          price: _price,
        );
      } else {
        await widget.slotCubit.updateSlot(
          existing.id,
          dayOfWeek: _dayOfWeek,
          startTime: _startTime,
          price: _price,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e == 'slot_already_exists'
            ? 'Já existe um slot neste dia e horário.'
            : 'Erro ao salvar. Tente novamente.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.existing == null;

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
              isCreate ? 'Novo Slot' : 'Editar Slot',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _dayOfWeek,
              decoration: const InputDecoration(labelText: 'Dia da semana'),
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_days[i]),
                ),
              ),
              onChanged: (v) {
                if (v != null) setState(() => _dayOfWeek = v);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text('Horario: $_startTime'),
              onTap: _pickTime,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _price.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preco (R\$)'),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) _price = parsed;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isCreate ? 'Criar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
