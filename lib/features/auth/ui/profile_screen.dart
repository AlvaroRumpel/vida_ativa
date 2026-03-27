import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/phone_input_formatter.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final photoURL = FirebaseAuth.instance.currentUser?.photoURL;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _Avatar(photoURL: photoURL, displayName: user.displayName),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      user.phone ?? 'Sem telefone',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => _showEditPhoneSheet(context, user.phone),
                      child: const Icon(Icons.edit, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                if (user.isAdmin) ...[
                  FilledButton.icon(
                    onPressed: () => GoRouter.of(context).go('/admin'),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Painel Admin'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _showEditPhoneSheet(BuildContext context, String? currentPhone) {
  final controller = TextEditingController(text: currentPhone ?? '');
  final authCubit = context.read<AuthCubit>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Editar telefone',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Celular',
              hintText: '(11) 99999-9999',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () async {
              final phone = controller.text.trim();
              await authCubit.updatePhone(phone.isEmpty ? null : phone);
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Telefone salvo')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

class _Avatar extends StatefulWidget {
  const _Avatar({required this.photoURL, required this.displayName});

  final String? photoURL;
  final String displayName;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _imageError = false;

  @override
  void didUpdateWidget(_Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoURL != widget.photoURL) {
      _imageError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showInitial =
        widget.photoURL == null || _imageError;

    return CircleAvatar(
      radius: 48,
      backgroundColor: AppTheme.primaryGreen,
      child: showInitial
          ? Text(
              widget.displayName.isNotEmpty
                  ? widget.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            )
          : ClipOval(
              child: Image.network(
                widget.photoURL!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _imageError = true);
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
    );
  }
}
