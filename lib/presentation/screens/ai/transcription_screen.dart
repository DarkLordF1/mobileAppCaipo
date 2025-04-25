import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import 'package:flutter/services.dart';

class TranscriptionScreen extends StatefulWidget {
  final String audioFilePath;
  
  const TranscriptionScreen({super.key, required this.audioFilePath});

  @override
  TranscriptionScreenState createState() => TranscriptionScreenState();
}

class TranscriptionScreenState extends State<TranscriptionScreen> with SingleTickerProviderStateMixin {
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _isTranscribed = false;
  bool _isEditing = false;
  double _transcriptionProgress = 0.0;
  String _transcriptionText = '';
  String _originalText = '';
  int _playbackPosition = 0;
  int _audioDuration = 0;
  Timer? _progressTimer;
  Timer? _playbackTimer;
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Confidence levels for segments (simulated)
  List<Map<String, dynamic>> _segments = [];
  
  // Language options
  String _selectedLanguage = 'English (US)';
  final List<String> _languages = [
    'English (US)', 
    'English (UK)', 
    'Spanish', 
    'French', 
    'German',
    'Japanese',
    'Mandarin',
    'Hindi',
    'Arabic'
  ];
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Hover states
  final Map<String, bool> _hoverStates = {};

  // Hover state variables
  bool _isResultsHovered = false;
  bool _isCopyHovered = false;
  bool _isExportHovered = false;
  bool _hasCopied = false;
  bool _isUploadHovered = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _initAnimations();
    if (widget.audioFilePath.isNotEmpty) {
      _startTranscription();
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _animationController.forward();
  }

