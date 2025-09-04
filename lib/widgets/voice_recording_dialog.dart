import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class VoiceRecordingDialog extends StatefulWidget {
  final Function(String) onTextRecognized;

  const VoiceRecordingDialog({
    super.key,
    required this.onTextRecognized,
  });

  @override
  State<VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<VoiceRecordingDialog>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  double _confidence = 0.0;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _startListening();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    final settings = context.read<SettingsProvider>();
    bool available = await _speechToText.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );

    if (available) {
      setState(() {
        _isListening = true;
        _errorMessage = null;
      });

      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _getLocaleId(settings.voiceLanguage),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    } else {
      setState(() {
        _errorMessage = 'Speech recognition not available';
      });
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _recognizedText = result.recognizedWords;
      _confidence = result.confidence;
    });

    if (result.finalResult && _recognizedText.isNotEmpty) {
      widget.onTextRecognized(_recognizedText);
      final settings = context.read<SettingsProvider>();
      if (settings.autoSendVoice) {
        Navigator.of(context).pop();
      }
    }
  }

  void _onError(dynamic error) {
    setState(() {
      _errorMessage = 'Error: ${error.toString()}';
      _isListening = false;
    });
  }

  void _onStatus(String status) {
    print('Speech recognition status: $status');
    if (status == 'done' && _recognizedText.isEmpty) {
      setState(() {
        _errorMessage = 'No speech detected. Please try again.';
      });
    }
  }

  String _getLocaleId(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return 'es-ES';
      case 'french':
        return 'fr-FR';
      case 'german':
        return 'de-DE';
      case 'chinese':
        return 'zh-CN';
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isListening ? 'Listening...' : 'Voice Input',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      size: 48,
                      color: _isListening
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            if (_recognizedText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _recognizedText,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_confidence > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: _confidence,
                          backgroundColor: theme.colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _confidence > 0.7
                                ? Colors.green
                                : _confidence > 0.4
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                if (_isListening)
                  FilledButton.tonal(
                    onPressed: _stopListening,
                    child: const Text('Stop'),
                  )
                else
                  FilledButton.tonal(
                    onPressed: _startListening,
                    child: const Text('Retry'),
                  ),
                if (_recognizedText.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      widget.onTextRecognized(_recognizedText);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Use Text'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}