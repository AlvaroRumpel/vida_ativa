import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/core/utils/snack_helper.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';

const _kGoogleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

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
    SnackHelper.info(context, 'Email de recuperação enviado. Verifique sua caixa de entrada.');
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
                          OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => context.read<AuthCubit>().signInWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF3C4043),
                              side: const BorderSide(color: Color(0xFFDADADA)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 1,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.string(
                                  _kGoogleLogoSvg,
                                  width: 18,
                                  height: 18,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Entrar com Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3C4043),
                                    letterSpacing: 0.25,
                                  ),
                                ),
                              ],
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
