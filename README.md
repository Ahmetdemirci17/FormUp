# ShapeUp

Kişiselleştirilmiş kalori takip uygulaması. Yaş, boy, kilo ve aktivite seviyene göre günlük kalori ihtiyacını hesaplar; yediğin yemeği ve yaptığın aktiviteyi kaydettikçe günlük hedefini canlı olarak günceller.

## Özellikler

- Mifflin-St Jeor formülüyle BMR/TDEE hesaplama
- Hedef bazlı günlük kalori kotası (kaç kg, kaç günde)
- Yemek kaydı (kalori + protein/karbonhidrat/yağ)
- Aktivite kaydı (MET bazlı kalori yakımı, yürüyüş için adım sayısından otomatik hesaplama)
- Günlük ilerleme grafiği (dairesel progress ring)
- Geçmiş istatistikler (7/30 günlük grafik)

## Teknoloji

- Flutter
- Riverpod (state management)
- Json (yerel veritabanı)
- fl_chart (grafikler)

## Kurulum

```bash
git clone https://github.com/Ahmetdemirci17/FormUp.git
cd FormUp
flutter pub get
flutter run
```

## Klasör Yapısı

```
lib/
  models/       # Veri modelleri
  services/     # Hesaplama mantığı ve veritabanı işlemleri
  providers/    # Riverpod state provider'ları
  screens/      # Uygulama ekranları
  widgets/      # Tekrar kullanılabilir bileşenler
  theme/        # Renk paleti ve tipografi
```

## Lisans

MIT
