# Hal Fiyat - Çiftçi Gelir Takip Uygulaması

Hal Fiyat, çiftçilerin seradan topladıkları ürünlerin kazançlarını takip etmelerini sağlayan bir mobil uygulamadır. Hem iOS hem de Android platformlarında çalışır.

## 📱 Özellikler

### ✅ Kullanıcı Yönetimi
- Kayıt olma ve giriş yapma
- Kişisel komisyon oranı ayarlama
- Profil bilgilerini görüntüleme

### 📦 Hasat Takibi
- Sandık sayısı ve kilogram girişi
- Ürün seçimi ve otomatik fiyat çekme
- Net kazanç hesaplama (komisyon düşülmüş)
- Hasat geçmişi görüntüleme

### 💰 Kazanç Hesaplama
- Brüt kazanç hesaplama
- Komisyoncu kesintisi hesaplama
- Net kazanç görüntüleme
- Sezonluk toplam kazanç özeti

### 📅 Sezon Yönetimi
- Yeni sezon başlatma
- Sezon bazlı kazanç takibi
- Geçmiş sezonları görüntüleme
- Sezon karşılaştırma

### 🏷️ Ürün Fiyatları
- Güncel hal fiyatları
- Sebze ve meyve kategorileri
- Fiyat güncelleme

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / Xcode

### Adımlar

1. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

2. **Ortam değişkenlerini ayarlayın:**
- Proje kökünde `.env.example` dosyasını kopyalayıp adını `.env` yapın.

`.env` dosyasına Supabase bilgilerinizi girin:
```env
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

3. **Supabase SQL şemasını çalıştırın:**
- Supabase Dashboard → SQL Editor
- `supabase/schema.sql` dosyasındaki scripti çalıştırın

4. **(Mevcut kurulumlar için) ilçe normalizasyon migration'ını çalıştırın:**
- Eğer veritabanında eski Mersin ilçe kayıtları varsa,
  `supabase/migrations/2026-04-23_mersin_district_normalization.sql` dosyasını SQL Editor'da çalıştırın.

5. **Uygulamayı çalıştırın:**

```bash
# Android için
flutter run

# iOS için
flutter run -d ios

# Web için (test amaçlı)
flutter run -d chrome
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── models/                   # Veri modelleri
│   ├── user_model.dart      # Kullanıcı modeli
│   ├── product_model.dart   # Ürün modeli
│   ├── harvest_model.dart   # Hasat modeli
│   └── season_model.dart    # Sezon modeli
├── providers/               # State management
│   ├── auth_provider.dart   # Kimlik doğrulama
│   ├── product_provider.dart
│   ├── harvest_provider.dart
│   └── season_provider.dart
├── services/                # İş mantığı servisleri
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── harvest_service.dart
│   └── season_service.dart
├── screens/                 # UI ekranları
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── products_screen.dart
│   ├── add_harvest_screen.dart
│   ├── harvest_history_screen.dart
│   ├── season_screen.dart
│   └── settings_screen.dart
└── utils/                   # Yardımcı araçlar
    └── app_theme.dart       # Tema ayarları
```

## 🗄️ Supabase Entegrasyonu

Uygulama artık Supabase tabanlıdır ve tüm veriler (`users`, `products`, `seasons`, `harvests`) Supabase Postgres üzerinde tutulur.

### Gerekli Supabase Ayarları
- Authentication zorunlu değil (uygulama `users` tablosunda telefon + şifre ile giriş yapar)
- SQL Editor'da `supabase/schema.sql` scriptini çalıştırın
- Project Settings → API bölümünden `SUPABASE_URL` ve `anon` key değerlerini alın

## 📦 Kullanılan Paketler

| Paket | Açıklama |
|-------|----------|
| provider | State management |
| supabase_flutter | Supabase Auth + Database bağlantısı |
| flutter_dotenv | `.env` yönetimi |
| shared_preferences | Local fallback servisleri |
| intl | Tarih/sayı formatı |
| uuid | Unique ID oluşturma |

## 🎨 Ekran Görüntüleri

### Ana Sayfa
- Hoş geldin mesajı
- Aktif sezon bilgisi
- Kazanç özeti kartları
- Son hasatlar listesi

### Hasat Ekleme
- Ürün seçimi
- Sandık ve kilo girişi
- Anlık kazanç hesaplama
- Not ekleme

### Fiyatlar
- Sebze kategorisi
- Meyve kategorisi
- Fiyat güncelleme

### Sezonlar
- Aktif sezon gösterimi
- Geçmiş sezonlar
- Sezon bazlı istatistikler

## 🛠️ Geliştirme

### Yeni Özellik Ekleme
1. Model oluşturun (`lib/models/`)
2. Servis oluşturun (`lib/services/`)
3. Provider oluşturun (`lib/providers/`)
4. UI ekranı oluşturun (`lib/screens/`)

### Build Alma
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

---

**Hal Fiyat** - Çiftçiler için geliştirildi 🌾
