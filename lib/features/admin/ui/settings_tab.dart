import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/core/widgets/sport_btn.dart';
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
              child: Text(message, style: AppTheme.ui(color: AppTheme.orangeDk)),
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
    final credentialsConfigured =
        state.isAccessTokenConfigured && state.isWebhookSecretConfigured;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
      children: [
        // ── 1. Pix Section ─────────────────────────────────────
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.line, width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAGAMENTO',
                        style: AppTheme.mono(size: 9.5, color: AppTheme.concrete),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PIX ATIVO',
                        style: AppTheme.display(size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        !credentialsConfigured
                            ? 'Configure as credenciais abaixo'
                            : state.pixEnabled
                                ? 'Usuários podem pagar com Pix'
                                : 'Apenas pagamento na hora',
                        style: AppTheme.ui(
                          size: 12.5,
                          color: AppTheme.concrete,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: state.pixEnabled,
                  onChanged: credentialsConfigured
                      ? (v) => context.read<SettingsCubit>().setPixEnabled(v)
                      : null,
                ),
              ],
            ),
          ),
        ),

        // ── 2. Mercado Pago Section ─────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MERCADO PAGO',
                    style: AppTheme.mono(size: 10, color: AppTheme.concrete),
                  ),
                  if (state.isAccessTokenConfigured &&
                      state.isWebhookSecretConfigured)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 11, color: AppTheme.court),
                        const SizedBox(width: 6),
                        Text(
                          'CONECTADO',
                          style: AppTheme.mono(size: 10, color: AppTheme.court),
                        ),
                      ],
                    ),
                ],
              ),

              // Access Token field
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCESS TOKEN',
                    style: AppTheme.mono(size: 10, color: AppTheme.concrete),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: ValueKey(_showAccessToken),
                          controller: _accessTokenController,
                          obscureText: !_showAccessToken,
                          style: AppTheme.mono(size: 14, color: AppTheme.ink),
                          decoration: InputDecoration(
                            hintText: state.isAccessTokenConfigured
                                ? '••••••••••••••••'
                                : 'Cole o Access Token',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (state.isAccessTokenConfigured)
                        const Icon(
                          Icons.check,
                          size: 14,
                          color: AppTheme.court,
                        ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => _showAccessToken = !_showAccessToken),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _showAccessToken
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 14,
                            color: AppTheme.concrete,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Webhook Secret field
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEBHOOK SECRET',
                    style: AppTheme.mono(size: 10, color: AppTheme.concrete),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: ValueKey(_showWebhookSecret),
                          controller: _webhookSecretController,
                          obscureText: !_showWebhookSecret,
                          style: AppTheme.mono(size: 14, color: AppTheme.ink),
                          decoration: InputDecoration(
                            hintText: state.isWebhookSecretConfigured
                                ? '••••••••••••••••'
                                : 'Cole o Webhook Secret',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (state.isWebhookSecretConfigured)
                        const Icon(
                          Icons.check,
                          size: 14,
                          color: AppTheme.court,
                        ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(
                            () => _showWebhookSecret = !_showWebhookSecret),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _showWebhookSecret
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 14,
                            color: AppTheme.concrete,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Salvar credenciais button
              const SizedBox(height: 18),
              SportBtn.outlined(
                'SALVAR CREDENCIAIS',
                onPressed: _isSaving ? null : _saveCredentials,
              ),
            ],
          ),
        ),

        // ── 3. Status Section ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.line, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS',
                    style: AppTheme.mono(size: 9.5, color: AppTheme.concrete),
                  ),
                  const SizedBox(height: 10),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: IntrinsicColumnWidth(),
                    },
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Última verificação',
                              style: AppTheme.ui(size: 13),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '—',
                              style: AppTheme.mono(
                                size: 12,
                                color: AppTheme.ink,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(
                            'Modo',
                            style: AppTheme.ui(size: 13),
                          ),
                          Text(
                            'PRODUÇÃO',
                            style: AppTheme.mono(
                              size: 12,
                              color: AppTheme.court,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── 4. Sports Section ───────────────────────────────────
        const _SportsSection(),
      ],
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
  bool _isDirty = false;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _syncFromState(List<String> stateSports) {
    if (!_initialized) {
      _localSports = List<String>.from(stateSports);
      _initialized = true;
    } else if (!_isDirty) {
      setState(() => _localSports = List<String>.from(stateSports));
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
      _isDirty = true;
      _localSports = List<String>.from(_localSports)..add(name);
      _addController.clear();
    });
  }

  void _removeSport(String sport) {
    setState(() {
      _isDirty = true;
      _localSports = List<String>.from(_localSports)..remove(sport);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<SportConfigCubit>().saveSports(_localSports);
      if (mounted) {
        _isDirty = false;
        SnackHelper.success(context, 'Esportes salvos.');
      }
    } catch (_) {
      if (mounted) {
        SnackHelper.error(context, 'Erro ao salvar esportes. Tente novamente.');
      }
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
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          SportConfigError(:final message) => Center(
              child: Text(message, style: AppTheme.ui(color: AppTheme.orangeDk)),
            ),
          SportConfigLoaded(:final sports) => () {
              _syncFromState(sports);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Esportes header with top border
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.line, width: 1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 14),
                        child: Text(
                          'ESPORTES',
                          style: AppTheme.mono(
                            size: 9.5,
                            color: AppTheme.concrete,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sport list
                  if (_localSports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhum esporte cadastrado.',
                        style: AppTheme.ui(size: 13, color: AppTheme.concrete),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final sport in _localSports)
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.lineHair,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sport,
                                  style: AppTheme.ui(
                                    size: 14,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                color: AppTheme.concrete,
                                onPressed: () => _removeSport(sport),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.drag_handle,
                                size: 18,
                                color: AppTheme.concrete,
                              ),
                            ],
                          ),
                        ),
                      ),

                  // Add sport field
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          maxLength: 50,
                          style: AppTheme.ui(size: 14),
                          decoration: const InputDecoration(
                            hintText: 'Nome do esporte',
                            counterText: '',
                          ),
                          onSubmitted: (_) => _addSport(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addSport,
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: AppTheme.orange,
                        ),
                      ),
                    ],
                  ),

                  // Adicionar esporte button
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SportBtn.outlined(
                      'ADICIONAR ESPORTE',
                      onPressed: _addSport,
                    ),
                  ),

                  // Salvar esportes button (only when dirty)
                  if (_isDirty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: SportBtn.outlined(
                        'SALVAR ESPORTES',
                        onPressed: _isSaving ? null : _save,
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              );
            }(),
        };
      },
    );
  }
}
