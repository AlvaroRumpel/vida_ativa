import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/core/widgets/sport_btn.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';

class UserDetailSheet extends StatefulWidget {
  final UserModel user;

  const UserDetailSheet({super.key, required this.user});

  @override
  State<UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<UserDetailSheet> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isAdmin = user.isAdmin;
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
    final avatarBg = isAdmin ? AppTheme.orange : AppTheme.ink;
    final actionLabel = isAdmin ? 'REMOVER ADMIN' : 'PROMOVER A ADMIN';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.65,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lineHair,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Avatar grande 64×64 (radius 32)
                CircleAvatar(
                  radius: 32,
                  backgroundColor: avatarBg,
                  child: Text(
                    initial,
                    style: AppTheme.display(size: 32, color: AppTheme.paper),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: AppTheme.ui(size: 14, weight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: AppTheme.mono(size: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Ação
                SportBtn.filled(
                  actionLabel,
                  onPressed:
                      _isSubmitting ? null : () => _handleAction(context, user),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, UserModel user) async {
    final confirmMsg = user.isAdmin
        ? 'Deseja remover privilégios de admin? Ação não pode ser desfeita.'
        : 'Deseja promover ${user.displayName} a admin?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isAdmin ? 'Remover admin' : 'Promover a admin'),
        content: Text(confirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _isSubmitting = true);
    try {
      if (user.isAdmin) {
        // demoteUser não existe em AuthCubit — chamar Firestore diretamente
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'role': 'client'});
      } else {
        await context.read<AuthCubit>().promoteUser(user.uid);
      }
      if (context.mounted) {
        SnackHelper.success(
          context,
          user.isAdmin
              ? '${user.displayName} não é mais admin'
              : '${user.displayName} agora é admin',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        SnackHelper.error(context, 'Erro ao atualizar usuário');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
