import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

enum _ResetStep { email, code, password, done }

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _ResetStep _step = _ResetStep.email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      _startResendCooldown(60);
      setState(() {
        _step = _ResetStep.code;
      });
      return;
    }

    if (!success && mounted) {
      final error = context.read<AuthProvider>().error ?? '';
      if (error.contains('saatlik e-posta limiti')) {
        _startResendCooldown(3600);
      }
    }
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsRemaining = seconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsRemaining = 0;
        });
        return;
      }

      setState(() {
        _resendSecondsRemaining -= 1;
      });
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().verifyPasswordResetCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _step = _ResetStep.password;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updatePassword(_passwordController.text);

    if (success && mounted) {
      await authProvider.logout();
      if (!mounted) return;
      setState(() {
        _step = _ResetStep.done;
      });
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'E-posta giriniz';
    }
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'Geçerli bir e-posta giriniz';
    }
    return null;
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) {
      return 'Yenileme kodunu giriniz';
    }
    if (code.length < 6) {
      return 'Kod en az 6 karakter olmalı';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Yeni şifre giriniz';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    return null;
  }

  String get _title {
    switch (_step) {
      case _ResetStep.email:
        return 'Şifrenizi yenileyin';
      case _ResetStep.code:
        return 'Kodu girin';
      case _ResetStep.password:
        return 'Yeni şifre belirleyin';
      case _ResetStep.done:
        return 'Şifre güncellendi';
    }
  }

  String get _description {
    switch (_step) {
      case _ResetStep.email:
        return 'Hesabınıza bağlı e-posta adresini giriniz.';
      case _ResetStep.code:
        return 'E-postanıza gelen yenileme kodunu giriniz.';
      case _ResetStep.password:
        return 'Hesabınız için yeni şifrenizi yazınız.';
      case _ResetStep.done:
        return 'Yeni şifrenizle giriş yapabilirsiniz.';
    }
  }

  IconData get _icon {
    switch (_step) {
      case _ResetStep.email:
        return Icons.lock_reset;
      case _ResetStep.code:
        return Icons.pin_outlined;
      case _ResetStep.password:
        return Icons.password_outlined;
      case _ResetStep.done:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre Yenileme')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(_icon, size: 72, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ..._buildStepFields(),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error == null || _step == _ResetStep.done) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepFields() {
    switch (_step) {
      case _ResetStep.email:
        return [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@mail.com',
              prefixIcon: Icon(Icons.mail_outline),
              border: OutlineInputBorder(),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 20),
        ];
      case _ResetStep.code:
        return [
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Yenileme Kodu',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _validateCode,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  context.watch<AuthProvider>().isLoading ||
                          _resendSecondsRemaining > 0
                      ? null
                      : _sendResetEmail,
              child: Text(
                _resendSecondsRemaining > 0
                    ? 'Kodu Tekrar Gönder (${_formatCooldown(_resendSecondsRemaining)})'
                    : 'Kodu Tekrar Gönder',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ];
      case _ResetStep.password:
        return [
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre Tekrar',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              final passwordError = _validatePassword(value);
              if (passwordError != null) return passwordError;
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
        ];
      case _ResetStep.done:
        return const [SizedBox(height: 8)];
    }
  }

  Widget _buildActionButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLoading = auth.isLoading;
        return ElevatedButton(
          onPressed: isLoading ? null : _handleAction,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(_buttonText, style: const TextStyle(fontSize: 16)),
        );
      },
    );
  }

  Future<void> _handleAction() async {
    switch (_step) {
      case _ResetStep.email:
        await _sendResetEmail();
        return;
      case _ResetStep.code:
        await _verifyCode();
        return;
      case _ResetStep.password:
        await _updatePassword();
        return;
      case _ResetStep.done:
        if (mounted) Navigator.of(context).pop();
        return;
    }
  }

  String get _buttonText {
    switch (_step) {
      case _ResetStep.email:
        return 'Yenileme Kodu Gönder';
      case _ResetStep.code:
        return 'Kodu Doğrula';
      case _ResetStep.password:
        return 'Şifreyi Güncelle';
      case _ResetStep.done:
        return 'Girişe Dön';
    }
  }

  String _formatCooldown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return '$remainingSeconds sn';
    }

    return '$minutes dk ${remainingSeconds.toString().padLeft(2, '0')} sn';
  }
}
