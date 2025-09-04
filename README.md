# SAP CCO Mobile Agent

A Flutter mobile application for inventory management and AI-powered assistance with barcode scanning capabilities.

## Features

### 1. Barcode Scanner & Item Management
- Camera-based barcode scanning
- Manual entry options (item code, barcode, description search)
- Quantity adjustment
- Scan history tracking
- Retry failed scans

### 2. AI Chat Interface
- Text and voice input support
- Markdown rendering for AI responses
- Message history persistence
- Copy messages to clipboard
- Auto-scroll to newest messages

### 3. Settings & Configuration
- Configurable API endpoint
- Connection testing
- Scanner preferences (sound, vibration, auto-scan)
- Chat preferences (voice language, auto-send, text size)
- Theme selection (light/dark/system)
- Data management (clear history, export)

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode for mobile development
- A device or emulator for testing

### Installation

1. Clone the repository
```bash
cd /Users/alex/Projects/sap-cco-mobile-agent
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the application
```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android

# List available devices
flutter devices
```

### Configuration

1. **API Endpoint**: Configure your backend API URL in Settings > API Configuration
   - Default: `http://localhost:8888`
   - Test connection before saving

2. **Permissions**: The app will request the following permissions:
   - Camera (for barcode scanning)
   - Microphone (for voice input)
   - Speech Recognition (for voice-to-text)

## API Integration

The app expects the following API endpoints:

### Add Item Endpoint
- **URL**: `POST /api/transaction/additem`
- **Headers**: `Content-Type: application/json`
- **Body**:
```json
{
  "itemcode": "string",
  "quantity": number
}
```

### Chat Endpoint (if implementing AI chat)
- **URL**: `POST /api/chat`
- **Headers**: `Content-Type: application/json`
- **Body**:
```json
{
  "message": "string",
  "context": {}
}
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # Screen widgets
│   ├── main_screen.dart     # Main navigation screen
│   ├── scanner_screen.dart  # Barcode scanner
│   ├── chat_screen.dart     # AI chat interface
│   └── settings_screen.dart # Settings page
├── providers/               # State management
│   ├── app_state.dart      # Global app state
│   ├── scanner_provider.dart # Scanner state
│   ├── chat_provider.dart   # Chat state
│   └── settings_provider.dart # Settings state
├── models/                  # Data models
│   ├── scan_item.dart      # Scan item model
│   └── chat_message.dart   # Chat message model
├── services/                # Business logic
│   ├── api_service.dart    # API communication
│   └── database_service.dart # Local storage
└── widgets/                 # Reusable widgets
    ├── manual_entry_dialog.dart
    ├── scan_history_list.dart
    └── voice_recording_dialog.dart
```

## Building for Production

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# For app bundle (recommended for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode to archive and distribute
```

## Troubleshooting

### Common Issues

1. **Camera not working**:
   - Ensure camera permissions are granted
   - Check if another app is using the camera

2. **API connection fails**:
   - Verify the API URL is correct
   - Check network connectivity
   - Ensure the backend server is running

3. **Voice input not working**:
   - Grant microphone and speech recognition permissions
   - Check device language settings
   - Ensure internet connection for speech recognition

## Development

### Running Tests
```bash
flutter test
```

### Code Generation (if needed)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Debugging
```bash
flutter run --debug
```

## License

This project is proprietary software.

## Support

For issues or questions, please contact the development team.