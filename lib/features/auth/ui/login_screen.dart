import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  void _handleAuthError(String message) {
    final msg = message.toLowerCase();
    setState(() {
      if (msg.contains('email') || msg.contains('não encontrado') || msg.contains('inválido')) {
        _emailError = message;
        _passwordError = null;
      } else if (msg.contains('senha') || msg.contains('incorretos') || msg.contains('fraca')) {
        _passwordError = message;
        _emailError = null;
      } else {
        _passwordError = message;
        _emailError = null;
      }
    });
  }

  void _onLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Informe o email' : null;
      _passwordError = password.isEmpty ? 'Informe a senha' : null;
    });

    if (email.isEmpty || password.isEmpty) return;

    _clearErrors();
    context.read<AuthCubit>().signInWithEmailPassword(email, password);
  }

  void _onForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Informe o email para recuperar a senha';
      });
      return;
    }
    context.read<AuthCubit>().sendPasswordReset(email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email de recuperação enviado. Verifique sua caixa de entrada.'),
      ),
    );
  }

  static const _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F0E8), Color(0xFFFDFAF5)],
          ),
        ),
        child: BlocConsumer<AuthCubit, AuthState>(
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Branding
                          Image.asset(
                            'assets/images/logo.png',
                            height: 140,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Reserve sua quadra',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF5A5A5A),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),

                          const SizedBox(height: 40),

                          // Google Sign-In button
                          ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => context.read<AuthCubit>().signInWithGoogle(),
                            icon: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            label: const Text('Entrar com Google'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 1,
                              side: const BorderSide(color: Color(0xFFDADADA)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Separator "ou"
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFD0CAC0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ou',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF9E9A95),
                                      ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFD0CAC0))),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Email field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: 'Email',
                              errorText: _emailError,
                              border: _inputBorder,
                              enabledBorder: _inputBorder,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFFC62828)),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Password field
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              errorText: _passwordError,
                              border: _inputBorder,
                              enabledBorder: _inputBorder,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFFC62828)),
                              ),
                            ),
                          ),

                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : _onForgotPassword,
                              child: const Text('Esqueci minha senha'),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // Login button
                          FilledButton(
                            onPressed: isLoading ? null : _onLogin,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                : const Text('Entrar'),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Não tem conta?'),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text('Criar'),
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
      ),
    );
  }
}
