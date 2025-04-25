import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/base_screen.dart';
import 'dart:async';

class PrivacyDataPage extends StatefulWidget {
  const PrivacyDataPage({super.key});

  @override
  _PrivacyDataPageState createState() => _PrivacyDataPageState();
}

class _PrivacyDataPageState extends State<PrivacyDataPage> with TickerProviderStateMixin, ScreenAnimationMixin {
  // Privacy settings
  final Map<String, Map<String, dynamic>> _privacySettings = {
    'Data Sharing': {
      'Allow Data Sharing': {
        'value': false,
        'icon': Icons.share,
        'description': 'Share anonymous data to improve services.',
        'details': 'This helps us understand how the app is used to make improvements.'
      },
      'Usage Analytics': {
        'value': true,
        'icon': Icons.analytics,
        'description': 'Collect data on how you use the app to improve features.',
        'details': 'We collect anonymous usage statistics to improve app performance and user experience.'
      },
    },
    'Permissions': {
      'Location Access': {
        'value': false,
        'icon': Icons.location_on,
        'description': 'Allow access to your location for better recommendations.',
        'details': 'Helps provide location-based features and relevant content.'
      },
      'Biometric Data': {
        'value': false,
        'icon': Icons.fingerprint,
        'description': 'Allow access to biometric data for authentication.',
        'details': 'Your biometric data never leaves your device and is used only for secure authentication.'
      },
      'Camera Access': {
        'value': true,
        'icon': Icons.camera_alt,
        'description': 'Allow access to your camera for features like image analysis.',
        'details': 'Required for taking photos and videos within the app.'
      },
      'Microphone Access': {
        'value': true,
        'icon': Icons.mic,
        'description': 'Allow access to your microphone for voice recording and transcription.',
        'details': 'Required for audio recording and voice input features.'
      },
    },
    'Advertising': {
      'Personalized Ads': {
        'value': true,
        'icon': Icons.ads_click,
        'description': 'Receive ads based on your preferences and usage patterns.',
        'details': 'Helps us show you more relevant ads. Disabling this will show you generic ads instead.'
      },
      'Ad Tracking': {
        'value': false,
        'icon': Icons.track_changes,
        'description': 'Allow ads to track your activity across apps and websites.',
        'details': 'When enabled, advertisers can use data from other apps and websites to target ads in this app.'
      },
    }
  };
  
  // Data management options
  final List<Map<String, dynamic>> _dataManagementOptions = [
    {
      'title': 'Export Your Data',
      'icon': Icons.download,
      'description': 'Download a copy of your personal data',
      'action': 'export'
    },
    {
      'title': 'Delete Account Data',
      'icon': Icons.delete_forever,
      'description': 'Permanently delete all your account data',
      'action': 'delete',
      'isDangerous': true
    },
    {
      'title': 'Clear Local Storage',
      'icon': Icons.cleaning_services,
      'description': 'Clear cached data from this device',
      'action': 'clear'
    },
    {
      'title': 'Privacy Policy',
      'icon': Icons.policy,
      'description': 'View our complete privacy policy',
      'action': 'policy'
    },
  ];
  
  // UI state
  bool haveUnsavedChanges = false;
  bool showConfirmation = false;
  bool _isExportingData = false;
  double _exportProgress = 0.0;
  String? _selectedCategory;
  final Set<String> _expandedCategories = {'Data Sharing', 'Permissions', 'Advertising'};
  
  // For animations
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _categoryTabsAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _exportTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Create staggered animations for different UI elements
    _headerFadeAnimation = createStaggeredAnimation(
      begin: 0.0, 
      end: 1.0, 
      startInterval: 0.0, 
      endInterval: 0.5,
      curve: Curves.easeOut,
    );
    
