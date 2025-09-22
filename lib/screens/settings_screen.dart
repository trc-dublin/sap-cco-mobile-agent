import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/chat_provider.dart';
import '../providers/scanner_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _cloudApiUrlController = TextEditingController();
  final TextEditingController _cloudApiKeyController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiUrlController.text = settings.apiBaseUrl;
    _cloudApiUrlController.text = settings.cloudApiBaseUrl;
    _cloudApiKeyController.text = settings.cloudApiKey;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _cloudApiUrlController.dispose();
    _cloudApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    final apiService = ApiService();
    final isReachable = await apiService.testConnection(_apiUrlController.text);

    setState(() {
      _isTestingConnection = false;
      _connectionStatus =
          isReachable ? 'Connection successful' : 'Connection failed. Please check the URL.';
    });
  }

  void _saveApiUrl() {
    final settings = context.read<SettingsProvider>();
    settings.setApiBaseUrl(_apiUrlController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API URL saved')),
    );
  }

  void _saveCloudSettings() {
    final settings = context.read<SettingsProvider>();
    settings.setCloudApiBaseUrl(_cloudApiUrlController.text);
    settings.setCloudApiKey(_cloudApiKeyController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cloud API settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildApiSettingsSection(settings),
              const Divider(),
              _buildCloudVisionSettingsSection(settings),
              const Divider(),
              _buildScannerSettingsSection(settings),
              const Divider(),
              _buildChatSettingsSection(settings),
              const Divider(),
              _buildDataManagementSection(),
              const Divider(),
              _buildAboutSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApiSettingsSection(SettingsProvider settings) {
    return _SettingsSection(
      title: 'API Configuration',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _apiUrlController,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://localhost:8888',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _saveApiUrl,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_connectionStatus != null)
                Text(
                  _connectionStatus!,
                  style: TextStyle(
                    color: _connectionStatus!.contains('successful') ? Colors.green : Colors.red,
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  child: _isTestingConnection
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Connection'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloudVisionSettingsSection(SettingsProvider settings) {
    return _SettingsSection(
      title: 'Cloud Vision & AI Settings',
      children: [
        SwitchListTile(
          title: const Text('Enable Cloud Vision'),
          subtitle: const Text('Use cloud AI for enhanced image analysis'),
          value: settings.cloudVisionEnabled,
          onChanged: settings.setCloudVisionEnabled,
        ),
        if (settings.cloudVisionEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: settings.cloudProvider,
                  decoration: const InputDecoration(
                    labelText: 'Cloud Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI')),
                    DropdownMenuItem(value: 'Claude', child: Text('Claude')),
                    DropdownMenuItem(value: 'Google', child: Text('Google Vision')),
                    DropdownMenuItem(value: 'Custom', child: Text('Custom API')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setCloudProvider(value);
                      // Update default URLs based on provider
                      switch (value) {
                        case 'OpenAI':
                          _cloudApiUrlController.text = 'https://api.openai.com/v1';
                          break;
                        case 'Claude':
                          _cloudApiUrlController.text = 'https://api.anthropic.com/v1';
                          break;
                        case 'Google':
                          _cloudApiUrlController.text = 'https://vision.googleapis.com/v1';
                          break;
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cloudApiUrlController,
                  decoration: InputDecoration(
                    labelText: 'Cloud API Base URL',
                    hintText: 'https://api.openai.com/v1',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveCloudSettings,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cloudApiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your API key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveCloudSettings,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cloud Vision Benefits',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• More accurate item recognition\n• Detailed product descriptions\n• Context-aware analysis\n• Better handling of complex images',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScannerSettingsSection(SettingsProvider settings) {
    return _SettingsSection(
      title: 'Scanner Settings',
      children: [
        SwitchListTile(
          title: const Text('Auto-scan on launch'),
          subtitle: const Text('Start scanning when app opens'),
          value: settings.autoScanOnLaunch,
          onChanged: settings.setAutoScanOnLaunch,
        ),
        SwitchListTile(
          title: const Text('Scan sound'),
          subtitle: const Text('Play sound when barcode is scanned'),
          value: settings.scanSoundEnabled,
          onChanged: settings.setScanSoundEnabled,
        ),
        SwitchListTile(
          title: const Text('Vibration feedback'),
          subtitle: const Text('Vibrate when barcode is scanned'),
          value: settings.vibrationEnabled,
          onChanged: settings.setVibrationEnabled,
        ),
        ListTile(
          title: const Text('Default quantity'),
          subtitle: Text('Current: ${settings.defaultQuantity}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: settings.defaultQuantity > 1
                    ? () => settings.setDefaultQuantity(settings.defaultQuantity - 1)
                    : null,
              ),
              Text('${settings.defaultQuantity}'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => settings.setDefaultQuantity(settings.defaultQuantity + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSettingsSection(SettingsProvider settings) {
    return _SettingsSection(
      title: 'Chat Settings',
      children: [
        ListTile(
          title: const Text('Voice language'),
          subtitle: Text(settings.voiceLanguage),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showLanguageDialog(settings),
        ),
        SwitchListTile(
          title: const Text('Auto-send voice messages'),
          subtitle: const Text('Send message after speech recognition'),
          value: settings.autoSendVoice,
          onChanged: settings.setAutoSendVoice,
        ),
        ListTile(
          title: const Text('Message text size'),
          subtitle: Slider(
            value: settings.messageTextSize,
            min: 12,
            max: 24,
            divisions: 6,
            label: settings.messageTextSize.round().toString(),
            onChanged: settings.setMessageTextSize,
          ),
        ),
        ListTile(
          title: const Text('Theme'),
          subtitle: Text(_getThemeModeName(settings.themeMode)),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showThemeDialog(settings),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return _SettingsSection(
      title: 'Data Management',
      children: [
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Clear chat history'),
          onTap: () => _confirmClearData('chat'),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Clear scan history'),
          onTap: () => _confirmClearData('scan'),
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export data'),
          onTap: _exportData,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _SettingsSection(
      title: 'About',
      children: [
        const ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://example.com/privacy'),
        ),
        ListTile(
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://example.com/terms'),
        ),
        ListTile(
          title: const Text('Open Source Licenses'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'SAP CCO Mobile Agent',
              applicationVersion: '1.0.0',
            );
          },
        ),
      ],
    );
  }

  void _showLanguageDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'English',
            'Spanish',
            'French',
            'German',
            'Chinese',
          ].map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: settings.voiceLanguage,
              onChanged: (value) {
                if (value != null) {
                  settings.setVoiceLanguage(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeName(mode)),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _confirmClearData(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear ${type == 'chat' ? 'Chat' : 'Scan'} History'),
        content: Text('This will delete all $type data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (type == 'chat') {
                context.read<ChatProvider>().clearChat();
              } else {
                context.read<ScannerProvider>().clearHistory();
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${type == 'chat' ? 'Chat' : 'Scan'} history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
