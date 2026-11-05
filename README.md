# VMS Frontend (Flutter Web)

Production-oriented Flutter Web application for the Vehicle Management System.

---

## 🛠 Tech Stack & Architecture

- **Flutter SDK**: `>=3.19.0`
- **Target Platform**: Web (Chrome, Edge, Safari, Firefox)
- **Design System**: Material 3 Design
- **Architecture**: Clean Architecture / Feature-First
  - `core/`: Cross-cutting utilities (network `ApiClient`, app configuration, colors, themes, constants)
  - `features/`: Isolated domain feature modules (reserved for features)

---

## ⚙️ Configuration

- API target is configurable at build or run time via `--dart-define`:
  ```bash
  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
  ```
  *(Default: `http://localhost:8080/api/v1`)*

---

## 🚀 Running the Web App

### Prerequisites
- Flutter SDK configured with Web support (`flutter config --enable-web`)

### Development Run
```bash
# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

### Production Build
```bash
flutter build web --release
```
Artifacts will be output to `build/web/`.

