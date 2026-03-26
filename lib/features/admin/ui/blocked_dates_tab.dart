import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';

import 'package:vida_ativa/core/models/blocked_date_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_blocked_date_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_blocked_date_state.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

class BlockedDatesTab extends StatelessWidget {
  const BlockedDatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBlockedDateCubit, AdminBlockedDateState>(
      builder: (context, state) {
        return switch (state) {
          AdminBlockedDateInitial() =>
            const Center(child: CircularProgressIndicator()),
          AdminBlockedDateError(:final message) => Center(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          AdminBlockedDateLoaded(:final dates) => _BlockedDatesList(dates: dates),
        };
      },
    );
  }
}

class _BlockedDatesList extends StatelessWidget {
  final List<BlockedDateModel> dates;

  const _BlockedDatesList({required this.dates});

  String _formatDate(String dateString) {
    final parsed = DateTime.parse(dateString);
    final formatted =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(parsed);
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  Future<void> _addBlockedDate(BuildContext context) async {
    final cubit = context.read<AdminBlockedDateCubit>();
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final adminUid = authState.user.uid;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;
    final dateString =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    await cubit.blockDate(dateString, adminUid);
  }

  Future<void> _confirmUnblock(
      BuildContext context, BlockedDateModel model) async {
    final cubit = context.read<AdminBlockedDateCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desbloquear data?'),
        content: Text('Deseja desbloquear ${_formatDate(model.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nao'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.unblockDate(model.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: dates.isEmpty
          ? const Center(child: Text('Nenhuma data bloqueada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final model = dates[index];
                return ListTile(
                  title: Text(_formatDate(model.date)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmUnblock(context, model),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBlockedDate(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
