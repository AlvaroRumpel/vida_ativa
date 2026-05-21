import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';

/// Dashboard tab for admin panel.
/// Full implementation in Plan 22-02.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Full implementation coming in Plan 22-02.
        return const SizedBox.shrink();
      },
    );
  }
}
