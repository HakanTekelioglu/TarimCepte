import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import 'home_screen.dart';

class RegistrationVerificationScreen extends StatefulWidget {
  final String email;
  final String phoneNumber;
  final String password;
  final String fullName;
  final String? city;
  final String? district;

  const RegistrationVerificationScreen({
    super.key,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.fullName,
    this.city,
    this.district,
  });

  @override
  State<RegistrationVerificationScreen> createState() =>
      _RegistrationVerificationScreenState();
}

class _RegistrationVerificationScreenState
    extends State<RegistrationVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _resendTimer;
  int _resendSecondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startResendCooldown(60);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyRegistrationCode(
      widget.email,
      _codeController.text.trim(),
      phoneNumber: widget.phoneNumber,
      password: widget.password,
      fullName: widget.fullName,
      city: widget.city,
      district: widget.district,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _resendCode() async {
    final success = await context.read<AuthProvider>().resendRegistrationCode(
      widget.email,
    );

    if (success && mounted) {
      _startResendCooldown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dogrulama kodu tekrar gonderildi.')),
      );
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

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) {
      return 'Dogrulama kodunu giriniz';
    }
    if (code.length < 6) {
      return 'Kod en az 6 karakter olmali';
    }
    return null;
  }

  String _formatCooldown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return '$remainingSeconds sn';
    }

    return '$minutes dk ${remainingSeconds.toString().padLeft(2, '0')} sn';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-posta Dogrulama')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 72,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Kodunuzu girin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.email} adresine gelen dogrulama kodunu giriniz.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dogrulama Kodu',
                    prefixIcon: Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCode,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return TextButton(
                        onPressed:
                            auth.isLoading || _resendSecondsRemaining > 0
                                ? null
                                : _resendCode,
                        child: Text(
                          _resendSecondsRemaining > 0
                              ? 'Kodu Tekrar Gonder (${_formatCooldown(_resendSecondsRemaining)})'
                              : 'Kodu Tekrar Gonder',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error == null) {
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
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          auth.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Kodu Dogrula',
                                style: TextStyle(fontSize: 16),
                              ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
