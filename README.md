# FormUp

FormUp, günlük kalori alımınızı ve harcamanızı takip etmenize yardımcı olan, hedeflerinize (kilo verme/alma) göre özelleştirilebilir bir Flutter uygulamasıdır.

## Gereksinimler

Bu projeyi yerel ortamınızda çalıştırmak için aşağıdaki araçların kurulu olması gerekir:

1.  **Flutter SDK**: Flutter'ın en son kararlı sürümü (3.x+ önerilir).
    *   [Flutter Kurulum Rehberi](https://docs.flutter.dev/get-started/install)
2.  **Android Studio veya Xcode**:
    *   Android cihazlar için Android SDK ve komut satırı araçları.
    *   iOS cihazlar için Xcode (sadece macOS'ta).
3.  **Dart SDK**: Flutter ile birlikte otomatik olarak gelir.

## Kurulum ve Çalıştırma

Projeyi klonladıktan sonra aşağıdaki adımları takip edin:

### 1. Bağımlılıkları Yükleme
Proje dizininde (FormUp/) terminali açın ve tüm bağımlılıkları indirin:

```bash
flutter pub get
```

### 2. Uygulamayı Çalıştırma
Uygulamayı bağlı bir emülatörde veya fiziksel cihazda çalıştırmak için:

```bash
flutter run
```

Eğer Linux üzerinde masaüstü uygulaması olarak çalıştırmak isterseniz:

```bash
flutter run -d linux
```

## Veritabanı ve Yapılandırma
Uygulama yerel SQLite veritabanı kullanır. İlk çalıştırdığınızda herhangi bir ek yapılandırmaya gerek yoktur; uygulama ilk açılışta veritabanını otomatik olarak oluşturur.

---
*Not: Bu uygulama yerel verileri (SQLite veritabanı vb.) cihazınızda saklar. Hassas verileriniz Git deposuna commit edilmez.*
