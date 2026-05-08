import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/admin/cubit/settings_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/settings_state.dart';

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

          // Pix section
          Text('Pix', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          SwitchListTile(
            title: const Text('Pagamento Pix'),
            subtitle: Text(
              state.pixEnabled
                  ? 'Usuários podem pagar com Pix'
                  : 'Apenas pagamento na hora',
            ),
            value: state.pixEnabled,
            onChanged: (v) => context.read<SettingsCubit>().setPixEnabled(v),
          ),
        ],
      ),
    );
  }
}
