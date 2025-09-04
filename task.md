# Flutter Mobile Application System Prompt

## Application Overview
You are developing a Flutter mobile application that serves as an inventory management and AI assistant tool. The app combines barcode scanning capabilities with AI-powered chat functionality and configurable API endpoints.

## Core Features

### 1. Barcode Scanner & Item Management

#### Requirements:
- **Primary Input Method**: Camera-based barcode scanning using the device's camera
- **Secondary Input Methods**: 
  - Manual entry of item code
  - Manual entry of barcode number
  - Partial text search using item description substring

#### Implementation Details:
- Use `mobile_scanner` or `flutter_barcode_scanner` package for camera functionality
- Implement a clean UI with:
  - Large, prominent scan button
  - Text input field with clear placeholder text
  - Toggle between scan and manual entry modes
  
#### API Integration:
- **Endpoint**: POST to `/api/transaction/additem`
- **Headers**: `Content-Type: application/json`
- **Payload Structure**:
```json
{
  "itemcode": "string",
  "quantity": number (default: 1)
}
```
- **Error Handling**: 
  - Network connection failures
  - Invalid barcode formats
  - API response errors (4xx, 5xx)
  - Timeout handling (suggest 30 second timeout)

#### User Experience:
- Show loading indicator during API calls
- Display success confirmation with item details
- Provide retry option on failure
- Maintain scan history for current session
- Allow quantity adjustment before submission

### 2. AI Chat Interface with Voice Support

#### Chat Features:
- **Text Input**: 
  - Expandable text field at bottom of screen
  - Send button with clear icon
  - Support for multi-line messages
  
- **Voice Input**:
  - Microphone button for voice-to-text
  - Use `speech_to_text` package
  - Visual feedback during recording (waveform or pulsing indicator)
  - Auto-submit after speech ends or manual stop option
  
- **Message Display**:
  - Clear distinction between user and AI messages
  - Timestamp for each message
  - Scrollable message history
  - Auto-scroll to newest message

#### AI Integration:
- Implement proper message queue system
- Show typing indicator while AI processes
- Handle long responses with proper text wrapping
- Support markdown formatting in AI responses
- Implement copy-to-clipboard for messages

### 3. Settings Screen

#### Configuration Options:

**API Settings**:
- **API Base URL**:
  - Text input field with validation
  - Default value: `http://localhost:8888`
  - Show current URL status (reachable/unreachable)
  - Test connection button
  - Save URL to secure storage

**App Preferences**:
- **Scanner Settings**:
  - Enable/disable auto-scan on app launch
  - Scan sound on/off
  - Vibration feedback on/off
  - Default quantity value

- **Chat Settings**:
  - Default voice language
  - Auto-send voice messages
  - Message text size
  - Theme selection (light/dark/system)

**Data Management**:
- Clear chat history
- Clear scan history
- Export data options

## Technical Requirements

### State Management:
- Use Provider, Riverpod, or Bloc for state management
- Maintain separate states for:
  - Scanner status and history
  - Chat messages and conversation state
  - API configuration and connection status
  - User preferences

### Data Persistence:
- Use `shared_preferences` for settings
- Use `sqflite` or `hive` for chat history
- Implement proper data migration strategies

### Security:
- Validate all API URLs before saving
- Implement HTTPS support
- No hardcoded credentials
- Sanitize user inputs before API calls

### Error Handling:
- Comprehensive try-catch blocks
- User-friendly error messages
- Logging system for debugging
- Crash reporting integration

### UI/UX Guidelines:
- Follow Material Design 3 guidelines
- Responsive layout for different screen sizes
- Support for both portrait and landscape
- Accessibility features (screen reader support, sufficient contrast)
- Smooth animations and transitions
- Pull-to-refresh where applicable

## Navigation Structure

```
Main App
├── Bottom Navigation Bar
│   ├── Scanner Tab (default)
│   ├── Chat Tab
│   └── Settings Tab
├── Scanner Screen
│   ├── Camera View
│   ├── Manual Entry Modal
│   └── History List
├── Chat Screen
│   ├── Message List
│   ├── Input Bar
│   └── Voice Recording Modal
└── Settings Screen
    ├── API Configuration
    ├── App Preferences
    └── About Section
```

## Dependencies (Suggested)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core functionality
  mobile_scanner: ^latest
  http: ^latest
  speech_to_text: ^latest
  
  # State management (choose one)
  provider: ^latest
  # or
  flutter_riverpod: ^latest
  
  # Storage
  shared_preferences: ^latest
  sqflite: ^latest
  
  # UI enhancements
  flutter_markdown: ^latest
  cached_network_image: ^latest
  shimmer: ^latest
  
  # Utilities
  connectivity_plus: ^latest
  permission_handler: ^latest
  url_launcher: ^latest
```

## Testing Requirements

- Unit tests for API communication
- Widget tests for each screen
- Integration tests for complete workflows
- Test coverage minimum: 70%

## Performance Targets

- App launch time: < 2 seconds
- Camera initialization: < 1 second
- API response handling: < 100ms after receipt
- Smooth scrolling at 60 FPS
- Memory usage: < 150MB in normal operation

## Deployment Considerations

- Support Android 6.0+ (API 23+)
- Support iOS 12.0+
- Prepare for app store requirements
- Implement proper version management
- Include update notification system

## Additional Features (Future Enhancements)

- Batch scanning mode
- Offline mode with sync
- Multiple API endpoint profiles
- Chat conversation export
- Barcode generation
- Inventory reports
- Multi-language support
- Biometric authentication for settings