# FormUp

Kişiselleştirilmiş kalori takip uygulaması. Yaş, boy, kilo ve aktivite seviyene göre günlük kalori ihtiyacını hesaplar; yediğin yemeği ve yaptığın aktiviteyi kaydettikçe günlük hedefini canlı olarak günceller.

## Özellikler

- Mifflin-St Jeor formülüyle BMR/TDEE hesaplama
- Hedef bazlı günlük kalori kotası (kaç kg, kaç günde)
- Yemek kaydı (kalori + protein/karbonhidrat/yağ)
- **Fotoğrafla yemek tanıma** — kamerayla çekilen yemek fotoğrafı Gemini 3.5 ile analiz edilir; paketli ürünlerde Open Food Facts veritabanından gerçek besin değerleri, bilinmeyen yemeklerde AI tahmini kullanılır. Ekleme öncesi kullanıcı onayı istenir.
- Aktivite kaydı (MET bazlı kalori yakımı, yürüyüş için adım sayısından otomatik hesaplama)
- **Kişiselleştirilmiş içgörüler** — günlük/haftalık/aylık yeme alışkanlıkları analiz edilip doğal dilde öneriler sunulur (örn. "Bu hafta öğle yemeklerinde ortalamanın üzerinde kalori aldın")
- Gelişmiş ilerleme grafikleri (7/30/90 gün, öğün bazlı dağılım, makro trendleri, hedefe ulaşma projeksiyonu)

## Teknoloji

- Flutter
- Riverpod (state management)
- sqflite (yerel veritabanı)
- fl_chart (grafikler)
- Gemini API (yemek fotoğrafı tanıma ve içgörü üretimi)
- Open Food Facts API (paketli ürün besin değerleri)

## Kurulum

```bash
git clone https://github.com/Ahmetdemirci17/calorie_tracker.git
cd calorie_tracker
flutter pub get
```

### API Anahtarı

Proje kök dizininde bir `.env` dosyası oluştur (`.env.example` dosyasını referans al):

```
GEMINI_API_KEY=senin_api_keyin
```

`.env` dosyası `.gitignore` içinde tutulur, repoya asla commit edilmez.

### Çalıştırma

```bash
flutter run
```

## Klasör Yapısı

```
lib/
  models/       # Veri modelleri
  services/     # Hesaplama mantığı, veritabanı, AI entegrasyonları
  providers/    # Riverpod state provider'ları
  screens/      # Uygulama ekranları
  widgets/      # Tekrar kullanılabilir bileşenler
  theme/        # Renk paleti ve tipografi
```

## Lisans

MIT