  Future<void> _initPlayer() async {
    await _audioPlayer.openPlayer();
    
    if (widget.audioFilePath.isNotEmpty) {
      try {
        await _audioPlayer.startPlayer(
          fromURI: widget.audioFilePath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          },
        );
        
        await Future.delayed(const Duration(milliseconds: 200));
        final progress = await _audioPlayer.getProgress();
        _audioDuration = progress['duration']?.inMilliseconds ?? 0;
        
        await _audioPlayer.stopPlayer();
      } catch (e) {
        print('Error initializing player: $e');
      }
    }
  }

  void _startTranscription() {
    setState(() {
      _isProcessing = true;
      _transcriptionProgress = 0.0;
    });
    
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_transcriptionProgress < 1.0) {
        setState(() {
          _transcriptionProgress += 0.01;
        });
      } else {
        timer.cancel();
        _completeTranscription();
      }
    });
  }

  void _completeTranscription() {
    final transcription = '''
    Hello and welcome to CAIPO. Today I wanted to record some thoughts about the new project we're working on. 
    
    The app interface is coming along nicely, and I think the user experience improvements we've made will really enhance the overall usability. I'd like to focus on implementing the transcription service next, with advanced features like timestamps, speaker identification, and confidence scoring.
    
    We should also consider adding export options for different file formats. Users might want to save transcriptions as text, Word documents, or even subtitles for videos.
    
    Let's schedule a meeting for next Tuesday to review our progress and outline the next steps. I'll send out a calendar invite later today.
    
    That's all for now, thanks for listening.
    '''.trim();
    
    final List<Map<String, dynamic>> segments = [];
    final words = transcription.split(' ');
    final segmentSize = words.length ~/ 6;
    
    for (int i = 0; i < words.length; i += segmentSize) {
      final end = i + segmentSize < words.length ? i + segmentSize : words.length;
      final segment = words.sublist(i, end).join(' ');
      
      final confidence = 0.75 + (0.25 * (i / words.length));
      
      segments.add({
        'text': segment,
        'start': (i / words.length * _audioDuration).toInt(),
        'end': (end / words.length * _audioDuration).toInt(),
        'confidence': confidence,
      });
    }
    
    setState(() {
      _isProcessing = false;
      _isTranscribed = true;
      _transcriptionText = transcription;
      _originalText = transcription;
      _segments = segments;
      _textEditingController.text = transcription;
    });
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pausePlayer();
        _playbackTimer?.cancel();
      } else {
        if (_playbackPosition >= _audioDuration) {
          _playbackPosition = 0;
        }
        
        await _audioPlayer.startPlayer(
          fromURI: widget.audioFilePath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
              _playbackPosition = 0;
            });
            _playbackTimer?.cancel();
          },
        );
        
        _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
          final progress = await _audioPlayer.getProgress();
          final position = progress['position']?.inMilliseconds ?? 0;
          setState(() {
            _playbackPosition = position;
          });
          
          _highlightCurrentSegment(_playbackPosition);
        });
      }
      
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      print('Error toggling playback: $e');
    }
  }

  void _highlightCurrentSegment(int position) {
    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      if (position >= segment['start'] && position <= segment['end']) {
        // Could implement scrolling to the current segment here
      }
    }
  }

  void _seekToPosition(int position) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.seekToPlayer(Duration(milliseconds: position));
      }
      setState(() {
        _playbackPosition = position;
      });
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _textEditingController.text = _transcriptionText;
      } else {
        _transcriptionText = _textEditingController.text;
      }
    });
  }

  void _copyTranscriptionToClipboard() {
    if (_transcriptionText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _transcriptionText));
      setState(() {
        _hasCopied = true;
      });
      
      // Reset the copied state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _hasCopied = false;
          });
        }
      });
    }
  }

  void _exportTranscription() {
    // Implementation for exporting transcription as a text file
    // This would typically involve using a file_picker or similar package
    // to allow the user to choose where to save the file
    
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality will be implemented soon'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    // Implementation for picking an audio file
    // This would typically involve using a file_picker package
    
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File picker functionality will be implemented soon'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _playbackTimer?.cancel();
    _audioPlayer.closePlayer();
    _textEditingController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          'Audio Transcription',
          style: themeProvider.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeProvider.primaryTextColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
                    )),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24, top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: themeProvider.accentColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: themeProvider.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Convert your audio to text',
                                    style: themeProvider.titleLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Upload an audio file or record directly to transcribe. Supports multiple languages.',
                              style: themeProvider.bodyMedium.copyWith(
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Audio player
                  _buildAudioPlayer(isDarkMode, themeProvider),
                  
                  // Language selector
                  _buildLanguageSelector(isDarkMode, themeProvider),
                  
                  // Processing indicator (when transcribing)
                  if (_isProcessing) _buildProcessingIndicator(isDarkMode, themeProvider),
                  
                  // Transcription results
                  if (!_isProcessing && _transcriptionText.isNotEmpty)
                    _buildTranscriptionResults(isDarkMode, themeProvider),
                  
                  // Empty state when no audio is loaded
                  if (!_isProcessing && _transcriptionText.isEmpty)
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 48),
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.9, end: 1.0),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: themeProvider.accentColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.upload_file,
                                    size: 64,
                                    color: themeProvider.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Upload an audio file to start',
                                style: themeProvider.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Supported formats: MP3, WAV, M4A',
                                style: themeProvider.bodyMedium.copyWith(
                                  color: themeProvider.secondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              MouseRegion(
                                onEnter: (_) => setState(() => _isUploadHovered = true),
                                onExit: (_) => setState(() => _isUploadHovered = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  transform: Matrix4.identity()
                                    ..scale(_isUploadHovered ? 1.05 : 1.0),
                                  child: ElevatedButton.icon(
                                    onPressed: _pickAudioFile,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Select Audio File'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeProvider.accentColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(bool isDarkMode, ThemeProvider themeProvider) {
    final fileName = widget.audioFilePath.isNotEmpty 
        ? widget.audioFilePath.split('/').last
        : 'No file selected';
    
    final String playerKey = 'audio_player';
    final bool isHovered = _hoverStates[playerKey] ?? false;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[playerKey] = true),
      onExit: (_) => setState(() => _hoverStates[playerKey] = false),
      child: AnimatedContainer(
        duration: themeProvider.animationDurationShort,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? Colors.black.withOpacity(isHovered ? 0.4 : 0.3)
              : Colors.white.withOpacity(isHovered ? 1.0 : 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isHovered 
                  ? themeProvider.accentColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isHovered ? 12 : 8,
              spreadRadius: isHovered ? 2 : 1,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isHovered 
                ? themeProvider.accentColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: themeProvider.animationDurationShort,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.accentColor.withOpacity(isHovered ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isHovered ? [
                      BoxShadow(
                        color: themeProvider.accentColor.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ] : [],
                  ),
                  child: Icon(
                    Icons.mic,
                    color: themeProvider.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: themeProvider.titleMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _audioDuration > 0 
                            ? 'Duration: ${_formatDuration(_audioDuration)}'
                            : 'Loading duration...',
                        style: themeProvider.bodySmall.copyWith(
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_audioDuration > 0)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: isHovered ? 1.1 : 1.0,
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: Icon(
                              _isPlaying 
                                  ? Icons.pause_circle_filled 
                                  : Icons.play_circle_filled,
                              key: ValueKey<bool>(_isPlaying),
                              color: themeProvider.accentColor,
                              size: 36,
                            ),
                          ),
                          onPressed: _togglePlayback,
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (_audioDuration > 0) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: isHovered ? 8 : 6,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: isHovered ? 16 : 14,
                      ),
                      activeTrackColor: themeProvider.accentColor,
                      inactiveTrackColor: themeProvider.accentColor.withOpacity(0.2),
                      thumbColor: themeProvider.accentColor,
                      overlayColor: themeProvider.accentColor.withOpacity(0.3),
                    ),
                    child: Slider(
                      value: _playbackPosition.toDouble(),
                      min: 0,
                      max: _audioDuration.toDouble(),
                      onChanged: (value) {
                        _seekToPosition(value.toInt());
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_playbackPosition),
                          style: themeProvider.bodySmall.copyWith(
                            color: themeProvider.secondaryTextColor,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDuration(_audioDuration),
                          style: themeProvider.bodySmall.copyWith(
                            color: themeProvider.secondaryTextColor,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDarkMode, ThemeProvider themeProvider) {
    final String selectorKey = 'language_selector';
    final bool isHovered = _hoverStates[selectorKey] ?? false;
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_fadeAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverStates[selectorKey] = true),
          onExit: (_) => setState(() => _hoverStates[selectorKey] = false),
          child: AnimatedContainer(
            duration: themeProvider.animationDurationShort,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.black.withOpacity(isHovered ? 0.4 : 0.3)
                  : Colors.white.withOpacity(isHovered ? 1.0 : 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isHovered 
                      ? themeProvider.accentColor.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isHovered ? 12 : 8,
                  spreadRadius: isHovered ? 2 : 1,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isHovered 
                    ? themeProvider.accentColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: themeProvider.animationDurationShort,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor.withOpacity(isHovered ? 0.3 : 0.2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isHovered ? [
                          BoxShadow(
                            color: themeProvider.accentColor.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : [],
                      ),
                      child: Icon(
                        Icons.language,
                        color: themeProvider.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Transcription Language',
                      style: themeProvider.titleMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _languages.map((language) {
                    final isSelected = _selectedLanguage == language;
                    final langKey = 'lang_${language.toLowerCase().replaceAll(' ', '_')}';
                    final isLangHovered = _hoverStates[langKey] ?? false;
                    
                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoverStates[langKey] = true),
                      onExit: (_) => setState(() => _hoverStates[langKey] = false),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLanguage = language;
                          });
                        },
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 1.0,
                            end: isLangHovered ? 1.05 : 1.0,
                          ),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration: themeProvider.animationDurationShort,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 8
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? themeProvider.accentColor.withOpacity(isLangHovered ? 0.3 : 0.2)
                                      : isDarkMode
                                          ? (isLangHovered ? Colors.grey.shade700 : Colors.grey.shade800)
                                          : (isLangHovered ? Colors.grey.shade100 : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected 
                                        ? themeProvider.accentColor 
                                        : isLangHovered
                                            ? themeProvider.accentColor.withOpacity(0.3)
                                            : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: isLangHovered ? [
                                    BoxShadow(
                                      color: isSelected
                                          ? themeProvider.accentColor.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected || isLangHovered)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Icon(
                                          isSelected ? Icons.check_circle : Icons.language,
                                          size: 14,
                                          color: isSelected
                                              ? themeProvider.accentColor
                                              : isDarkMode
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                        ),
                                      ),
                                    Text(
                                      language,
                                      style: themeProvider.bodyMedium.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? themeProvider.accentColor
                                            : isDarkMode
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator(bool isDarkMode, ThemeProvider themeProvider) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_fadeAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 2 * 3.14159),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value,
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.settings,
                      color: themeProvider.accentColor,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
                  ),
                  child: Text(
                    'Transcribing Audio',
                    style: themeProvider.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.9, curve: Curves.easeIn),
                  ),
                  child: Text(
                    'This may take a few moments...',
                    style: themeProvider.bodyMedium.copyWith(
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.accentColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: LinearProgressIndicator(
                      value: _transcriptionProgress,
                      backgroundColor: themeProvider.accentColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(themeProvider.accentColor),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _transcriptionProgress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return Text(
                    '${(value * 100).toInt()}%',
                    style: themeProvider.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.accentColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: themeProvider.accentColor.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      'CAIPO is using AI to convert your audio to text',
                      style: themeProvider.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: themeProvider.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptionResults(bool isDarkMode, ThemeProvider themeProvider) {
    if (_transcriptionText.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_fadeAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isResultsHovered = true),
          onExit: (_) => setState(() => _isResultsHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.all(_isResultsHovered ? 12 : 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[900]!.withOpacity(_isResultsHovered ? 0.9 : 0.7)
                  : Colors.white.withOpacity(_isResultsHovered ? 1.0 : 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isResultsHovered ? 0.2 : 0.1),
                  blurRadius: _isResultsHovered ? 12 : 8,
                  spreadRadius: _isResultsHovered ? 2 : 1,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: themeProvider.accentColor.withOpacity(_isResultsHovered ? 0.3 : 0.1),
                width: _isResultsHovered ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
                      )),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.1, 0.6, curve: Curves.easeIn),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: themeProvider.accentColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.text_fields,
                                color: themeProvider.accentColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Transcription Results',
                              style: themeProvider.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
                      )),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.2, 0.7, curve: Curves.easeIn),
                        ),
                        child: Row(
                          children: [
                            MouseRegion(
                              onEnter: (_) => setState(() => _isCopyHovered = true),
                              onExit: (_) => setState(() => _isCopyHovered = false),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 1.0,
                                  end: _isCopyHovered ? 1.1 : 1.0,
                                ),
                                duration: const Duration(milliseconds: 200),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: IconButton(
                                  onPressed: _copyTranscriptionToClipboard,
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return ScaleTransition(scale: animation, child: child);
                                    },
                                    child: _hasCopied
                                        ? Icon(
                                            Icons.check_circle,
                                            key: const ValueKey('check'),
                                            color: Colors.green,
                                          )
                                        : Icon(
                                            Icons.copy,
                                            key: const ValueKey('copy'),
                                            color: themeProvider.accentColor,
                                          ),
                                  ),
                                  tooltip: 'Copy to clipboard',
                                ),
                              ),
                            ),
                            MouseRegion(
                              onEnter: (_) => setState(() => _isExportHovered = true),
                              onExit: (_) => setState(() => _isExportHovered = false),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 1.0,
                                  end: _isExportHovered ? 1.1 : 1.0,
                                ),
                                duration: const Duration(milliseconds: 200),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: IconButton(
                                  onPressed: _exportTranscription,
                                  icon: Icon(
                                    Icons.download,
                                    color: themeProvider.accentColor,
                                  ),
                                  tooltip: 'Export as text file',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey[100]!.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.accentColor.withOpacity(0.1),
                        ),
                      ),
                      child: SelectableText(
                        _transcriptionText,
                        style: themeProvider.bodyLarge.copyWith(
                          height: 1.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeProvider.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: themeProvider.accentColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Transcribed in ${_selectedLanguage.toUpperCase()}',
                                style: themeProvider.bodySmall.copyWith(
                                  color: themeProvider.secondaryTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 