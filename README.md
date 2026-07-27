# LiDAR Scanner iOS Uygulaması

iPhone LiDAR sensörü ile nesneleri tarayıp 3D model olarak dışa aktaran iOS uygulaması.

**Kullanım amacı:** Araç plastik parçalarını tarayıp Blender'da düzenledikten sonra 3D yazıcıya göndermek.

## Özellikler

- iPhone LiDAR ile gerçek zamanlı mesh tarama
- AR kamera üzerinde canlı mesh görüntüleme
- Tarama tamamlandıktan sonra 3D önizleme
- **OBJ / STL / PLY** formatlarında dışa aktarım
- AirDrop, Files, Mail ile dosya paylaşımı
- Tarama istatistikleri (vertex/triangle sayısı, dosya boyutu)

## Gereksinimler

- **iOS 17+**
- **iPhone 12 Pro** veya daha yeni Pro model
- **iPad Pro** (2020 veya daha yeni, LiDAR'lı)

## CI ile Derleme

Bu proje GitHub Actions kullanarak macOS runner'da otomatik derlenir.

### Kullanım

```bash
# 1. Repo'yu klonla
git clone https://github.com/<kullanici>/LiDAR-Scanner.git
cd LiDAR-Scanner

# 2. Push yap → GitHub Actions otomatik derler
git push origin main
```

### Build Artifact'ı İndirme

1. GitHub repo sayfasında **Actions** sekmesine tıklayın
2. En son workflow run'ı seçin
3. **LidarScanner-iOS** artifact'ını indirin
4. `.app` dosyasını bir sideload aracı ile iPhone'a yükleyin

### Sideload ile iPhone'a Yükleme (Windows)

| Araç | Link | İşlem |
|---|---|---|
| **Sideloadly** | https://sideloadly.io | .app seç → Apple ID gir → Install |
| **3uTools** | https://3utools.com | App Install → .app seç |
| **AltStore** | https://altstore.io | iTunes üzerinden yükleme |

Adımlar:
1. [Sideloadly](https://sideloadly.io) indirip kurun
2. iPhone'u USB ile bağlayın (iTunes yüklü olmalı)
3. GitHub Actions'dan indirdiğiniz `.app` dosyasını seçin
4. Apple ID (ücretsiz) ile giriş yapın
5. "Start" butonuna basın → 7 gün geçerli olarak yüklenir
6. 7 gün sonra tekrar sideload yapmanız gerekir

## Yerel Geliştirme (macOS)

```bash
# XcodeGen ile proje oluştur
brew install xcodegen
xcodegen generate

# Xcode ile aç
open LidarScanner.xcodeproj

# Build (Cmd+B) veya test (Cmd+U)
```

## Proje Yapısı

```
LiDAR-Scanner/
├── .github/workflows/build.yml   # CI pipeline
├── project.yml                    # XcodeGen spec
├── LidarScanner/
│   ├── LidarScannerApp.swift      # App entry
│   ├── ContentView.swift          # Ana navigasyon
│   ├── Views/                     # SwiftUI ekranlar
│   ├── Managers/                  # ARKit yönetimi
│   ├── Models/                    # Veri modelleri
│   ├── Exporters/                 # OBJ/STL/PLY export
│   └── Resources/                 # Asset'ler
├── LidarScannerTests/             # Unit testler
└── LidarScannerUITests/           # UI testler
```

## Export Formatları

| Format | Açıklama | Blender Import |
|---|---|---|
| **OBJ** | Wavefront OBJ (vertex/face/normal) | File > Import > Wavefront (.obj) |
| **STL** | Binary STL (3D yazıcı standardı) | File > Import > STL (.stl) |
| **PLY** | Stanford PLY (ASCII) | File > Import > Stanford (.ply) |

## Blender'a Aktarma

1. iPhone'dan export ettiğiniz dosyayı Windows'a aktarın (AirDrop / USB / e-posta)
2. Blender'ı açın
3. `File > Import` menüsünden formatınıza uygun seçeneği seçin
4. Mesh'i düzenleyin (boşluk doldurma, smoothing, ölçeklendirme)
5. `File > Export > STL` ile 3D yazıcıya hazır hale getirin

## Lisans

MIT
