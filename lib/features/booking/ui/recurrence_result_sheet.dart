import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';

class RecurrenceResultSheet extends StatelessWidget {
  final List<RecurrenceOutcome> outcomes;
  final VoidCallback onClose; // pops both this sheet AND the confirmation sheet

  const RecurrenceResultSheet({
    super.key,
    required this.outcomes,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final created = outcomes.where((o) => o.success).toList();
    final conflicts = outcomes.where((o) => !o.success).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: AppSpacing.md),

          // Success heading
          Text(
            '${created.length} reserva${created.length != 1 ? 's' : ''} criada${created.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
            ),
          ),

          // Conflicts section
          if (conflicts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${conflicts.length} horário${conflicts.length != 1 ? 's' : ''} não disponível${conflicts.length != 1 ? 'eis' : ''}:',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFB300),
              ),
            ),
            ...conflicts.map((conflict) {
              final formatted = DateFormat("EEE, d 'de' MMM", 'pt_BR')
                  .format(DateTime.parse(conflict.dateString));
              final dateDisplay =
                  '${formatted[0].toUpperCase()}${formatted.substring(1)}';
              final reason = conflict.failureReason == 'slot_already_booked'
                  ? 'Já reservado'
                  : conflict.failureReason == 'slot_already_passed'
                      ? 'Horário passado'
                      : 'Horário não cadastrado';
              return Column(
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.circle_outlined,
                        size: 10,
                        color: Color(0xFF9E9A95),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('$dateDisplay · $reason'),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],

          const SizedBox(height: AppSpacing.lg),

          FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
