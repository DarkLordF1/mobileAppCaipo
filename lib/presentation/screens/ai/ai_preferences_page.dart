import 'package:flutter/material.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AIPreferencesPage extends StatefulWidget {
  const AIPreferencesPage({super.key});

  @override
  _AIPreferencesPageState createState() => _AIPreferencesPageState();
}

class _AIPreferencesPageState extends State<AIPreferencesPage> with SingleTickerProviderStateMixin {
  // AI Preferences
  bool adaptiveResponses = true;
  bool voiceFeedback = false;
  bool autoTranscribe = true;
  bool contextMemory = true;
  bool enhancedPrivacy = false;
  bool developerPreview = false;
  double responseSpeed = 0.5;
  double voiceVolume = 0.7;
  String selectedVoice = 'Natural';
  String selectedAIModel = 'Standard';
  
  // Language preferences
  String selectedLanguage = 'English';
  bool useDialect = false;
  String selectedDialect = 'American';
  
  // State variables
  bool _haveUnsavedChanges = false;
  bool _showConfirmation = false;
  bool _isProcessing = false;
  
  // Available options for dropdowns
  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese'];
  final List<String> _voices = ['Natural', 'Casual', 'Professional', 'Friendly'];
  final List<String> _aiModels = ['Standard', 'Advanced', 'Experimental'];
  final List<String> _englishDialects = ['American', 'British', 'Australian', 'Canadian', 'Indian'];

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Track hover states for interactive UI elements
  final Map<String, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedPreferences();
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  Future<void> _loadSavedPreferences() async {
    // Simulate loading from shared preferences or backend
    await Future.delayed(const Duration(milliseconds: 300));
    // In real app, would load from storage
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Check for unsaved changes before navigating back
  Future<bool> _onWillPop() async {
    if (!_haveUnsavedChanges) {
      return true;
    }
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unsaved Changes',
          style: themeProvider.headlineMedium,
        ),
        content: Text(
          'You have unsaved AI preference changes. Do you want to discard these changes?',
          style: themeProvider.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: themeProvider.textButtonStyle,
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.errorColor,
            ),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
  }

  void _updateSetting(String setting, dynamic value) {
    setState(() {
      switch (setting) {
        case 'adaptive':
          adaptiveResponses = value as bool;
          break;
        case 'voice':
          voiceFeedback = value as bool;
          break;
        case 'transcribe':
          autoTranscribe = value as bool;
          break;
        case 'memory':
          contextMemory = value as bool;
          break;
        case 'privacy':
          enhancedPrivacy = value as bool;
          break;
        case 'developer':
          developerPreview = value as bool;
          if (value == true) {
            _showDeveloperWarning();
          }
          break;
        case 'speed':
          responseSpeed = value as double;
          break;
        case 'volume':
          voiceVolume = value as double;
          break;
        case 'voiceType':
          selectedVoice = value as String;
          break;
        case 'aiModel':
          selectedAIModel = value as String;
          if (value == 'Experimental') {
            _showExperimentalWarning();
          }
          break;
        case 'language':
          selectedLanguage = value as String;
          break;
        case 'dialect':
          useDialect = value as bool;
          break;
        case 'dialectType':
          selectedDialect = value as String;
          break;
      }
      _haveUnsavedChanges = true;
    });
  }

