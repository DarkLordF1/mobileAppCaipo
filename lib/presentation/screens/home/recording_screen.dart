import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/base_screen.dart';
import 'package:path/path.dart' as path;

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  RecordingScreenState createState() => RecordingScreenState();
}

class RecordingScreenState extends State<RecordingScreen> with TickerProviderStateMixin, ScreenAnimationMixin {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  
  // Animation variables for staggered animations
  late Animation<double> _headerAnimation;
  late Animation<double> _audioVisualizerAnimation;
  late Animation<double> _controlsAnimation;
  late Animation<double> _recentRecordingsAnimation;
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  
  String? _audioFilePath;
  File? _videoFile;
  
  int _recordingDuration = 0;
  int _playbackPosition = 0;
  final int _audioDuration = 0;
  RecordingType _recordingType = RecordingType.audio;
  
  final List<String> _qualities = ['Low', 'Medium', 'High'];
  String _selectedQuality = 'Medium';
  
  List<RecordingFile> _recentRecordings = [];
  
  RecorderController? _recorderController;
  PlayerController? _playerController;
  
  late TabController _tabController;
  Timer? _timer;
  
  // Animation controllers for enhanced UX
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  
  final bool _isHoveringRecord = false;
  final bool _isHoveringPlay = false;
  final bool _isHoveringPause = false;
  
