# EK-2: Uygulama Teknik Dokumantasyonu ve Ekran Goruntuleri

## EK-2'nin Amaci

Bu ek bolumde, gelistirilen TarimCepte mobil uygulamasinin teknik yapisi, kullanilan teknolojiler, veritabani altyapisi, uygulama modulleri ve ekran goruntuleri sunulmustur. EK-2, proje raporunda anlatilan sistemin uygulanabilirligini gostermek ve uygulamanin nasil calistigini destekleyici belgelerle aciklamak amaciyla hazirlanmistir.

## 1. Uygulama Hakkinda Genel Bilgi

TarimCepte uygulamasi, ciftcilerin hasat ettikleri urunlerin sandik ve kilogram bilgilerini kaydederek tahmini gelirlerini takip edebilmelerini saglayan bir mobil uygulamadir. Uygulama uzerinden urun fiyatlari goruntulenebilir, hasat kaydi eklenebilir, komisyon orani dikkate alinarak net kazanc hesaplanabilir ve sezon bazli gelir takibi yapilabilir.

Uygulama Android ve iOS platformlarinda calisabilecek sekilde Flutter ile gelistirilmistir. Veriler Supabase uzerindeki PostgreSQL veritabaninda tutulmaktadir.

## 2. Kullanilan Teknolojiler

Projede kullanilan baslica teknolojiler sunlardir:

| Teknoloji / Paket | Kullanim Amaci |
| --- | --- |
| Flutter | Mobil uygulama arayuzunun gelistirilmesi |
| Dart | Uygulama programlama dili |
| Provider | Uygulama ici durum yonetimi |
| Supabase | Veritabani ve bulut servis altyapisi |
| PostgreSQL | Verilerin saklandigi iliskisel veritabani |
| flutter_dotenv | Ortam degiskenlerinin yonetimi |
| shared_preferences | Yerel veri saklama / yardimci veri yonetimi |
| intl | Tarih ve sayi formatlama islemleri |
| uuid | Benzersiz kimlik uretimi |

## 3. Uygulama Modulleri

Uygulama asagidaki temel modullerden olusmaktadir:

| Modul | Aciklama |
| --- | --- |
| Kullanici Girisi ve Kayit | Kullanici sisteme giris yapabilir veya yeni hesap olusturabilir. |
| Ana Sayfa | Aktif sezon, toplam kazanc ve son hasat kayitlari gibi ozet bilgiler gosterilir. |
| Urun Fiyatlari | Sebze ve meyve fiyatlari listelenir, kullanici guncel fiyat bilgilerini gorebilir. |
| Hasat Ekleme | Urun, sandik sayisi, kilogram ve not bilgileri girilerek yeni hasat kaydi olusturulur. |
| Hasat Gecmisi | Daha once eklenen hasat kayitlari listelenir ve gelir takibi yapilir. |
| Sezon Yonetimi | Kullanici yeni sezon baslatabilir, aktif sezonu takip edebilir ve gecmis sezonlari inceleyebilir. |
| Ayarlar / Profil | Kullanici bilgileri ve komisyon orani gibi ayarlar goruntulenir veya duzenlenir. |

## 4. Proje Dosya Yapisi

Uygulama kaynak kodlari temel olarak `lib` klasoru altinda tutulmaktadir.

```text
lib/
  main.dart
  models/
    user_model.dart
    product_model.dart
    harvest_model.dart
    season_model.dart
  providers/
    user_provider.dart
    product_provider.dart
    harvest_provider.dart
    season_provider.dart
  services/
    user_service.dart
    product_service.dart
    harvest_service.dart
    season_service.dart
  screens/
    login_screen.dart
    register_screen.dart
    home_screen.dart
    products_screen.dart
    add_harvest_screen.dart
    harvest_history_screen.dart
    season_screen.dart
    settings_screen.dart
  utils/
    app_theme.dart
    formatters.dart
```

Bu yapida `models` klasoru veri modellerini, `services` klasoru veritabani ve is mantigi islemlerini, `providers` klasoru durum yonetimini, `screens` klasoru ise kullanici arayuzlerini icermektedir.

## 5. Veritabani Yapisi

Uygulamada veriler Supabase PostgreSQL veritabaninda saklanmaktadir. Projede temel olarak su veri tablolarinin kullanilmasi planlanmistir:

| Tablo | Aciklama |
| --- | --- |
| users | Kullanici profil bilgileri, telefon numarasi ve komisyon orani |
| products | Urun bilgileri, kategori ve fiyat bilgileri |
| harvests | Kullaniciya ait hasat kayitlari, urun, kilo, sandik, kazanc ve tarih bilgileri |
| seasons | Sezon bilgileri, aktif sezon ve sezon tarihleri |

Veritabani semasi `supabase/schema.sql` dosyasinda yer almaktadir. Gerekli kurulum icin bu SQL dosyasi Supabase SQL Editor uzerinden calistirilir.

## 6. Gelir Hesaplama Mantigi

Uygulamada gelir hesaplama islemi urun fiyati, kilogram miktari ve kullaniciya ait komisyon orani dikkate alinarak yapilir.

Temel hesaplama mantigi:

```text
Brut Kazanc = Urun Kilogrami x Birim Fiyat
Komisyon Tutarı = Brut Kazanc x Komisyon Orani
Net Kazanc = Brut Kazanc - Komisyon Tutarı
```

Bu hesaplama sayesinde kullanici, hasat kaydi olustururken tahmini net kazancini gorebilir.

## 7. Kurulum ve Calistirma Bilgileri

Uygulamanin calistirilabilmesi icin asagidaki adimlar izlenir:

1. Flutter SDK ve Dart kurulumu yapilir.
2. Proje klasorunde bagimliliklar yuklenir:

```bash
flutter pub get
```

3. Proje ayarlari yapilandirilir.
4. `supabase/schema.sql` dosyasi Supabase SQL Editor uzerinden calistirilir.
5. Uygulama asagidaki komutla baslatilir:

```bash
flutter run
```

## 8. Ekran Goruntuleri

Bu bolume uygulama ekran goruntuleri eklenmelidir. Her ekran goruntusunun altina kisa aciklama yazilmasi onerilir.

### Sekil EK-2.1: Giris Ekrani

Kullanici giris ekranindan uygulamaya erisir.

### Sekil EK-2.2: Kayit Ekrani

Yeni kullanici hesap olusturur ve gerekli profil bilgilerini girer.

### Sekil EK-2.3: Ana Sayfa

Aktif sezon, toplam kazanc ve son hasat kayitlari ozet olarak gosterilir.

### Sekil EK-2.4: Urun Fiyatlari Ekrani

Sebze ve meyve urunlerinin fiyat bilgileri listelenir.

### Sekil EK-2.5: Hasat Ekleme Ekrani

Kullanici urun, sandik sayisi ve kilogram bilgisi girerek hasat kaydi olusturur.

### Sekil EK-2.6: Hasat Gecmisi Ekrani

Kullanici onceki hasat kayitlarini ve gelir bilgilerini goruntuler.

### Sekil EK-2.7: Sezon Yonetimi Ekrani

Aktif sezon ve gecmis sezon bilgileri takip edilir.

## 9. Sonuc

EK-2 kapsaminda sunulan teknik bilgiler ve ekran goruntuleri, TarimCepte uygulamasinin islevsel yapisini desteklemektedir. Uygulama, ciftcilerin urun fiyatlarini takip etmesine, hasat kayitlarini saklamasina ve sezonluk gelirlerini daha duzenli bicimde analiz etmesine yardimci olacak sekilde tasarlanmistir.
