import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'password_reset_screen.dart';

const String _kvkkAydinlatmaMetni = '''
Hal Fiyat KVKK Aydınlatma Metni

6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında, Hal Fiyat uygulamasını kullanırken paylaştığınız kişisel veriler aşağıdaki çerçevede işlenmektedir.

Veri sorumlusu
Kişisel verileriniz, Hal Fiyat uygulamasının hizmetlerinin sunulması ve yönetilmesi amacıyla uygulama sahibi/veri sorumlusu tarafından işlenir.

İşlenen kişisel veriler
Ad soyad, telefon numarası, şifre, şehir, ilçe, kullanıcı rolü, ürün, sezon, hasat ve fiyat kayıtları ile uygulama kullanımına ilişkin işlem kayıtları işlenebilir.

Kişisel verilerin işlenme amaçları
Verileriniz; kullanıcı hesabı oluşturmak ve güvenli giriş sağlamak, uygulama hizmetlerini sunmak, ürün ve hasat kayıtlarını yönetmek, fiyat takibi yapmak, destek taleplerini karşılamak, güvenliği sağlamak ve mevzuattan doğan yükümlülükleri yerine getirmek amacıyla işlenir.

Kişisel verilerin aktarımı
Kişisel verileriniz; uygulama altyapısının işletilmesi, veri saklama, teknik destek ve yasal yükümlülüklerin yerine getirilmesi amaçlarıyla hizmet sağlayıcılar ve hukuken yetkili kamu kurumlarıyla sınırlı olarak paylaşılabilir.

Toplama yöntemi ve hukuki sebep
Kişisel verileriniz uygulama formları, kullanıcı işlemleri ve elektronik sistemler aracılığıyla toplanır. Verileriniz; sözleşmenin kurulması veya ifası, veri sorumlusunun hukuki yükümlülüğünü yerine getirmesi, bir hakkın tesisi, kullanılması veya korunması ve meşru menfaat hukuki sebeplerine dayanılarak işlenir.

İlgili kişi hakları
KVKK'nın 11. maddesi kapsamında; kişisel verilerinizin işlenip işlenmediğini öğrenme, işlenmişse bilgi talep etme, işlenme amacını ve amaca uygun kullanılıp kullanılmadığını öğrenme, aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmiş verilerin düzeltilmesini isteme, mevzuatta öngörülen şartlarda silinmesini veya yok edilmesini isteme, aktarıldığı üçüncü kişilere yapılan işlemlerin bildirilmesini isteme, otomatik sistemlerle analiz sonucu aleyhinize çıkan sonuca itiraz etme ve kanuna aykırı işleme nedeniyle zarara uğramanız halinde giderim talep etme haklarına sahipsiniz.
''';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  String _normalizePhoneNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    if (cleaned.startsWith('90')) {
      return '+$cleaned';
    }

    if (cleaned.startsWith('0')) {
      return '+90${cleaned.substring(1)}';
    }

    return '+90$cleaned';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _normalizePhoneNumber(_phoneController.text.trim()),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (success && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  Future<void> _showKvkkDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('KVKK Aydınlatma Metni'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                _kvkkAydinlatmaMetni,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo ve başlık
                Icon(
                  Icons.agriculture,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hal Fiyat',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kazancınızı Takip Edin',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Telefon alanı
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon Numarası',
                    hintText: '05XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telefon numarası giriniz';
                    }
                    final digitCount =
                        value.replaceAll(RegExp(r'[^0-9]'), '').length;
                    if (digitCount < 10) {
                      return 'Geçerli bir telefon numarası giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre alanı
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Beni hatırla'),
                ),
                const SizedBox(height: 8),

                // Hata mesajı
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Giriş butonu
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
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
                                'Giriş Yap',
                                style: TextStyle(fontSize: 16),
                              ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      context.read<AuthProvider>().clearError();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PasswordResetScreen(),
                        ),
                      );
                    },
                    child: const Text('Şifremi Unuttum'),
                  ),
                ),
                const SizedBox(height: 8),

                // Kayıt ol linki
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hesabınız yok mu?'),
                    TextButton(
                      onPressed: () {
                        context.read<AuthProvider>().clearError();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Kayıt Ol'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextButton.icon(
                  onPressed: _showKvkkDialog,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('KVKK Aydınlatma Metni'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
