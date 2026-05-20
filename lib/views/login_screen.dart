import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  void _onGoogleSignIn() {
    context.read<AuthBloc>().add(const SignInWithGoogleRequested());
  }

  void _onAnonymousSignIn() {
    final state = context.read<AuthBloc>().state;
    context.read<AuthBloc>().add(const AuthAnonymousSignInRequested());

  }

  void _onPhoneSubmit() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    context.read<AuthBloc>().add(
          AuthPhoneVerificationRequested(phoneNumber: phone),
        );
  }

  void _onSmsCodeSubmit() {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthPhoneCodeSent) return;
    final code = _smsCodeController.text.trim();
    if (code.isEmpty) return;
    context.read<AuthBloc>().add(
          AuthPhoneCodeSubmitted(
            verificationId: state.verificationId,
            smsCode: code,
          ),
        );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.textSecondary.withOpacity(0.5))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        Expanded(child: Divider(color: AppTheme.textSecondary.withOpacity(0.5))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthError,
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(content: Text(state.message)),
            );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) =>
            curr is AuthPhoneCodeSent || prev is AuthPhoneCodeSent,
        builder: (context, state) {
          final showPhoneCode = state is AuthPhoneCodeSent;
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppTheme.neonAccent.withOpacity(0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_mall_outlined,
                            color: AppTheme.neonAccent,
                            size: 32,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Dijab',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        showPhoneCode ? 'Enter verification code' : 'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (showPhoneCode) ...[
                        Text(
                          'Code sent to ${state.phoneNumber}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _smsCodeController,
                          decoration: const InputDecoration(
                            labelText: 'SMS Code',
                            prefixIcon: Icon(Icons.sms_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, s) {
                            final loading = s is AuthLoading;
                            return SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: loading ? null : _onSmsCodeSubmit,
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Verify'),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _onSubmit,
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Sign In'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDivider(),
                            const SizedBox(height: 12),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: isLoading ? null : _onGoogleSignIn,
                                        icon: const Icon(Icons.g_mobiledata, size: 24),
                                        label: const Text('Continue with Google'),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: isLoading ? null : _onAnonymousSignIn,
                                        icon: const Icon(Icons.person_outline, size: 20),
                                        label: const Text('Continue as Guest'),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone (e.g. +1234567890)',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: isLoading ? null : _onPhoneSubmit,
                                        icon: const Icon(Icons.phone_android, size: 20),
                                        label: const Text('Continue with Phone'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                          ],
                        ),
                      ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'By continuing you agree to our Terms & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
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