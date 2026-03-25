import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/phone_input_formatter.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleAuthError(String message) {
    final msg = message.toLowerCase();
    setState(() {
      if (msg.contains('email') || msg.contains('cadastrado') || msg.contains('inválido')) {
        _emailError = message;
        _passwordError = null;
      } else if (msg.contains('senha') || msg.contains('fraca')) {
        _passwordError = message;
        _emailError = null;
      } else {
        _emailError = null;
        _passwordError = message;
      }
    });
  }

  void _onRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phone = _phoneController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Informe seu nome' : null;
      _emailError = email.isEmpty ? 'Informe o email' : null;
      _passwordError = password.length < 6 ? 'Mínimo 6 caracteres' : null;
      _confirmError = password != confirmPassword ? 'Senhas não conferem' : null;
    });

    if (name.isEmpty || email.isEmpty || password.length < 6 || password != confirmPassword) {
      return;
    }

    context.read<AuthCubit>().registerWithEmailPassword(
          name: name,
          email: email,
          password: password,
          phone: phone.isEmpty ? null : phone,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Criar conta'),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _handleAuthError(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: InputDecoration(
                            labelText: 'Nome completo',
                            errorText: _nameError,
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            errorText: _emailError,
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            errorText: _passwordError,
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm password field
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            errorText: _confirmError,
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Phone field (optional)
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [PhoneInputFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Celular (opcional)',
                            hintText: '(11) 99999-9999',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Register button
                        FilledButton(
                          onPressed: isLoading ? null : _onRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Criar conta'),
                        ),

                        const SizedBox(height: 16),

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Já tem conta?'),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Entrar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