    _categoryTabsAnimation = createStaggeredAnimation(
      begin: 0.0, 
      end: 1.0, 
      startInterval: 0.2, 
      endInterval: 0.7,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: screenAnimationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));
    
    // Set initial selected category
    _selectedCategory = _privacySettings.keys.first;
  }
  
  @override
  void dispose() {
    screenAnimationController.dispose();
    _exportTimer?.cancel();
    super.dispose();
  }
  
  // Track changes and update save button state
  void _updateSetting(String setting, bool value) {
    setState(() {
      switch (setting) {
        case 'dataSharing':
          _privacySettings['Data Sharing']?['Allow Data Sharing']?['value'] = value;
          break;
        case 'personalizedAds':
          _privacySettings['Advertising']?['Personalized Ads']?['value'] = value;
          break;
        case 'locationAccess':
          _privacySettings['Permissions']?['Location Access']?['value'] = value;
          break;
        case 'biometricData':
          _privacySettings['Permissions']?['Biometric Data']?['value'] = value;
          break;
        case 'usageAnalytics':
          _privacySettings['Data Sharing']?['Usage Analytics']?['value'] = value;
          break;
      }
      haveUnsavedChanges = true;
    });
  }
  
  // Handle save preferences
  void _savePreferences() {
    // Here you would typically save to SharedPreferences or backend
    setState(() {
      haveUnsavedChanges = false;
      showConfirmation = true;
    });
    
    // Hide confirmation after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showConfirmation = false;
        });
      }
    });
  }
  
  // Prompt user before leaving if there are unsaved changes
  Future<bool> _onWillPop() async {
    if (!haveUnsavedChanges) {
      return true;
    }
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved privacy changes. Do you want to discard these changes?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GradientScaffold(
        appBar: AppBar(
          title: Text(
            'Privacy & Data',
            style: themeProvider.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
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
            splashRadius: 24,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              tooltip: 'Privacy Information',
              onPressed: () => _showPrivacyHelp(themeProvider),
              splashRadius: 24,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Reset to Defaults',
              onPressed: _resetToDefaults,
              splashRadius: 24,
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: screenAnimationController,
          builder: (context, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: screenAnimationController,
                        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
                      )),
                      child: _buildHeaderSection(isDarkMode, themeProvider),
                    ),
                  ),
                  
                  // Category tabs
                  FadeTransition(
                    opacity: _categoryTabsAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: screenAnimationController,
                        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
                      )),
                      child: _buildCategoryTabs(isDarkMode, themeProvider),
                    ),
                  ),
                  
                  // Main content area
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SizedBox(
                        height: size.height * 0.6,
                        child: _selectedCategory == 'Data Management'
                            ? _buildDataManagementView(isDarkMode, themeProvider)
                            : _buildPrivacySettingsView(isDarkMode, themeProvider),
                      ),
                    ),
                  ),
                  
                  // Bottom section with save button
                  FadeTransition(
                    opacity: createStaggeredAnimation(
                      begin: 0.0,
                      end: 1.0,
                      startInterval: 0.4,
                      endInterval: 0.9,
                      curve: Curves.easeOut,
                    ),
                    child: _buildBottomActionSection(isDarkMode, themeProvider),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeaderSection(bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.15),
            Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade700,
                  Colors.red.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & Security',
                  style: themeProvider.settingsTitleStyle.copyWith(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'These settings control how your personal data is handled and protected.',
                  style: themeProvider.settingsDescriptionStyle.copyWith(
                    color: Colors.red.shade700,
                    height: 1.3,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTabs(bool isDarkMode, ThemeProvider themeProvider) {
    final categories = [..._privacySettings.keys, 'Data Management'];
    
    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? LinearGradient(
                        colors: [
                          themeProvider.accentColor.withOpacity(isDarkMode ? 0.4 : 0.2),
                          themeProvider.accentColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected 
                    ? null
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                border: Border.all(
                  color: isSelected 
                      ? themeProvider.accentColor 
                      : themeProvider.settingsCardBorderColor,
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: themeProvider.accentColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? themeProvider.accentColor.withOpacity(0.2)
                          : themeProvider.isDarkMode 
                              ? Colors.black.withOpacity(0.2) 
                              : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: isSelected 
                          ? themeProvider.accentColor
                          : themeProvider.secondaryIconColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.replaceAll(' Options', ''),
                    style: themeProvider.bodyMedium.copyWith(
                      color: isSelected 
                          ? themeProvider.accentColor
                          : themeProvider.secondaryTextColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Data Sharing':
        return Icons.share;
      case 'Permissions':
        return Icons.security;
      case 'Advertising':
        return Icons.ads_click;
      case 'Data Management':
        return Icons.storage;
      default:
        return Icons.settings;
    }
  }
  
  Widget _buildPrivacySettingsView(bool isDarkMode, ThemeProvider themeProvider) {
    // If no category is selected or invalid category, show a message
    if (_selectedCategory == null || !_privacySettings.containsKey(_selectedCategory)) {
      return Center(
        child: Text(
          'Select a category to view settings',
          style: themeProvider.bodyLarge,
        ),
      );
    }
    
    final categorySettings = _privacySettings[_selectedCategory]!;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      physics: const BouncingScrollPhysics(),
      children: [
        // Show settings for selected category
        _buildCategoryHeader(_selectedCategory!, isDarkMode, themeProvider),
        
        // Animate each setting item with staggered delay
        ...categorySettings.entries.map((entry) {
          final settingName = entry.key;
          final settingData = entry.value;
          final index = categorySettings.entries.toList().indexOf(entry);
          
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            // Stagger the animations
            child: _buildAnimatedSwitchTile(
              title: settingName,
              description: settingData['description'] as String,
              icon: settingData['icon'] as IconData,
              value: settingData['value'] as bool,
              details: settingData['details'] as String,
              isDarkMode: isDarkMode,
              themeProvider: themeProvider,
              onChanged: (val) {
                final settingKey = _getSettingKey(settingName);
                if (settingKey != null) {
                  _updateSetting(settingKey, val);
                }
              },
            ),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
          );
        }),
        
        const SizedBox(height: 20),
        
        // Info card at the bottom
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: isDarkMode
                      ? Colors.blueGrey.withOpacity(0.2)
                      : Colors.blueGrey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: themeProvider.secondaryIconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategory == 'Permissions'
                                ? 'These permission settings control what CAIPO can access on your device. You can change these at any time.'
                                : _selectedCategory == 'Advertising'
                                    ? 'Ad settings control how your data is used for personalized advertising. You have the right to opt out at any time.'
                                    : 'Changes to these settings will be applied when you save your preferences. You can update them anytime.',
                            style: themeProvider.bodySmall.copyWith(
                              color: themeProvider.secondaryTextColor,
                              height: 1.4,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  // Helper method to get the setting key from the display name
  String? _getSettingKey(String displayName) {
    switch (displayName) {
      case 'Allow Data Sharing':
        return 'dataSharing';
      case 'Usage Analytics':
        return 'usageAnalytics';
      case 'Location Access':
        return 'locationAccess';
      case 'Biometric Data':
        return 'biometricData';
      case 'Personalized Ads':
        return 'personalizedAds';
      case 'Ad Tracking':
        return 'adTracking';
      case 'Camera Access':
        return 'cameraAccess';
      case 'Microphone Access':
        return 'microphoneAccess';
      default:
        return null;
    }
  }
  
  Widget _buildCategoryHeader(String title, bool isDarkMode, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeProvider.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getCategoryIcon(title),
              size: 14,
              color: themeProvider.accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
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
    );
  }
  
  Widget _buildDataManagementView(bool isDarkMode, ThemeProvider themeProvider) {
    return _isExportingData
        ? _buildExportProgressView(isDarkMode, themeProvider)
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCategoryHeader('Data Management', isDarkMode, themeProvider),
              
              // Animate each data management option with staggered delay
              ..._dataManagementOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                
                // Calculate opacity based on animation progress and index
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    // Create staggered effect by delaying based on index
                    final staggeredValue = (value - (index * 0.1)).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: staggeredValue,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - staggeredValue)),
                        child: _buildDataManagementTile(
                          option: option,
                          isDarkMode: isDarkMode,
                          themeProvider: themeProvider,
                        ),
                      ),
                    );
                  },
                );
              }),
              
              const SizedBox(height: 20),
              
              // Data insights card with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  // Delay the animation by calculating a modified value
                  final delayedValue = (value - 0.3).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: delayedValue,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - delayedValue)),
                      child: _buildDataInsightsCard(isDarkMode, themeProvider),
                    ),
                  );
                },
              ),
            ],
          );
  }
  
  Widget _buildExportProgressView(bool isDarkMode, ThemeProvider themeProvider) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Card(
              margin: const EdgeInsets.all(24),
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
              ),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.accentColor.withOpacity(0.8),
                            themeProvider.accentColor.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.accentColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.downloading,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Exporting Your Data',
                      style: themeProvider.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we prepare your data export',
                      style: themeProvider.bodyMedium.copyWith(
                        color: themeProvider.secondaryTextColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.accentColor.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _exportProgress,
                          backgroundColor: themeProvider.accentColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(themeProvider.accentColor),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(_exportProgress * 100).toInt()}%',
                      style: themeProvider.titleMedium.copyWith(
                        color: themeProvider.accentColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'This may take a few moments. Your data will be securely packaged into a downloadable file.',
                      style: themeProvider.bodySmall.copyWith(
                        color: themeProvider.secondaryTextColor,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDataInsightsCard(bool isDarkMode, ThemeProvider themeProvider) {
    return Card(
      color: isDarkMode
          ? Colors.black.withOpacity(0.3)
          : Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: themeProvider.accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Data Insights',
                  style: themeProvider.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Data storage info
            _buildDataStatRow(
              icon: Icons.storage,
              label: 'Storage Used',
              value: '245 MB',
              isDarkMode: isDarkMode,
              themeProvider: themeProvider,
            ),
            _buildDataStatRow(
              icon: Icons.mic,
              label: 'Voice Recordings',
              value: '32 files',
              isDarkMode: isDarkMode,
              themeProvider: themeProvider,
            ),
            _buildDataStatRow(
              icon: Icons.text_snippet,
              label: 'Transcriptions',
              value: '18 files',
              isDarkMode: isDarkMode,
              themeProvider: themeProvider,
            ),
            _buildDataStatRow(
              icon: Icons.calendar_today,
              label: 'Account Age',
              value: '63 days',
              isDarkMode: isDarkMode,
              themeProvider: themeProvider,
            ),
            
            const SizedBox(height: 16),
            Divider(color: themeProvider.secondaryTextColor.withOpacity(0.2)),
            const SizedBox(height: 8),
            
            Text(
              'This data summary shows what\'s stored in your account. You can export or delete this data at any time.',
              style: themeProvider.bodySmall.copyWith(
                color: themeProvider.secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataStatRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: themeProvider.accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: themeProvider.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: themeProvider.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: themeProvider.accentColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataManagementTile({
    required Map<String, dynamic> option,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
  }) {
    final bool isDangerous = option['isDangerous'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: themeProvider.settingsCardDecoration.copyWith(
        color: isDangerous
            ? Colors.red.withOpacity(isDarkMode ? 0.1 : 0.05)
            : themeProvider.settingsCardDecoration.color,
        border: isDangerous
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : themeProvider.settingsCardDecoration.border,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: isDangerous
              ? BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                )
              : themeProvider.getSettingsIconDecoration(isActive: true),
          child: Icon(
            option['icon'] as IconData,
            color: isDangerous ? Colors.red : themeProvider.accentColor,
            size: 20,
          ),
        ),
        title: Text(
          option['title'] as String,
          style: themeProvider.settingsTitleStyle.copyWith(
            color: isDangerous ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          option['description'] as String,
          style: themeProvider.settingsDescriptionStyle,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDangerous
              ? Colors.red.withOpacity(0.8)
              : themeProvider.secondaryIconColor,
        ),
        onTap: () => _handleDataAction(option['action'] as String),
      ),
    );
  }
  
  Widget _buildBottomActionSection(bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: themeProvider.settingsBottomBarDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confirmation message
          if (showConfirmation)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.15),
                            Colors.green.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Privacy settings saved successfully!',
                            style: themeProvider.bodyMedium.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Save button row
          if (_selectedCategory != 'Data Management')
            Row(
              children: [
                TextButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                      gradient: haveUnsavedChanges 
                          ? LinearGradient(
                              colors: [
                                themeProvider.accentColor,
                                themeProvider.accentColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: haveUnsavedChanges 
                          ? null 
                          : themeProvider.accentColor.withOpacity(0.5),
                      boxShadow: haveUnsavedChanges 
                          ? [
                              BoxShadow(
                                color: themeProvider.accentColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ] 
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: haveUnsavedChanges ? _savePreferences : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.white.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            size: 18,
                            color: Colors.white.withOpacity(haveUnsavedChanges ? 1.0 : 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save Changes',
                            style: themeProvider.titleMedium.copyWith(
                              color: Colors.white.withOpacity(haveUnsavedChanges ? 1.0 : 0.6),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
  
  void _showPrivacyHelp(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.privacy_tip,
              color: themeProvider.accentColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Privacy & Data Help',
                style: themeProvider.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Understanding Your Privacy Settings',
                style: themeProvider.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This page lets you control how your data is used, collected, and shared. Here\'s what each section means:',
                style: themeProvider.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              _buildPrivacyHelpItem(
                'Data Sharing',
                'Controls what anonymous data is shared with our team to improve the app.',
                Icons.share,
                themeProvider,
              ),
              
              _buildPrivacyHelpItem(
                'Permissions',
                'Manages what features of your device CAIPO can access, such as location and camera.',
                Icons.perm_device_information,
                themeProvider,
              ),
              
              _buildPrivacyHelpItem(
                'Advertising',
                'Controls whether ads are personalized based on your data and if tracking is allowed.',
                Icons.ads_click,
                themeProvider,
              ),
              
              _buildPrivacyHelpItem(
                'Data Management',
                'Tools to export, delete, or clear your data stored within CAIPO.',
                Icons.storage,
                themeProvider,
              ),
              
              const SizedBox(height: 16),
              Text(
                'You can change these settings at any time. Your privacy is important to us.',
                style: themeProvider.bodyMedium.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: themeProvider.textButtonStyle,
            child: const Text('Got It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPrivacyPolicy(themeProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Privacy Policy'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
      ),
    );
  }
  
  Widget _buildPrivacyHelpItem(
    String title,
    String description,
    IconData icon,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: themeProvider.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: themeProvider.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: themeProvider.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handle data management actions
  void _handleDataAction(String action) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    switch (action) {
      case 'export':
        _startDataExport();
        break;
      case 'delete':
        _showDeleteAccountDialog(themeProvider);
        break;
      case 'clear':
        _showClearCacheDialog(themeProvider);
        break;
      case 'policy':
        _showPrivacyPolicy(themeProvider);
        break;
    }
  }
  
  // Show privacy policy
  void _showPrivacyPolicy(ThemeProvider themeProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradientScaffold(
          appBar: AppBar(
            title: Text(
              'Privacy Policy',
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
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: themeProvider.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAIPO Privacy Policy',
                        style: themeProvider.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last Updated: March 10, 2025',
                        style: themeProvider.bodySmall.copyWith(
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This privacy policy describes how CAIPO collects, uses, and shares your personal information. This comprehensive policy applies to all services offered by CAIPO.',
                        style: themeProvider.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        'Information We Collect',
                        [
                          'Profile information you provide when creating an account',
                          'Content you create, upload, or receive from others when using our services',
                          'Information about how you use our services',
                          'Voice recordings when you use our transcription services',
                          'Location information when location services are enabled',
                        ],
                        themeProvider,
                      ),
                      _buildPolicySection(
                        'How We Use Information',
                        [
                          'Provide, maintain, and improve our services',
                          'Develop new services and features',
                          'Measure performance and understand how our services are used',
                          'Communicate with you about service updates and promotions',
                          'Protect against abuse and harmful activities',
                        ],
                        themeProvider,
                      ),
                      _buildPolicySection(
                        'Data Sharing',
                        [
                          'We do not sell your personal information',
                          'We may share information with service providers who perform services on our behalf',
                          'We may share information for legal reasons when necessary',
                          'We share anonymized data for research and analytics purposes',
                        ],
                        themeProvider,
                      ),
                      _buildPolicySection(
                        'Your Controls',
                        [
                          'You can access, update, or delete your information through your account settings',
                          'You can choose what information is used to personalize your experience',
                          'You can disable location sharing and other permissions',
                          'You can export your data at any time',
                        ],
                        themeProvider,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'For any questions regarding this policy, please contact our privacy team at privacy@caipo.ai',
                        style: themeProvider.bodyMedium.copyWith(
                          fontStyle: FontStyle.italic,
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
    );
  }
  
  Widget _buildPolicySection(String title, List<String> items, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: themeProvider.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: themeProvider.bodyMedium),
                Expanded(
                  child: Text(item, style: themeProvider.bodyMedium),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  // Data export simulation
  void _startDataExport() {
    setState(() {
      _isExportingData = true;
      _exportProgress = 0.0;
    });
    
    // Simulate export with progress updates
    _exportTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _exportProgress += 0.01;
        
        if (_exportProgress >= 1.0) {
          _isExportingData = false;
          timer.cancel();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Data Export Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Your data has been exported to Downloads folder', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.green.withOpacity(0.8),
            ),
          );
        }
      });
    });
  }
  
  // Delete account confirmation
  void _showDeleteAccountDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account Data',
                style: themeProvider.headlineMedium.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: themeProvider.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Once you delete your account data:',
              style: themeProvider.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...[
              'All your personal information will be permanently deleted',
              'Your saved recordings and transcriptions will be removed',
              'Your profile and settings will be erased',
              'You will be signed out from all devices',
            ].map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: themeProvider.bodyMedium),
                  Expanded(child: Text(text, style: themeProvider.bodyMedium)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Text(
              'Please type "DELETE" to confirm:',
              style: themeProvider.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Type DELETE',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                // In a real app, you would enable the delete button when value == "DELETE"
              },
            ),
          ],
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
              // Show a snackbar for demo purposes
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature is disabled in this demo'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.red.withOpacity(0.3),
              disabledForegroundColor: Colors.white.withOpacity(0.5),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
  
  // Clear cache confirmation
  void _showClearCacheDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Local Storage',
          style: themeProvider.headlineMedium,
        ),
        content: Text(
          'This will clear all cached data from this device, including saved drafts and temporary files. Your account data will not be affected.',
          style: themeProvider.bodyMedium,
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
              // Simulate clearing cache
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Simulate a delay then show success
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pop(context); // Dismiss loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local storage cleared successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // Reset all privacy settings to defaults
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        
        return AlertDialog(
          title: Text(
            'Reset Privacy Settings',
            style: themeProvider.headlineMedium,
          ),
          content: Text(
            'This will reset all privacy settings to their default values. This action cannot be undone.',
            style: themeProvider.bodyMedium,
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
                setState(() {
                  // Reset all values to defaults
                  _privacySettings['Data Sharing']!['Allow Data Sharing']['value'] = false;
                  _privacySettings['Data Sharing']!['Usage Analytics']['value'] = true;
                  _privacySettings['Permissions']!['Location Access']['value'] = false;
                  _privacySettings['Permissions']!['Biometric Data']['value'] = false;
                  _privacySettings['Permissions']!['Camera Access']['value'] = true;
                  _privacySettings['Permissions']!['Microphone Access']['value'] = true;
                  _privacySettings['Advertising']!['Personalized Ads']['value'] = true;
                  _privacySettings['Advertising']!['Ad Tracking']['value'] = false;
                  
                  haveUnsavedChanges = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedSwitchTile({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
    required String details,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: themeProvider.settingsCardDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(!value),
            splashColor: themeProvider.accentColor.withOpacity(0.1),
            highlightColor: themeProvider.accentColor.withOpacity(0.05),
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
                          gradient: LinearGradient(
                            colors: value ? [
                              themeProvider.accentColor.withOpacity(0.8),
                              themeProvider.accentColor.withOpacity(0.6),
                            ] : [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: value 
                                  ? themeProvider.accentColor.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: value ? Colors.white : themeProvider.secondaryIconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: themeProvider.settingsTitleStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: themeProvider.settingsDescriptionStyle.copyWith(
                                height: 1.3,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: value,
                        onChanged: onChanged,
                        activeColor: themeProvider.accentColor,
                        activeTrackColor: themeProvider.accentColor.withOpacity(0.4),
                        inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade50,
                        inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                      ),
                    ],
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.accentColor.withOpacity(0.15),
                            themeProvider.accentColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                        border: Border.all(
                          color: themeProvider.accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: themeProvider.secondaryIconColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              details,
                              style: themeProvider.bodySmall.copyWith(
                                color: themeProvider.secondaryTextColor,
                                height: 1.4,
                                letterSpacing: 0.2,
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
      ),
    );
  }
}