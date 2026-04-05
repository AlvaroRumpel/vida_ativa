import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';

class SlotFormSheet extends StatefulWidget {
  final SlotModel? existing;
  final AdminSlotCubit slotCubit;
  final DateTime? initialDate;

  const SlotFormSheet({
    super.key,
    this.existing,
    required this.slotCubit,
    this.initialDate,
  });

  @override
  State<SlotFormSheet> createState() => _SlotFormSheetState();
}

class _SlotFormSheetState extends State<SlotFormSheet> {
  late DateTime _date;
  late String _startTime;
  late double _price;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final parts = existing.date.split('-');
      _date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      _startTime = existing.startTime;
      _price = existing.price;
    } else {
      _date = widget.initialDate ?? DateTime.now();
      _startTime = '08:00';
      _price = 0.0;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _date = picked);
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

  String _toDateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir slot?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.slotCubit.deleteSlot(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() {
        _error = 'Erro ao excluir. Tente novamente.';
        _isSubmitting = false;
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
      final dateStr = _toDateString(_date);
      if (existing == null) {
        await widget.slotCubit.createSlot(
          date: dateStr,
          startTime: _startTime,
          price: _price,
        );
      } else {
        await widget.slotCubit.updateSlot(
          existing.id,
          date: dateStr,
          startTime: _startTime,
          price: _price,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e == 'slot_already_exists'
            ? 'Já existe um slot nesta data e horário.'
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCreate ? 'Novo Slot' : 'Editar Slot',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!isCreate)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Excluir slot',
                    onPressed: _isSubmitting ? null : _confirmDelete,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_date)}'),
              onTap: _pickDate,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text('Horário: $_startTime'),
              onTap: _pickTime,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _price.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço (R\$)'),
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
