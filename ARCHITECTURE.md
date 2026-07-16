# Mimari sınırlar

Proje, yüksek cohesion ve düşük coupling için aşağıdaki bağımlılık yönünü izler:

```text
screens -> providers -> service contracts
                         ^
app composition -> service implementations -> domain rules
                               |
                               v
                    infrastructure adapters
```

## Kurallar

- `lib/app/` uygulamanın composition root katmanıdır. Somut servis seçimi yalnızca burada yapılır.
- `lib/providers/` yalnızca `lib/services/contracts/` içindeki arayüzlere bağlıdır; Supabase veya SharedPreferences bilmez.
- `lib/services/` iş akışlarını ve servis implementasyonlarını içerir. Harici saklama ayrıntılarına doğrudan bağlanmak yerine arayüz kullanır.
- `lib/domain/` Flutter ve veri kaynağından bağımsız kuralları içerir.
- `lib/infrastructure/` SharedPreferences gibi paketlere bağlı adaptörleri içerir.
- `lib/features/` kendi başına anlamlı arayüz parçalarını ve içeriklerini tutar.
- Yeni bir veri kaynağı eklenirken Provider veya ekran değiştirilmez; ilgili servis sözleşmesinin yeni implementasyonu yazılıp `AppDependencies` içinde seçilir.