  // For hover effects
  final Map<String, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        setState(() => _recordingType = RecordingType.audio);
      } else {
        setState(() => _recordingType = RecordingType.video);
      }
    });
    
    // Initialize screen animations
    screenAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: screenAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Create staggered animations
    _headerAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.0, 
      endInterval: 0.6, 
      curve: Curves.easeOutCubic
    );
    
    _audioVisualizerAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.1, 
      endInterval: 0.7, 
      curve: Curves.easeOutCubic
    );
    
    _controlsAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.2, 
      endInterval: 0.8, 
      curve: Curves.easeOutCubic
    );
    
    _recentRecordingsAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.3, 
      endInterval: 0.9, 
      curve: Curves.easeOutCubic
    );
    
    // Initialize pulse animation
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    screenAnimationController.forward();
    
    _initRecorders();
    _loadRecentRecordings();
  }

  Future<void> _initRecorders() async {
    try {
      await _checkPermissions();
      await _audioRecorder.openRecorder();
      await _audioPlayer.openPlayer();
      
      _recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = 44100;
        
      _playerController = PlayerController();
    } catch (e) {
      print('Error initializing recorders: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    final cameraStatus = await Permission.camera.request();
    
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
    
    if (!_hasPermission && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Microphone Permission Required',
            style: themeProvider.headlineMedium,
          ),
          content: Text(
            'This app needs microphone access to record audio. Please grant permission in settings.',
            style: themeProvider.bodyMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeProvider.borderRadius),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: themeProvider.textButtonStyle,
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              style: themeProvider.primaryButtonStyle,
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recording Help', style: themeProvider.headlineMedium),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'Audio Recording',
                'Tap the Record button to start recording audio. You can pause and resume at any time.',
                Icons.mic,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Video Recording',
                'Switch to the Video tab and tap the camera button to record a video.',
                Icons.videocam,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Playback',
                'Tap on any recording to play it back. Use the play button on audio recordings.',
                Icons.play_arrow,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Transcription',
                'For audio recordings, use the menu to transcribe speech to text.',
                Icons.text_fields,
                themeProvider,
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: themeProvider.primaryButtonStyle,
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: themeProvider.accentColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: themeProvider.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            description,
            style: themeProvider.bodyMedium,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return GradientScaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: screenAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _headerAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _headerAnimation.value)),
                child: Text(
                  "Voice & Video Recorder",
                  style: themeProvider.headlineLarge.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelpDialog,
            tooltip: 'Recording Help',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: themeProvider.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          tabs: const [
            Tab(text: "AUDIO"),
            Tab(text: "VIDEO"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAudioRecordingTab(isDarkMode, themeProvider),
          _buildVideoRecordingTab(isDarkMode, themeProvider),
        ],
      ),
    );
  }

  Widget _buildAudioRecordingTab(bool isDarkMode, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Audio visualizer
          AnimatedBuilder(
            animation: screenAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _audioVisualizerAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _audioVisualizerAnimation.value)),
                  child: _buildAudioVisualizer(isDarkMode, themeProvider),
                ),
              );
            }
          ),
          
          const SizedBox(height: 16),
          
          // Recording duration
          if (_isRecording)
            AnimatedBuilder(
              animation: screenAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _audioVisualizerAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _audioVisualizerAnimation.value)),
                    child: Text(
                      _formatDuration(_recordingDuration),
                      style: themeProvider.displayLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isPaused ? themeProvider.secondaryTextColor : themeProvider.primaryTextColor,
                      ),
                    ),
                  ),
                );
              }
            ),
            
          const SizedBox(height: 24),
          
          // Recording controls
          AnimatedBuilder(
            animation: screenAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _controlsAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _controlsAnimation.value)),
                  child: _buildRecordingControls(isDarkMode, themeProvider),
                ),
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // Recent recordings
          Expanded(
            child: AnimatedBuilder(
              animation: screenAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _recentRecordingsAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _recentRecordingsAnimation.value)),
                    child: _buildRecentRecordings(isDarkMode, themeProvider),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoRecordingTab(bool isDarkMode, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Video preview with enhanced styling
          AnimatedBuilder(
            animation: screenAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _audioVisualizerAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _audioVisualizerAnimation.value)),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black26 : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _videoFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                            child: Image.asset(
                              'assets/video_thumbnail.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                size: 64,
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap the button below to start recording',
                                style: themeProvider.bodyLarge.copyWith(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            }
          ),
          
          const SizedBox(height: 32),
          
          // Video recording button with enhanced styling and animations
          AnimatedBuilder(
            animation: screenAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _controlsAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _controlsAnimation.value)),
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.errorColor,
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.errorColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.redAccent,
                            Colors.red.shade900,
                          ],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _pickVideo,
                          customBorder: const CircleBorder(),
                          child: const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          
          const SizedBox(height: 40),
          
          // Recent video recordings with theme styling
          Expanded(
            child: AnimatedBuilder(
              animation: screenAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _recentRecordingsAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _recentRecordingsAnimation.value)),
                    child: _buildRecentRecordings(isDarkMode, themeProvider, audioOnly: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer(bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isRecording
          ? AudioWaveforms(
              size: Size(MediaQuery.of(context).size.width - 40, 180),
              recorderController: _recorderController!,
              waveStyle: WaveStyle(
                waveColor: _isPaused 
                    ? Colors.grey 
                    : themeProvider.accentColor,
                extendWaveform: true,
                showMiddleLine: false,
                spacing: 8.0,
                waveThickness: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
              ),
            )
          : Center(
              child: _audioFilePath != null && _isPlaying
                  ? AudioFileWaveforms(
                      size: Size(MediaQuery.of(context).size.width - 40, 180),
                      playerController: _playerController!,
                      enableSeekGesture: true,
                      playerWaveStyle: PlayerWaveStyle(
                        fixedWaveColor: themeProvider.accentColor.withOpacity(0.5),
                        liveWaveColor: themeProvider.accentColor,
                        showBottom: false,
                        spacing: 8.0,
                        waveCap: StrokeCap.round,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: Colors.transparent,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none,
                          size: 64,
                          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _audioFilePath != null 
                              ? 'Ready to play recording' 
                              : 'Tap the microphone button to start',
                          style: themeProvider.bodyLarge.copyWith(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildRecordingControls(bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white.withOpacity(0.8),
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
        children: [
          // Quality selector
          if (!_isRecording && !_isPlaying)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Quality: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedQuality,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedQuality = newValue;
                      });
                    }
                  },
                  items: _qualities.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isRecording && _audioFilePath != null)
                _buildControlButton(
                  onPressed: () => _playAudio(_audioFilePath!),
                  icon: _isPlaying ? Icons.stop : Icons.play_arrow,
                  label: _isPlaying ? 'Stop' : 'Play',
                  color: Colors.green,
                  themeProvider: themeProvider,
                ),
                
              if (!_isPlaying)
                _buildControlButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: _isRecording ? Icons.stop : Icons.mic,
                  label: _isRecording ? 'Stop' : 'Record',
                  color: _isRecording ? Colors.red : Colors.blueAccent,
                  isLoading: _isProcessing,
                  themeProvider: themeProvider,
                ),
                
              if (_isRecording)
                _buildControlButton(
                  onPressed: _pauseRecording,
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  label: _isPaused ? 'Resume' : 'Pause',
                  color: Colors.orange,
                  themeProvider: themeProvider,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
    bool isHovering = false,
    Function(bool)? onHover,
    required ThemeProvider themeProvider,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: themeProvider.animationDurationShort,
            width: isHovering ? 68 : 64,
            height: isHovering ? 68 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isHovering ? 0.4 : 0.3),
                  blurRadius: isHovering ? 12 : 8,
                  spreadRadius: isHovering ? 3 : 2,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  Color.lerp(color, Colors.black, 0.3) ?? color,
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      )
                    : Icon(
                        icon,
                        color: Colors.white,
                        size: isHovering ? 36 : 32,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: themeProvider.titleMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordings(bool isDarkMode, ThemeProvider themeProvider, {bool audioOnly = true}) {
    final filteredRecordings = audioOnly
        ? _recentRecordings.where((rec) => rec.isAudio).toList()
        : _recentRecordings.where((rec) => !rec.isAudio).toList();
    
    if (filteredRecordings.isEmpty) {
      return Center(
        child: Text(
          'No recordings yet',
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            'Recent Recordings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredRecordings.length,
            itemBuilder: (context, index) {
              final recording = filteredRecordings[index];
              return _buildRecordingItem(recording, isDarkMode, themeProvider);
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Safely close audio recorder and player
    try {
      _audioRecorder.closeRecorder();
    } catch (e) {
      print('Error closing recorder: $e');
    }
    
    try {
      _audioPlayer.closePlayer();
    } catch (e) {
      print('Error closing player: $e');
    }
    
    // Safely dispose controllers
    try {
      _recorderController?.dispose();
    } catch (e) {
      print('Error disposing recorder controller: $e');
    }
    
    try {
      _playerController?.dispose();
    } catch (e) {
      print('Error disposing player controller: $e');
    }
    
    try {
      _tabController.dispose();
    } catch (e) {
      print('Error disposing tab controller: $e');
    }
    
    try {
      _pulseAnimationController.dispose();
    } catch (e) {
      print('Error disposing pulse animation controller: $e');
    }
    
    // Stop animation controller if it's still running
    try {
      if (screenAnimationController.isAnimating) {
        screenAnimationController.stop();
      }
      // Don't dispose screenAnimationController as it's handled by the mixin
    } catch (e) {
      print('Error stopping screen animation controller: $e');
    }
    
    super.dispose();
  }

  Future<void> _loadRecentRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      setState(() {
        _recentRecordings = files
            .where((file) => file is File && 
                (file.path.endsWith('.aac') || file.path.endsWith('.mp4')))
            .map((file) => RecordingFile(
                  file: file as File,
                  name: path.basename(file.path),
                  date: file.statSync().modified,
                  isAudio: file.path.endsWith('.aac'),
                ))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (e) {
      print('Error loading recordings: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkPermissions();
      if (!_hasPermission) return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      _audioFilePath = '${directory.path}/recording_$timestamp.aac';

      await _audioRecorder.startRecorder(
        toFile: _audioFilePath,
        codec: Codec.aacADTS,
      );

      await _recorderController?.record();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() => _isProcessing = true);
      
      _timer?.cancel();
      await _audioRecorder.stopRecorder();
      await _recorderController?.stop();

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _isProcessing = false;
      });

      await _loadRecentRecordings();
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pauseRecording() async {
    try {
      if (_isPaused) {
        await _audioRecorder.resumeRecorder();
        await _recorderController?.record();
      } else {
        await _audioRecorder.pauseRecorder();
        await _recorderController?.pause();
      }

      setState(() {
        _isPaused = !_isPaused;
      });
    } catch (e) {
      print('Error pausing/resuming recording: $e');
    }
  }

  Future<void> _playAudio(String filePath) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stopPlayer();
        await _playerController?.stopAllPlayers();
        setState(() {
          _isPlaying = false;
          _playbackPosition = 0;
        });
      } else {
        await _playerController?.preparePlayer(
          path: filePath,
          shouldExtractWaveform: true,
        );
        
        await _audioPlayer.startPlayer(
          fromURI: filePath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
              _playbackPosition = 0;
            });
          },
        );
        
        await _playerController?.startPlayer();
        
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        setState(() {
          _videoFile = File(video.path);
        });
        
        await _loadRecentRecordings();
      }
    } catch (e) {
      print('Error picking video: $e');
    }
  }

  Widget _buildRecordingItem(RecordingFile recording, bool isDarkMode, ThemeProvider themeProvider) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[recording.name] = true),
      onExit: (_) => setState(() => _hoverStates[recording.name] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _hoverStates[recording.name] == true
                ? isDarkMode
                    ? [
                        themeProvider.accentColor.withOpacity(0.15),
                        themeProvider.accentColor.withOpacity(0.05),
                      ]
                    : [
                        themeProvider.accentColor.withOpacity(0.15),
                        themeProvider.accentColor.withOpacity(0.05),
                      ]
                : isDarkMode
                    ? [
                        Colors.grey.shade900.withOpacity(0.7),
                        Colors.grey.shade900.withOpacity(0.5),
                      ]
                    : [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ],
          ),
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
          boxShadow: [
            BoxShadow(
              color: _hoverStates[recording.name] == true
                  ? themeProvider.accentColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _hoverStates[recording.name] == true ? 8 : 5,
              spreadRadius: _hoverStates[recording.name] == true ? 1 : 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: _hoverStates[recording.name] == true
                ? themeProvider.accentColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(themeProvider.borderRadius),
            onTap: recording.isAudio
                ? () => _playAudio(recording.file.path)
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlaybackScreen(
                          videoFile: recording.file,
                        ),
                      ),
                    ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: recording.isAudio
                            ? [
                                themeProvider.accentColor.withOpacity(0.2),
                                themeProvider.accentColor.withOpacity(0.1),
                              ]
                            : [
                                Colors.redAccent.withOpacity(0.2),
                                Colors.redAccent.withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                      boxShadow: [
                        BoxShadow(
                          color: (recording.isAudio ? themeProvider.accentColor : Colors.redAccent).withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      recording.isAudio ? Icons.mic : Icons.videocam,
                      color: recording.isAudio ? themeProvider.accentColor : Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.displayName,
                          style: themeProvider.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: themeProvider.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, y HH:mm').format(recording.date),
                          style: themeProvider.bodySmall.copyWith(
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                        if (_isPlaying && _audioFilePath == recording.file.path && recording.isAudio)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(
                              backgroundColor: themeProvider.accentColor.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(themeProvider.accentColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (recording.isAudio)
                        IconButton(
                          icon: Icon(
                            _isPlaying && _audioFilePath == recording.file.path
                                ? Icons.stop
                                : Icons.play_arrow,
                            color: _hoverStates[recording.name] == true
                                ? themeProvider.accentColor
                                : themeProvider.secondaryIconColor,
                          ),
                          onPressed: () => _playAudio(recording.file.path),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: _hoverStates[recording.name] == true
                              ? themeProvider.accentColor
                              : themeProvider.secondaryIconColor,
                        ),
                        onPressed: () => _showRecordingOptions(recording, themeProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showRecordingOptions(RecordingFile recording, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.modalBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(themeProvider.borderRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.play_circle_fill,
                color: themeProvider.accentColor,
              ),
              title: Text(
                'Play',
                style: themeProvider.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                if (recording.isAudio) {
                  _playAudio(recording.file.path);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlaybackScreen(
                        videoFile: recording.file,
                      ),
                    ),
                  );
                }
              },
            ),
            if (recording.isAudio)
              ListTile(
                leading: Icon(
                  Icons.text_fields,
                  color: themeProvider.accentColor,
                ),
                title: Text(
                  'Transcribe',
                  style: themeProvider.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/transcription',
                    arguments: recording.file.path,
                  );
                },
              ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: themeProvider.accentColor,
              ),
              title: Text(
                'Share',
                style: themeProvider.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sharing coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: themeProvider.accentColor,
              ),
              title: Text(
                'Rename',
                style: themeProvider.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(recording, themeProvider);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: themeProvider.errorColor,
              ),
              title: Text(
                'Delete',
                style: themeProvider.bodyLarge.copyWith(
                  color: themeProvider.errorColor,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                _confirmDelete(recording, themeProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRenameDialog(RecordingFile recording, ThemeProvider themeProvider) {
    final TextEditingController nameController = TextEditingController();
    nameController.text = recording.name.split('.').first;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Recording', style: themeProvider.headlineMedium),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
            ),
          ),
          autofocus: true,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: themeProvider.textButtonStyle,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implement rename functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rename feature coming soon')),
              );
            },
            style: themeProvider.primaryButtonStyle,
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete(RecordingFile recording, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recording', style: themeProvider.headlineMedium),
        content: Text(
          'Are you sure you want to delete "${recording.displayName}"? This cannot be undone.',
          style: themeProvider.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: themeProvider.textButtonStyle,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await recording.file.delete();
                _loadRecentRecordings();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recording deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                print('Error deleting recording: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting recording: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

enum RecordingType {
  audio,
  video,
}

class RecordingFile {
  final File file;
  final String name;
  final DateTime date;
  final bool isAudio;
  
  RecordingFile({
    required this.file,
    required this.name,
    required this.date,
    required this.isAudio,
  });
  
  String get displayName {
    if (name.length > 20) {
      return '${name.substring(0, 15)}...${name.substring(name.length - 5)}';
    }
    return name;
  }
}

class VideoPlaybackScreen extends StatefulWidget {
  final File videoFile;
  const VideoPlaybackScreen({super.key, required this.videoFile});

  @override
  State<VideoPlaybackScreen> createState() => _VideoPlaybackScreenState();
}

class _VideoPlaybackScreenState extends State<VideoPlaybackScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _currentPosition = 0;
  double _totalDuration = 0;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.file(widget.videoFile);
      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _totalDuration = _controller!.value.duration.inMilliseconds.toDouble();
      });
      
      // Add listener for position updates
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
            _currentPosition = _controller!.value.position.inMilliseconds.toDouble();
          });
        }
      });
      
      await _controller!.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          "Video Playback",
          style: themeProvider.headlineLarge.copyWith(
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: _isInitialized && _controller != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Video with controls overlay
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video player
                        VideoPlayer(_controller!),
                        
                        // Play/pause button overlay
                        AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 0.7,
                          duration: const Duration(milliseconds: 300),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPlaying ? _controller!.pause() : _controller!.play();
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                        
                        // Progress indicator and controls at bottom
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            color: Colors.black54,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Progress slider
                                Slider(
                                  value: _currentPosition,
                                  min: 0.0,
                                  max: _totalDuration,
                                  activeColor: themeProvider.accentColor,
                                  inactiveColor: Colors.grey.shade700,
                                  onChanged: (value) {
                                    setState(() {
                                      _currentPosition = value;
                                      _controller!.seekTo(Duration(milliseconds: value.toInt()));
                                    });
                                  },
                                ),
                                
                                // Time and controls
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Current time
                                      Text(
                                        _formatDuration(Duration(milliseconds: _currentPosition.toInt())),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      
                                      // Control buttons
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.replay_10, color: Colors.white),
                                            onPressed: () {
                                              final position = _controller!.value.position;
                                              final newPosition = position - const Duration(seconds: 10);
                                              _controller!.seekTo(newPosition);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _isPlaying ? Icons.pause : Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (_isPlaying) {
                                                  _controller!.pause();
                                                } else {
                                                  _controller!.play();
                                                }
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.forward_10, color: Colors.white),
                                            onPressed: () {
                                              final position = _controller!.value.position;
                                              final newPosition = position + const Duration(seconds: 10);
                                              _controller!.seekTo(newPosition);
                                            },
                                          ),
                                        ],
                                      ),
                                      
                                      // Total duration
                                      Text(
                                        _formatDuration(Duration(milliseconds: _totalDuration.toInt())),
                                        style: const TextStyle(color: Colors.white),
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
                  
                  // Video information
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black26 : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius),
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
                        Text(
                          path.basename(widget.videoFile.path),
                          style: themeProvider.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: themeProvider.secondaryIconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(_controller!.value.duration),
                              style: themeProvider.bodyMedium,
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: themeProvider.secondaryIconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y').format(widget.videoFile.statSync().modified),
                              style: themeProvider.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: themeProvider.bodyLarge,
                  ),
                ],
              ),
      ),
    );
  }
}
