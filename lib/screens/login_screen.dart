import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/auth/turkish_phone_number.dart';
import '../features/legal/kvkk_notice_dialog.dart';
import '../providers/providers.dart';
import 'home_screen.dart';
import 'password_reset_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final identifier = _phoneController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      identifier.contains('@')
          ? identifier.toLowerCase()
          : TurkishPhoneNumber.normalize(identifier),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (success && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBrand(context),
                        const SizedBox(height: 28),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Hesabınıza giriş yapın',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hasatlarınız ve güncel ürün fiyatları sizi bekliyor.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                        AutofillHints.telephoneNumber,
                                        AutofillHints.email,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Telefon veya E-posta',
                                        hintText:
                                            '05XXXXXXXXX veya ornek@mail.com',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      onFieldSubmitted:
                                          (_) =>
                                              _passwordFocusNode.requestFocus(),
                                      validator: _validateIdentifier,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Şifre',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip:
                                              _obscurePassword
                                                  ? 'Şifreyi göster'
                                                  : 'Şifreyi gizle',
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          onPressed:
                                              () => setState(
                                                () =>
                                                    _obscurePassword =
                                                        !_obscurePassword,
                                              ),
                                        ),
                                      ),
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      validator:
                                          (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Şifre giriniz'
                                                  : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CheckboxListTile(
                                            value: _rememberMe,
                                            onChanged:
                                                (value) => setState(
                                                  () =>
                                                      _rememberMe =
                                                          value ?? false,
                                                ),
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            dense: true,
                                            title: const Text('Beni hatırla'),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _openPasswordReset,
                                          child: const Text('Şifremi Unuttum'),
                                        ),
                                      ],
                                    ),
                                    Consumer<AuthProvider>(
                                      builder: (context, auth, _) {
                                        if (auth.error == null) {
                                          return const SizedBox(height: 8);
                                        }
                                        return Semantics(
                                          liveRegion: true,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                              bottom: 14,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: colors.errorContainer,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 20,
                                                  color:
                                                      colors.onErrorContainer,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    auth.error!,
                                                    style: TextStyle(
                                                      color:
                                                          colors
                                                              .onErrorContainer,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Consumer<AuthProvider>(
                                      builder: (context, auth, _) {
                                        return FilledButton.icon(
                                          onPressed:
                                              auth.isLoading
                                                  ? null
                                                  : _handleLogin,
                                          icon:
                                              auth.isLoading
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : const Icon(
                                                    Icons.login_rounded,
                                                  ),
                                          label: Text(
                                            auth.isLoading
                                                ? 'Giriş Yapılıyor…'
                                                : 'Giriş Yap',
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: colors.outlineVariant,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'veya',
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: colors.outlineVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _openRegistration,
                                      icon: const Icon(
                                        Icons.person_add_outlined,
                                      ),
                                      label: const Text('Yeni Hesap Oluştur'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => KvkkNoticeDialog.show(context),
                          icon: const Icon(
                            Icons.privacy_tip_outlined,
                            size: 19,
                          ),
                          label: const Text('KVKK Aydınlatma Metni'),
                        ),
                      ],
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

  Widget _buildBrand(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.agriculture_rounded,
            size: 40,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'TarımCepte',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Hasadınızı kaydedin, kazancınızı güvenle takip edin.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  String? _validateIdentifier(String? value) {
    final identifier = value?.trim() ?? '';
    if (identifier.isEmpty) {
      return 'Telefon numarası veya e-posta giriniz';
    }
    if (identifier.contains('@')) {
      final validEmail = RegExp(
        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      ).hasMatch(identifier);
      return validEmail ? null : 'Geçerli bir e-posta giriniz';
    }
    final digitCount = identifier.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digitCount < 10
        ? 'Geçerli bir telefon numarası veya e-posta giriniz'
        : null;
  }

  void _openPasswordReset() {
    context.read<AuthProvider>().clearError();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PasswordResetScreen()));
  }

  void _openRegistration() {
    context.read<AuthProvider>().clearError();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }
}
