import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/admin/cubit/settings_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/settings_state.dart';
import 'package:vida_ativa/features/admin/cubit/sport_config_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/sport_config_state.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return switch (state) {
          SettingsInitial() =>
            const Center(child: CircularProgressIndicator()),
          SettingsError(:final message) => Center(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          SettingsLoaded() => _SettingsForm(state: state),
        };
      },
    );
  }
}

class _SettingsForm extends StatefulWidget {
  final SettingsLoaded state;

  const _SettingsForm({required this.state});

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final TextEditingController _accessTokenController;
  late final TextEditingController _webhookSecretController;
  bool _showAccessToken = false;
  bool _showWebhookSecret = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _accessTokenController = TextEditingController();
    _webhookSecretController = TextEditingController();
  }

  @override
  void dispose() {
    _accessTokenController.dispose();
    _webhookSecretController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    setState(() => _isSaving = true);
    try {
      await context.read<SettingsCubit>().saveCredentials(
            accessToken: _accessTokenController.text,
            webhookSecret: _webhookSecretController.text,
          );
      if (mounted) {
        SnackHelper.success(context, 'Credenciais salvas.');
        _accessTokenController.clear();
        _webhookSecretController.clear();
      }
    } catch (e) {
      if (mounted) SnackHelper.error(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Pix section
          Text('Pix', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Builder(builder: (context) {
            final credentialsConfigured = state.isAccessTokenConfigured &&
                state.isWebhookSecretConfigured;
            return SwitchListTile(
              title: const Text('Pagamento Pix'),
              subtitle: Text(
                !credentialsConfigured
                    ? 'Configure as credenciais abaixo primeiro'
                    : state.pixEnabled
                        ? 'Usuários podem pagar com Pix'
                        : 'Apenas pagamento na hora',
              ),
              value: state.pixEnabled,
              onChanged: credentialsConfigured
                  ? (v) => context.read<SettingsCubit>().setPixEnabled(v)
                  : null,
            );
          }),

          const SizedBox(height: AppSpacing.lg),
          const Divider(),

          Text('Mercado Pago', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          // Access Token field
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _accessTokenController,
                  obscureText: !_showAccessToken,
                  decoration: InputDecoration(
                    labelText: 'Access Token',
                    hintText: state.isAccessTokenConfigured
                        ? '••••••••••••••••'
                        : 'Cole o Access Token de produção',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showAccessToken
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showAccessToken = !_showAccessToken),
                    ),
                  ),
                ),
              ),
              if (state.isAccessTokenConfigured) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Webhook Secret field
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _webhookSecretController,
                  obscureText: !_showWebhookSecret,
                  decoration: InputDecoration(
                    labelText: 'Webhook Secret',
                    hintText: state.isWebhookSecretConfigured
                        ? '••••••••••••••••'
                        : 'Cole o Webhook Secret',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showWebhookSecret
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                          () => _showWebhookSecret = !_showWebhookSecret),
                    ),
                  ),
                ),
              ),
              if (state.isWebhookSecretConfigured) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          FilledButton(
            onPressed: _isSaving ? null : _saveCredentials,
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Salvar Credenciais'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          Text('Esportes', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const _SportsSection(),
        ],
      ),
    );
  }
}

class _SportsSection extends StatefulWidget {
  const _SportsSection();

  @override
  State<_SportsSection> createState() => _SportsSectionState();
}

class _SportsSectionState extends State<_SportsSection> {
  final TextEditingController _addController = TextEditingController();
  List<String> _localSports = const <String>[];
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _syncFromState(List<String> stateSports) {
    if (!_initialized) {
      _localSports = List<String>.from(stateSports);
      _initialized = true;
    }
  }

  void _addSport() {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    if (_localSports.contains(name)) {
      SnackHelper.error(context, 'Esporte já existe.');
      return;
    }
    if (name.length > 50) {
      SnackHelper.error(context, 'Nome muito longo (máx 50 caracteres).');
      return;
    }
    setState(() {
      _localSports = List<String>.from(_localSports)..add(name);
      _addController.clear();
    });
  }

  void _removeSport(String sport) {
    setState(() => _localSports = List<String>.from(_localSports)..remove(sport));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final updated = List<String>.from(_localSports);
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _localSports = updated;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<SportConfigCubit>().saveSports(_localSports);
      if (mounted) SnackHelper.success(context, 'Esportes salvos.');
    } catch (_) {
      if (mounted) SnackHelper.error(context, 'Erro ao salvar esportes. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SportConfigCubit, SportConfigState>(
      builder: (context, state) {
        return switch (state) {
          SportConfigInitial() => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          SportConfigError(:final message) => Center(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          SportConfigLoaded(:final sports) => () {
              _syncFromState(sports);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_localSports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        'Nenhum esporte cadastrado. Adicione um acima.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: _reorder,
                      children: [
                        for (final sport in _localSports)
                          ListTile(
                            key: ValueKey('sport_$sport'),
                            title: Text(sport),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  tooltip: 'Remover esporte',
                                  onPressed: () => _removeSport(sport),
                                ),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          maxLength: 50,
                          decoration: const InputDecoration(
                            hintText: 'Nome do esporte',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _addSport(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: AppTheme.primaryGreen,
                        tooltip: 'Adicionar esporte',
                        onPressed: _addSport,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Salvar Esportes'),
                  ),
                ],
              );
            }(),
        };
      },
    );
  }
}
