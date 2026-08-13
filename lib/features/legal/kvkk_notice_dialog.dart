import 'package:flutter/material.dart';

const String kvkkNoticeText = '''
TarımCepte KVKK Aydınlatma Metni

6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında, TarımCepte uygulamasını kullanırken paylaştığınız kişisel veriler aşağıdaki çerçevede işlenmektedir.

Veri sorumlusu
Kişisel verileriniz, TarımCepte uygulamasının hizmetlerinin sunulması ve yönetilmesi amacıyla uygulama sahibi/veri sorumlusu tarafından işlenir.

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

class KvkkNoticeDialog extends StatelessWidget {
  const KvkkNoticeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const KvkkNoticeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('KVKK Aydınlatma Metni'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            kvkkNoticeText,
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
  }
}