  void _savePreferences() async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      // Simulate API call or saving to storage
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isProcessing = false;
        _showConfirmation = true;
        _haveUnsavedChanges = false;
      });
      
      // Hide confirmation after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showConfirmation = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: themeProvider.errorColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(themeProvider.borderRadius),
            ),
          ),
        );
      }
    }
  }
  
  void _showDeveloperWarning() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Developer Preview Features',
          style: themeProvider.headlineMedium,
        ),
        content: Text(
          'Developer preview features are experimental and may not work as expected. '
          'These features are provided for testing purposes only and should not be '
          'relied upon for critical tasks.',
          style: themeProvider.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: themeProvider.primaryButtonStyle,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showExperimentalWarning() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Experimental AI Model',
          style: themeProvider.headlineMedium,
        ),
        content: Text(
          'The experimental AI model offers cutting-edge capabilities but may be less '
          'stable and consume more resources. It is recommended only for testing '
          'advanced features.',
          style: themeProvider.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: themeProvider.primaryButtonStyle,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all AI preferences to their default values. '
          'This action cannot be undone. Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        // Reset to default values
        adaptiveResponses = true;
        voiceFeedback = false;
        autoTranscribe = true;
        contextMemory = true;
        enhancedPrivacy = false;
        developerPreview = false;
        responseSpeed = 0.5;
        voiceVolume = 0.7;
        selectedVoice = 'Natural';
        selectedAIModel = 'Standard';
        selectedLanguage = 'English';
        useDialect = false;
        selectedDialect = 'American';
        
        _haveUnsavedChanges = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default settings'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: GradientScaffold(
        appBar: AppBar(
          title: Text(
            'AI Preferences',
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
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            tooltip: 'Back',
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetToDefaults,
              tooltip: 'Reset to defaults',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: _showHelpDialog,
              tooltip: 'Help',
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildSectionHeader('Core AI Behavior', Icons.settings, themeProvider),
                      _buildSwitchTile(
                        title: 'Adaptive Responses',
                        subtitle: 'Allow AI to adapt its responses based on your interaction style',
                        value: adaptiveResponses,
                        icon: Icons.auto_awesome,
                        onChanged: (val) => _updateSetting('adaptive', val),
                        isDarkMode: isDarkMode,
                        themeProvider: themeProvider,
                      ),
                      _buildSwitchTile(
                        title: 'Context Memory',
                        subtitle: 'AI remembers previous conversations for improved relevance',
                        value: contextMemory,
                        icon: Icons.psychology,
                        onChanged: (val) => _updateSetting('memory', val),
                        isDarkMode: isDarkMode,
                        themeProvider: themeProvider,
                      ),
                      _buildProcessingSpeedCard(isDarkMode, themeProvider),
                      _buildAIModelSelector(isDarkMode, themeProvider),
                      
                      const SizedBox(height: 16),
                      _buildSectionHeader('Voice & Language', Icons.record_voice_over, themeProvider),
                      _buildSwitchTile(
                        title: 'Voice Feedback',
                        subtitle: 'Enable spoken responses from the AI assistant',
                        value: voiceFeedback,
                        icon: Icons.mic,
                        onChanged: (val) => _updateSetting('voice', val),
                        isDarkMode: isDarkMode,
                        themeProvider: themeProvider,
                      ),
                      if (voiceFeedback)
                        _buildVoiceSettingsCard(isDarkMode, themeProvider),
                      _buildSwitchTile(
                        title: 'Auto-Transcribe',
                        subtitle: 'Automatically transcribe your voice recordings',
                        value: autoTranscribe,
                        icon: Icons.text_fields,
                        onChanged: (val) => _updateSetting('transcribe', val),
                        isDarkMode: isDarkMode,
                        themeProvider: themeProvider,
                      ),
                      _buildLanguageSelector(isDarkMode, themeProvider),
                      if (selectedLanguage == 'English') 
                        _buildDialectSelector(isDarkMode, themeProvider),
                        
                      const SizedBox(height: 16),
                      _buildSectionHeader('Security & Advanced', Icons.shield, themeProvider),
                      _buildSwitchTile(
                        title: 'Enhanced Privacy',
                        subtitle: 'Limit data storage and disable conversation learning',
                        value: enhancedPrivacy,
                        icon: Icons.security,
                        onChanged: (val) => _updateSetting('privacy', val),
                        isDarkMode: isDarkMode,
                        themeProvider: themeProvider,
                      ),
                      _buildSwitchTile(
                        title: 'Developer Preview',
                        subtitle: 'Enable experimental features for testing',
                        value: developerPreview,
                        icon: Icons.code,
                        onChanged: (val) => _updateSetting('developer', val),
                        isDarkMode: isDarkMode,
                        themeProvider: themeProvider,
                      ),
                    ],
                  ),
                ),
                _buildBottomBar(isDarkMode, themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomBar(bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
              ? [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ]
              : [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.2),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedCrossFade(
            firstChild: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI preferences saved successfully!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(height: 36),
            crossFadeState: _showConfirmation 
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoverStates['save_button'] = true),
                  onExit: (_) => setState(() => _hoverStates['save_button'] = false),
                  child: AnimatedContainer(
                    duration: themeProvider.animationDurationShort,
                    transform: _hoverStates['save_button'] == true && _haveUnsavedChanges && !_isProcessing
                        ? (Matrix4.identity()..scale(1.02))
                        : Matrix4.identity(),
                    child: ElevatedButton(
                      onPressed: _haveUnsavedChanges && !_isProcessing 
                          ? _savePreferences 
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blueAccent,
                        disabledBackgroundColor: Colors.blueAccent.withOpacity(0.5),
                        elevation: _hoverStates['save_button'] == true && _haveUnsavedChanges && !_isProcessing ? 8 : 4,
                        shadowColor: Colors.blueAccent.withOpacity(
                          _hoverStates['save_button'] == true && _haveUnsavedChanges && !_isProcessing ? 0.4 : 0.2
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Preferences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(
                                  _haveUnsavedChanges ? 1.0 : 0.7,
                                ),
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeProvider themeProvider) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 16.0, 0, 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueAccent.withOpacity(0.2),
                Colors.blueAccent.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: themeProvider.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
  }) {
    final String tileKey = 'switch_${title.toLowerCase().replaceAll(' ', '_')}';
    final bool isHovered = _hoverStates[tileKey] ?? false;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[tileKey] = true),
      onExit: (_) => setState(() => _hoverStates[tileKey] = false),
      child: AnimatedContainer(
        duration: themeProvider.animationDurationShort,
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isHovered ? [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Card(
          elevation: isHovered ? 4 : (isDarkMode ? 0 : 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDarkMode 
              ? (isHovered ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.3))
              : (isHovered ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.2)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ListTile(
              leading: AnimatedContainer(
                duration: themeProvider.animationDurationShort,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: value 
                      ? (isHovered ? Colors.blueAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.1))
                      : (isHovered ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isHovered && value ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ] : [],
                ),
                child: Icon(
                  icon,
                  color: value ? Colors.blueAccent : Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                title,
                style: themeProvider.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: themeProvider.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(isHovered ? 0.8 : 0.7),
                ),
              ),
              trailing: Transform.scale(
                scale: isHovered ? 1.1 : 1.0,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.blueAccent,
                  activeTrackColor: Colors.blueAccent.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProcessingSpeedCard(bool isDarkMode, ThemeProvider themeProvider) {
    final String cardKey = 'processing_speed_card';
    final bool isHovered = _hoverStates[cardKey] ?? false;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverStates[cardKey] = true),
          onExit: (_) => setState(() => _hoverStates[cardKey] = false),
          child: AnimatedContainer(
            duration: themeProvider.animationDurationShort,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isHovered ? [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: Card(
              elevation: isHovered ? 4 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: isDarkMode 
                  ? (isHovered ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.3))
                  : (isHovered ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.2)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: themeProvider.animationDurationShort,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isHovered 
                                ? Colors.blueAccent.withOpacity(0.2)
                                : Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isHovered ? [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ] : [],
                          ),
                          child: const Icon(
                            Icons.speed,
                            color: Colors.blueAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Processing Speed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Adjust how quickly the AI processes and responds',
                                style: themeProvider.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(isHovered ? 0.8 : 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: Colors.blueAccent,
                        inactiveTrackColor: Colors.blueAccent.withOpacity(0.2),
                        thumbColor: Colors.white,
                        overlayColor: Colors.blueAccent.withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: responseSpeed,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: "${(responseSpeed * 100).toInt()}%",
                        onChanged: (value) => _updateSetting('speed', value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.date_range, 
                                size: 14, 
                                color: isHovered ? Colors.white.withOpacity(0.9) : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Thorough',
                                style: themeProvider.bodyMedium.copyWith(
                                  color: isHovered ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.bolt, 
                                size: 14, 
                                color: isHovered ? Colors.white.withOpacity(0.9) : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Speedy',
                                style: themeProvider.bodyMedium.copyWith(
                                  color: isHovered ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildVoiceSettingsCard(bool isDarkMode, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode 
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice type selector
            const Text(
              'Voice Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedVoice,
                  isExpanded: true,
                  dropdownColor: isDarkMode 
                      ? Colors.grey.shade900 
                      : Colors.grey.shade800,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _updateSetting('voiceType', newValue);
                    }
                  },
                  items: _voices.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Voice volume slider
            Row(
              children: [
                const Icon(
                  Icons.volume_down,
                  color: Colors.white70,
                  size: 20,
                ),
                Expanded(
                  child: Slider(
                    value: voiceVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) => _updateSetting('volume', value),
                    activeColor: Colors.blueAccent,
                  ),
                ),
                const Icon(
                  Icons.volume_up,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
            
            // Test voice button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice playback test will be available soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Test Voice'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageSelector(bool isDarkMode, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode 
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Primary Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  isExpanded: true,
                  dropdownColor: isDarkMode 
                      ? Colors.grey.shade900 
                      : Colors.grey.shade800,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _updateSetting('language', newValue);
                    }
                  },
                  items: _languages.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDialectSelector(bool isDarkMode, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode 
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.public,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'English Dialect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Choose your preferred English dialect',
                        style: themeProvider.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: useDialect,
                  onChanged: (val) => _updateSetting('dialect', val),
                  activeColor: Colors.blueAccent,
                  activeTrackColor: Colors.blueAccent.withOpacity(0.3),
                ),
              ],
            ),
            if (useDialect) ...[
              const SizedBox(height: 16),
              _buildDialectOptions(isDarkMode, themeProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDialectOptions(bool isDarkMode, ThemeProvider themeProvider) {
    return AnimatedOpacity(
      opacity: useDialect ? 1.0 : 0.7,
      duration: themeProvider.animationDurationShort,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Dialect',
            style: themeProvider.bodyMedium.copyWith(
              color: themeProvider.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _englishDialects.map((dialect) {
              final isSelected = selectedDialect == dialect;
              final hoverKey = 'dialect_$dialect';
              final isHovering = _hoverStates[hoverKey] ?? false;
              
              return MouseRegion(
                onEnter: (_) => setState(() => _hoverStates[hoverKey] = true),
                onExit: (_) => setState(() => _hoverStates[hoverKey] = false),
                child: GestureDetector(
                  onTap: () => _updateSetting('dialectType', dialect),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: isHovering ? 1.05 : 1.0,
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
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? themeProvider.accentColor.withOpacity(isHovering ? 0.3 : 0.2)
                                : isHovering
                                    ? themeProvider.secondaryTextColor.withOpacity(0.15)
                                    : themeProvider.secondaryTextColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                            border: Border.all(
                              color: isSelected
                                  ? themeProvider.accentColor
                                  : isHovering
                                      ? themeProvider.accentColor.withOpacity(0.3)
                                      : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isHovering || isSelected ? [
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
                              AnimatedContainer(
                                duration: themeProvider.animationDurationShort,
                                padding: EdgeInsets.all(isSelected || isHovering ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? themeProvider.accentColor.withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.language,
                                  size: 16,
                                  color: isSelected
                                      ? themeProvider.accentColor
                                      : themeProvider.secondaryIconColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dialect,
                                style: themeProvider.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? themeProvider.accentColor
                                      : themeProvider.primaryTextColor,
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
    );
  }

  Widget _buildAIModelSelector(bool isDarkMode, ThemeProvider themeProvider) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDarkMode 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.memory,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Model',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Choose which AI model to use',
                            style: themeProvider.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _aiModels.map((model) {
                    final isSelected = model == selectedAIModel;
                    final modelKey = 'model_${model.toLowerCase()}';
                    final isHovered = _hoverStates[modelKey] ?? false;
                    
                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoverStates[modelKey] = true),
                      onExit: (_) => setState(() => _hoverStates[modelKey] = false),
                      child: GestureDetector(
                        onTap: () => _updateSetting('aiModel', model),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 1.0,
                            end: isHovered ? 1.05 : 1.0,
                          ),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration: themeProvider.animationDurationShort,
                                width: 95,
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blueAccent.withOpacity(isHovered ? 0.3 : 0.2)
                                      : Colors.white.withOpacity(isHovered ? 0.1 : 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blueAccent
                                        : isHovered 
                                            ? Colors.blueAccent.withOpacity(0.3)
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isHovered ? [
                                    BoxShadow(
                                      color: isSelected 
                                          ? Colors.blueAccent.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : [],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      model == 'Standard'
                                          ? Icons.check_circle_outline
                                          : model == 'Advanced'
                                              ? Icons.auto_awesome
                                              : Icons.science,
                                      color: isSelected ? Colors.blueAccent : Colors.white70,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      model,
                                      textAlign: TextAlign.center,
                                      style: themeProvider.bodyMedium.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.blueAccent : Colors.white70,
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
                const SizedBox(height: 12),
                if (selectedAIModel != 'Standard') ...[
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: selectedAIModel == 'Experimental'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selectedAIModel == 'Experimental'
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: selectedAIModel == 'Experimental'
                              ? Colors.orange
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedAIModel == 'Experimental'
                                ? 'Experimental model may have unexpected behavior'
                                : 'Advanced model uses more resources but gives better results',
                            style: themeProvider.bodyMedium.copyWith(
                              color: selectedAIModel == 'Experimental'
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showHelpDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About AI Preferences',
          style: themeProvider.headlineMedium,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'Adaptive Responses',
                'When enabled, the AI will learn from your interactions and adjust its responses to better match your communication style.',
                Icons.auto_awesome,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Voice Features',
                'Control text-to-speech functionality and voice characteristics for audio responses.',
                Icons.record_voice_over,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Processing Speed',
                'Adjust the tradeoff between response quality and speed. Slower processing typically yields more thorough responses.',
                Icons.speed,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'AI Models',
                'Select different AI models based on your needs. Advanced models provide better quality at the cost of speed and resources.',
                Icons.memory,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Privacy Mode',
                'Enhanced privacy mode prevents your conversations from being used for AI training and limits data storage.',
                Icons.security,
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
            child: const Text('CLOSE'),
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
            Icon(
              icon,
              size: 20,
              color: themeProvider.accentColor,
            ),
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
}