import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
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
  String _transcription = "Processing...";
  bool _isLoading = true;
  bool _hasError = false;
  double _progress = 0.0;
  late StreamSubscription<double> _progressSubscription;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Hover states
  final Map<String, bool> _hoverStates = {};
  bool _isRetryHovered = false;
  bool _isExportHovered = false;
  bool _isCopyHovered = false;
  bool _hasCopied = false;

  @override
  void initState() {
    super.initState();
    _setupProgressListener();
    _fetchTranscription();
    _initAnimations();
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

  void _setupProgressListener() {
    _progressSubscription = TranscriptionService().progressStream.listen((progress) {
      setState(() {
        _progress = progress;
      });
    });
  }

  @override
  void dispose() {
    _progressSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTranscription() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await TranscriptionService().transcribeAudio(
        audioFilePath: widget.audioFilePath,
      );
      setState(() {
        _transcription = result['transcription'] as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _transcription = "Error processing transcription.";
        _isLoading = false;
        _hasError = true;
      });
    }
  }
  
  void _copyTranscriptionToClipboard() {
    if (_transcription.isNotEmpty && _transcription != "Processing..." && !_hasError) {
      Clipboard.setData(ClipboardData(text: _transcription));
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
      
      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transcription copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  void _exportTranscription() {
    if (_transcription.isNotEmpty && _transcription != "Processing..." && !_hasError) {
      // Implementation for exporting transcription as a text file
      // This would typically involve using a file_picker or similar package
      
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
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          "AI Transcription",
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
        actions: [
          if (!_isLoading && !_hasError && _transcription != "Processing...")
            Row(
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
                                color: themeProvider.primaryTextColor,
                              ),
                      ),
                      onPressed: _copyTranscriptionToClipboard,
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
                      icon: Icon(
                        Icons.download,
                        color: themeProvider.primaryTextColor,
                      ),
                      onPressed: _exportTranscription,
                      tooltip: 'Export as text file',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
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
                        margin: const EdgeInsets.only(bottom: 24),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Transcript",
                                    style: themeProvider.titleLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "AI-powered audio transcription",
                                    style: themeProvider.bodyMedium.copyWith(
                                      color: themeProvider.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  if (_isLoading) _buildLoadingIndicator(isDarkMode, themeProvider),
                  
                  if (!_isLoading) Expanded(
                    child: _hasError
                        ? _buildErrorState(isDarkMode, themeProvider)
                        : _buildTranscriptionContent(isDarkMode, themeProvider),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDarkMode, ThemeProvider themeProvider) {
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
                      value: _progress,
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
                tween: Tween<double>(begin: 0, end: _progress),
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

  Widget _buildErrorState(bool isDarkMode, ThemeProvider themeProvider) {
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
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
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
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
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
                    'Failed to transcribe audio',
                    style: themeProvider.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    'There was an error processing your audio file. Please try again.',
                    style: themeProvider.bodyMedium.copyWith(
                      color: themeProvider.secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
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
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isRetryHovered = true),
                    onExit: (_) => setState(() => _isRetryHovered = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..scale(_isRetryHovered ? 1.05 : 1.0),
                      child: ElevatedButton.icon(
                        onPressed: _fetchTranscription,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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
                          elevation: _isRetryHovered ? 4 : 2,
                        ),
                      ),
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

  Widget _buildTranscriptionContent(bool isDarkMode, ThemeProvider themeProvider) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_fadeAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverStates['transcription'] = true),
          onExit: (_) => setState(() => _hoverStates['transcription'] = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[900]!.withOpacity(_hoverStates['transcription'] == true ? 0.9 : 0.7)
                  : Colors.white.withOpacity(_hoverStates['transcription'] == true ? 1.0 : 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hoverStates['transcription'] == true ? 0.2 : 0.1),
                  blurRadius: _hoverStates['transcription'] == true ? 12 : 8,
                  spreadRadius: _hoverStates['transcription'] == true ? 2 : 1,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: themeProvider.accentColor.withOpacity(_hoverStates['transcription'] == true ? 0.3 : 0.1),
                width: _hoverStates['transcription'] == true ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
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
                  ],
                ),
                const SizedBox(height: 24),
                Container(
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
                    _transcription,
                    style: themeProvider.bodyLarge.copyWith(
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
                            'Transcribed with CAIPO AI',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A service for handling audio transcription using AI
class TranscriptionService {
  static final TranscriptionService _instance = TranscriptionService._internal();
  
  // Factory constructor to return the same instance
  factory TranscriptionService() {
    return _instance;
  }
  
  TranscriptionService._internal();
  
  /// Cache for storing transcriptions to avoid re-processing
  final Map<String, Map<String, dynamic>> _transcriptionCache = {};
  
  /// Stream controller for tracking transcription progress
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  
  /// Get the stream of transcription progress (0.0 to 1.0)
  Stream<double> get progressStream => _progressController.stream;
  
  /// Transcribe an audio file
  /// 
  /// Parameters:
  /// - [audioFilePath]: Path to the audio file to transcribe
  /// - [language]: Language code (e.g., 'en-US', 'es', 'fr')
  /// - [useCache]: Whether to use cached results if available
  /// 
  /// Returns a map containing:
  /// - transcription: The full text transcription
  /// - segments: List of segments with timing information
  /// - confidence: Overall confidence score
  /// - language: Detected or specified language
  Future<Map<String, dynamic>> transcribeAudio({
    required String audioFilePath,
    String language = 'en-US',
    bool useCache = true,
  }) async {
    // Check cache first if enabled
    final fileKey = '$audioFilePath:$language';
    if (useCache && _transcriptionCache.containsKey(fileKey)) {
      return _transcriptionCache[fileKey]!;
    }
    
    // In a real implementation, this would connect to an API service
    // For demo purposes, we'll simulate the process
    
    // Simulate processing time
    final file = File(audioFilePath);
    final fileSize = await file.length();
    
    // Large files take longer to process
    final processingTime = Duration(milliseconds: 5000 + (fileSize ~/ 10000));
    final totalSteps = 100;
    
    // Simulate progress updates
    for (int i = 0; i < totalSteps; i++) {
      await Future.delayed(Duration(milliseconds: processingTime.inMilliseconds ~/ totalSteps));
      _progressController.add(i / totalSteps);
    }
    
    // Generate sample transcription data
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Create a simulated response
    final result = await _generateSimulatedTranscription(
      audioFilePath: audioFilePath,
      language: language,
    );
    
    // Cache the result
    _transcriptionCache[fileKey] = result;
    
    // Artificial delay to show 100% progress
    await Future.delayed(const Duration(milliseconds: 200));
    _progressController.add(1.0);
    
    return result;
  }
  
  /// Clear the transcription cache
  Future<void> clearCache() async {
    _transcriptionCache.clear();
    
    // Also clear any cached files
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('transcription_cache_keys');
    
    try {
      final cacheDir = await _getCacheDirectory();
      final cacheFiles = await cacheDir.list().where(
        (entity) => entity is File && entity.path.endsWith('.json')
      ).toList();
      
      for (final file in cacheFiles) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache files: $e');
    }
  }
  
  /// Persist the cache to disk
  Future<void> persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = _transcriptionCache.keys.toList();
      await prefs.setStringList('transcription_cache_keys', cacheKeys);
      
      final cacheDir = await _getCacheDirectory();
      
      // Save each transcription to a file
      for (final key in cacheKeys) {
        final data = _transcriptionCache[key]!;
        final file = File('${cacheDir.path}/${key.hashCode}.json');
        await file.writeAsString(jsonEncode(data));
      }
    } catch (e) {
      debugPrint('Error persisting cache: $e');
    }
  }
  
  /// Load the cache from disk
  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs.getStringList('transcription_cache_keys') ?? [];
      
      final cacheDir = await _getCacheDirectory();
      
      for (final key in cacheKeys) {
        final file = File('${cacheDir.path}/${key.hashCode}.json');
        if (await file.exists()) {
          final data = jsonDecode(await file.readAsString());
          _transcriptionCache[key] = Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
  }
  
  /// Get the cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/transcription_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  /// Generate a simulated transcription (for demo purposes)
  Future<Map<String, dynamic>> _generateSimulatedTranscription({
    required String audioFilePath,
    required String language,
  }) async {
    // Get the audio file duration for timing
    final audioDuration = await _getAudioDuration(audioFilePath);
    
    // For demo purposes, we'll generate a fixed transcription
    final text = '''
Hello and welcome to CAIPO. Today I wanted to record some thoughts about the new project we're working on. 

The app interface is coming along nicely, and I think the user experience improvements we've made will really enhance the overall usability. I'd like to focus on implementing the transcription service next, with advanced features like timestamps, speaker identification, and confidence scoring.

We should also consider adding export options for different file formats. Users might want to save transcriptions as text, Word documents, or even subtitles for videos.

Let's schedule a meeting for next Tuesday to review our progress and outline the next steps. I'll send out a calendar invite later today.

That's all for now, thanks for listening.
'''.trim();

    // Split into segments
    final words = text.split(' ');
    final segmentSize = words.length ~/ 6; // Divide into roughly 6 segments
    final List<Map<String, dynamic>> segments = [];
    
    for (int i = 0; i < words.length; i += segmentSize) {
      final end = i + segmentSize < words.length ? i + segmentSize : words.length;
      final segment = words.sublist(i, end).join(' ');
      
      // Generate a random confidence score between 0.75 and 1.0
      final confidence = 0.75 + (0.25 * (i / words.length));
      
      segments.add({
        'text': segment,
        'start': (i / words.length * audioDuration).toInt(),
        'end': (end / words.length * audioDuration).toInt(),
        'confidence': confidence,
      });
    }
    
    return {
      'transcription': text,
      'segments': segments,
      'confidence': 0.92,
      'language': language,
      'audioDuration': audioDuration,
    };
  }
  
  /// Get the duration of an audio file in milliseconds
  Future<int> _getAudioDuration(String filePath) async {
    // In a real implementation, you would use a proper audio plugin
    // For demo purposes, we'll return a fixed duration or estimated from file size
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      
      // Roughly estimate duration based on file size
      // Assuming ~16KB per second for a typical audio file
      final estimatedDuration = (fileSize / 16000).round() * 1000;
      return estimatedDuration.clamp(10000, 120000);
    } catch (e) {
      // Return a default duration if file can't be read
      return 60000; // 1 minute
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _progressController.close();
  }
}
