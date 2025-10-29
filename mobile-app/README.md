# Upvista Community Mobile App

A Flutter mobile application for the Upvista Community platform.

## Features

- Welcome screen with Upvista branding
- Modern Material Design 3 UI
- Cross-platform support (Android & iOS)
- Clean and intuitive user interface

## Prerequisites

Before running this Flutter app, make sure you have:

- **Flutter SDK** (3.0.0 or higher)
- **Dart SDK** (included with Flutter)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **VS Code** or **Android Studio** (recommended IDEs)

## Installation

### 1. Install Flutter

If you haven't installed Flutter yet:

**Windows:**
1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your PATH environment variable
4. Run `flutter doctor` to verify installation

**macOS:**
```bash
# Using Homebrew
brew install flutter

# Or download from flutter.dev
```

**Linux:**
```bash
# Download and extract Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
```

### 2. Setup Project

1. Navigate to the mobile app directory:
   ```bash
   cd mobile-app/upvista_mobile
   ```

2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Verify setup:
   ```bash
   flutter doctor
   ```

## Running the App

### Android
```bash
# Make sure you have an Android device connected or emulator running
flutter run
```

### iOS (macOS only)
```bash
# Make sure you have an iOS simulator or device
flutter run
```

### Web
```bash
flutter run -d chrome
```

## Project Structure

```
upvista_mobile/
├── lib/
│   └── main.dart          # Main app entry point
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
├── pubspec.yaml           # Dependencies and metadata
└── README.md              # This file
```

## Development

### Adding Dependencies
```bash
flutter pub add package_name
```

### Hot Reload
- Press `r` in the terminal while the app is running
- Or save files in your IDE (VS Code/Android Studio)

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**iOS (macOS only):**
```bash
flutter build ios --release
```

## Features Implemented

- ✅ Welcome screen with Upvista branding
- ✅ Material Design 3 theming
- ✅ Responsive layout
- ✅ Interactive buttons
- ✅ Cross-platform compatibility

## Next Steps

- [ ] Add navigation between screens
- [ ] Implement user authentication
- [ ] Add API integration with backend
- [ ] Add community features
- [ ] Implement push notifications

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both Android and iOS
5. Submit a pull request

## Troubleshooting

### Common Issues

**Flutter not found:**
- Make sure Flutter is in your PATH
- Restart your terminal/IDE

**Android license issues:**
```bash
flutter doctor --android-licenses
```

**iOS build issues (macOS):**
```bash
cd ios
pod install
```

For more help, check the [Flutter documentation](https://flutter.dev/docs).
