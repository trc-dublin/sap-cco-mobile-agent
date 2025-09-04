import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  static const String _apiUrlKey = 'api_base_url';
  static const String _autoScanKey = 'auto_scan_on_launch';
  static const String _scanSoundKey = 'scan_sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _defaultQuantityKey = 'default_quantity';
  static const String _voiceLanguageKey = 'voice_language';
  static const String _autoSendVoiceKey = 'auto_send_voice';
  static const String _messageTextSizeKey = 'message_text_size';
  static const String _themeModeKey = 'theme_mode';
  static const String _cloudVisionEnabledKey = 'cloud_vision_enabled';
  static const String _cloudApiBaseUrlKey = 'cloud_api_base_url';
  static const String _cloudApiKeyKey = 'cloud_api_key';
  static const String _cloudProviderKey = 'cloud_provider';

  SettingsProvider(this._prefs);

  // API Settings
  String get apiBaseUrl => _prefs.getString(_apiUrlKey) ?? 'http://localhost:8888';
  
  void setApiBaseUrl(String url) {
    _prefs.setString(_apiUrlKey, url);
    notifyListeners();
  }

  // Scanner Settings
  bool get autoScanOnLaunch => _prefs.getBool(_autoScanKey) ?? false;
  
  void setAutoScanOnLaunch(bool value) {
    _prefs.setBool(_autoScanKey, value);
    notifyListeners();
  }

  bool get scanSoundEnabled => _prefs.getBool(_scanSoundKey) ?? true;
  
  void setScanSoundEnabled(bool value) {
    _prefs.setBool(_scanSoundKey, value);
    notifyListeners();
  }

  bool get vibrationEnabled => _prefs.getBool(_vibrationKey) ?? true;
  
  void setVibrationEnabled(bool value) {
    _prefs.setBool(_vibrationKey, value);
    notifyListeners();
  }

  int get defaultQuantity => _prefs.getInt(_defaultQuantityKey) ?? 1;
  
  void setDefaultQuantity(int value) {
    _prefs.setInt(_defaultQuantityKey, value);
    notifyListeners();
  }

  // Chat Settings
  String get voiceLanguage => _prefs.getString(_voiceLanguageKey) ?? 'English';
  
  void setVoiceLanguage(String value) {
    _prefs.setString(_voiceLanguageKey, value);
    notifyListeners();
  }

  bool get autoSendVoice => _prefs.getBool(_autoSendVoiceKey) ?? false;
  
  void setAutoSendVoice(bool value) {
    _prefs.setBool(_autoSendVoiceKey, value);
    notifyListeners();
  }

  double get messageTextSize => _prefs.getDouble(_messageTextSizeKey) ?? 16.0;
  
  void setMessageTextSize(double value) {
    _prefs.setDouble(_messageTextSizeKey, value);
    notifyListeners();
  }

  ThemeMode get themeMode {
    final modeIndex = _prefs.getInt(_themeModeKey) ?? 0;
    return ThemeMode.values[modeIndex];
  }
  
  void setThemeMode(ThemeMode mode) {
    _prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  // Cloud Vision Settings
  bool get cloudVisionEnabled => _prefs.getBool(_cloudVisionEnabledKey) ?? false;
  
  void setCloudVisionEnabled(bool value) {
    _prefs.setBool(_cloudVisionEnabledKey, value);
    notifyListeners();
  }

  String get cloudApiBaseUrl => _prefs.getString(_cloudApiBaseUrlKey) ?? 'https://api.openai.com/v1';
  
  void setCloudApiBaseUrl(String url) {
    _prefs.setString(_cloudApiBaseUrlKey, url);
    notifyListeners();
  }

  String get cloudApiKey => _prefs.getString(_cloudApiKeyKey) ?? '';
  
  void setCloudApiKey(String key) {
    _prefs.setString(_cloudApiKeyKey, key);
    notifyListeners();
  }

  String get cloudProvider => _prefs.getString(_cloudProviderKey) ?? 'OpenAI';
  
  void setCloudProvider(String provider) {
    _prefs.setString(_cloudProviderKey, provider);
    notifyListeners();
  }

  // Data Management
  Future<void> resetToDefaults() async {
    await _prefs.clear();
    notifyListeners();
  }
}