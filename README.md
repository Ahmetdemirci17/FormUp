# FormUp

FormUp, günlük kalori alımınızı ve harcamanızı takip etmenize yardımcı olan, kişisel hedeflerinize (kilo verme, koruma veya alma) göre özelleştirilebilir, modern ve şık bir Flutter uygulamasıdır.

## Temel Özellikler

### 1. Kişiselleştirilmiş Onboarding
*   **Adım Adım Kurulum:** Cinsiyet, yaş, boy, kilo ve aktivite seviyesi bilgilerini alan kullanıcı dostu bir sihirbaz.
*   **Akıllı Hedef Belirleme:** Kilo verme, koruma veya alma hedefleri için özel kalori ve süre hesaplaması.
*   **Sağlık Kontrolü:** Hesaplanan günlük kalori kotasının güvenli sınırlar (kadınlar için 1200 kcal, erkekler için 1500 kcal) altında kalıp kalmadığını kontrol eder.

### 2. Bilimsel Hesaplama Motoru
*   **Mifflin-St Jeor Formülü:** Bazal metabolizma hızınızı (BMR) bilimsel yöntemle hesaplar.
*   **Aktivite Bazlı TDEE:** Günlük aktivite seviyenize göre toplam enerji harcamanızı (TDEE) belirler.
*   **Dinamik Kota:** Hedefinize ulaşmak için gerekli kalori açığını veya fazlasını günlük kota olarak otomatik ayarlar.

### 3. İnteraktif Dashboard
*   **Animasyonlu Progress Ring:** CustomPainter ile çizilmiş, o anki kalori durumunuzu % olarak gösteren modern bir görselleştirme.
*   **Makro Takibi:** Protein, Karbonhidrat ve Yağ dağılımınızı günlük hedefinize göre anlık takip edin.
*   **Dinamik Kota Güncelleme:** Gün içinde eklediğiniz aktiviteler otomatik olarak günlük kalori kotanızı artırır ve arayüzde anında yansıtılır.

### 4. Yemek ve Aktivite Günlüğü
*   **Öğün Bazlı Takip:** Kahvaltı, Öğle, Akşam ve Ara Öğün olarak kategorize edilmiş yemek kayıtları.
*   **Kolay Aktivite Ekleme:** Yürüyüş, koşu, spor gibi aktiviteleri seçerek MET değerleri üzerinden otomatik yakılan kalori hesaplaması.
*   **Yerel Veri Saklama:** Tüm verileriniz SQLite veritabanı ile cihazınızda güvenle saklanır, internet gerektirmez.

### 5. İstatistikler
*   **Görsel Raporlar:** `fl_chart` ile desteklenen günlük/haftalık kalori alım grafiklerini inceleyin.
*   **İlerleme Takibi:** Hedefinize ne kadar yaklaştığınızı istatistik ekranından gözlemleyin.

---

## Gereksinimler

1.  **Flutter SDK**: [Flutter Kurulum Rehberi](https://docs.flutter.dev/get-started/install)
2.  **Android Studio veya Xcode** (Android veya iOS geliştirme için).

## Kurulum ve Çalıştırma

### 1. Bağımlılıkları Yükleme
Proje dizininde (FormUp/) terminali açın:
```bash
flutter pub get
```

### 2. Uygulamayı Çalıştırma
Bağlı bir cihazda çalıştırmak için:
```bash
flutter run
```

Eğer Linux üzerinde masaüstü uygulaması olarak çalıştırmak isterseniz:
```bash
flutter run -d linux
```

---
*Not: Bu uygulama yerel verileri cihazınızda saklar. Hassas verileriniz Git deposuna commit edilmez.*
