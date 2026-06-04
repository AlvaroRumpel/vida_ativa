import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/ui/user_detail_sheet.dart';
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
                        return UserRow(
                          user: user,
                          index: index,
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => BlocProvider.value(
                              value: context.read<AuthCubit>(),
                              child: UserDetailSheet(user: user),
                            ),
                          ).then((_) => _loadUsers()),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// Public widget exposed for widget testing (ADMN-21).
class UserRow extends StatelessWidget {
  final UserModel user;
  final int index;
  final VoidCallback onTap;

  const UserRow({
    super.key,
    required this.user,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
    final avatarBg = user.isAdmin ? AppTheme.orange : AppTheme.ink;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : const Border(
                top: BorderSide(color: AppTheme.lineHair, width: 0.5),
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarBg,
                child: Text(
                  initial,
                  style: AppTheme.display(size: 20, color: AppTheme.paper),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style:
                          AppTheme.ui(size: 14, weight: FontWeight.w600),
                    ),
                    Text(user.email, style: AppTheme.mono(size: 11)),
                    if (user.isAdmin)
                      Text(
                        'Admin',
                        style: AppTheme.mono(size: 11, color: AppTheme.orange),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.concrete, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
