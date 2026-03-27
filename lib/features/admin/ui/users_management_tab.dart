import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';

class UsersManagementTab extends StatefulWidget {
  const UsersManagementTab({super.key});

  @override
  State<UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<UsersManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('displayName')
        .get();
    final users = snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
    setState(() {
      _users = users;
      _onSearchChanged(_searchController.text);
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users
              .where((u) =>
                  u.displayName.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _confirmPromote(BuildContext context, UserModel user) async {
    final authCubit = context.read<AuthCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Promover a administrador'),
        content: Text(
          'Promover ${user.displayName} a administrador? Esta acao nao pode ser desfeita pelo app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await authCubit.promoteUser(user.uid);
              await _loadUsers();
              if (context.mounted) {
                SnackHelper.success(context, '${user.displayName} agora é administrador');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar por nome ou email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Nenhum usuario cadastrado'
                            : 'Nenhum usuario encontrado',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final user = _filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(user.displayName),
                          subtitle: Text(user.email),
                          trailing: user.isAdmin
                              ? Chip(
                                  label: const Text('Admin'),
                                  backgroundColor:
                                      AppTheme.primaryGreen.withValues(alpha: 0.2),
                                )
                              : FilledButton(
                                  onPressed: () =>
                                      _confirmPromote(context, user),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                  child: const Text('Promover'),
                                ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
