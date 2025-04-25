import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/base_screen.dart';
import 'dart:async';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  _AdvancedSettingsPageState createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> with TickerProviderStateMixin, ScreenAnimationMixin {
  // Settings values
  final Map<String, Map<String, dynamic>> _settings = {
    'Developer Options': {
      'Enable Developer Mode': {
        'value': false,
        'icon': Icons.developer_mode,
        'description': 'Access debugging tools and experimental features.',
        'details': 'Activates additional menus and options for development purposes. Not recommended for regular users.'
      },
      'Enable Beta Features': {
        'value': false,
        'icon': Icons.new_releases,
        'description': 'Try out upcoming features before they are released.',
        'details': 'Enables access to beta features which may not be fully stable. Requires app restart.',
        'requiresRestart': true
      },
      'Experimental AI Models': {
        'value': false,
        'icon': Icons.psychology,
        'description': 'Use cutting-edge AI models that are still in development.',
        'details': 'Enables access to the latest experimental AI models. May affect performance and accuracy. Requires app restart.',
        'requiresRestart': true
      },
      'API Access': {
        'value': false,
        'icon': Icons.api,
        'description': 'Enable direct API access for custom integrations.',
        'details': 'Provides access to the API configuration and token management for external integrations.'
      },
    },
    'Performance Options': {
      'Background Processing': {
        'value': true,
        'icon': Icons.all_inclusive,
        'description': 'Allow the app to process data in the background.',
        'details': 'Enables the app to continue processing tasks when minimized or when the screen is off. Disabling may save battery.'
      },
      'Enable Caching': {
        'value': true,
        'icon': Icons.cached,
        'description': 'Store temporary data to improve performance.',
        'details': 'Caches data to disk to improve load times and reduce network usage. Disabling will free up storage space but may slow down the app.'
      },
      'High Performance Mode': {
        'value': false,
        'icon': Icons.speed,
        'description': 'Optimize for maximum performance at the expense of battery life.',
        'details': 'Uses more system resources to deliver the best possible performance. May significantly increase battery usage.'
      },
      'Offline Mode': {
        'value': false,
        'icon': Icons.wifi_off,
        'description': 'Work without an internet connection using cached data.',
        'details': 'Disables network requests and operates using only locally cached data. Limited functionality available.'
      },
    },
    'Debugging Options': {
      'Enable Debug Logs': {
        'value': false,
        'icon': Icons.subject,
        'description': 'Log errors and diagnostic information for troubleshooting.',
        'details': 'Records detailed application logs which can help identify and fix issues. May affect performance slightly.'
      },
      'Crash Reporting': {
        'value': true,
        'icon': Icons.report_problem,
        'description': 'Automatically send crash reports to help improve stability.',
        'details': 'Sends anonymous crash reports to our servers to help identify and fix issues. No personal data is included.'
      },
      'Extended Error Details': {
        'value': false,
        'icon': Icons.bug_report,
        'description': 'Show detailed technical error information when problems occur.',
        'details': 'Displays technical error details when crashes or errors occur, instead of user-friendly messages.'
      },
      'Network Debugging': {
        'value': false,
        'icon': Icons.wifi,
        'description': 'Monitor and log network traffic for troubleshooting.',
        'details': 'Logs all network requests and responses for debugging. May slow down network operations.'
      },
    },
    'Advanced Features': {
      'Custom Themes': {
        'value': false,
        'icon': Icons.format_paint,
        'description': 'Create and apply custom themes beyond the built-in options.',
        'details': 'Allows creating and modifying custom themes with advanced color and style options.'
      },
      'Voice Command Mode': {
        'value': false,
        'icon': Icons.record_voice_over,
        'description': 'Control the app using voice commands for hands-free operation.',
        'details': 'Enables navigation and control of the app using voice commands. Requires microphone permission.'
      },
      'Alternative Text Models': {
        'value': false,
        'icon': Icons.text_fields,
        'description': 'Use third-party text processing models instead of default models.',
        'details': 'Allows using alternative text processing models. May require additional downloads.'
      },
      'Keyboard Shortcuts': {
        'value': true,
        'icon': Icons.keyboard,
        'description': 'Enable keyboard shortcuts for faster navigation and actions.',
        'details': 'Enables keyboard shortcuts for common actions on desktop platforms.'
      },
    },
  };
  
  // Selected log level
  String selectedLogLevel = 'Warning';
  final List<String> logLevels = ['Debug', 'Info', 'Warning', 'Error', 'Critical'];
  
  // Debug console
  final List<String> _debugLogs = [];
  final ScrollController _logsScrollController = ScrollController();
  final TextEditingController _logInputController = TextEditingController();
  
  // State variables
  bool haveUnsavedChanges = false;
  bool showRestartDialog = false;
  final String _searchQuery = '';
  String? _selectedCategory;
  bool _showSystemInfo = false;
  final bool _isShowingPerformanceMetrics = false;
  Timer? _metricsRefreshTimer;
  final Map<String, double> _metrics = {
    'Memory Usage': 0,
    'CPU Usage': 0,
    'Network Speed': 0,
    'Battery Drain': 0,
    'Storage': 0,
  };
  
  // Map to track hover states for interactive UI
  final Map<String, bool> _hoverStates = {};
  
  // Animations for staggered entry
  late Animation<double> _headerAnimation;
  late Animation<double> _warningAnimation;
  late Animation<double> _tabsAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _bottomBarAnimation;
  
  // For animations and expanded sections
  late AnimationController _expandAnimationController;
  final Set<String> _expandedCategories = {'Developer Options', 'Performance Options', 'Debugging Options', 'Advanced Features'};
  
  @override
  void initState() {
    super.initState();
    _expandAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Initialize staggered animations using ScreenAnimationMixin
    _headerAnimation = createStaggeredAnimation(
      begin: 0.0,
      end: 1.0,
      startInterval: 0.0,
      endInterval: 0.2,
      curve: Curves.easeOutQuart,
    );
    
    _warningAnimation = createStaggeredAnimation(
      begin: 0.0,
      end: 1.0,
      startInterval: 0.1,
      endInterval: 0.3,
      curve: Curves.easeOutQuart,
    );
    
    _tabsAnimation = createStaggeredAnimation(
      begin: 0.0,
      end: 1.0,
      startInterval: 0.2,
      endInterval: 0.4,
      curve: Curves.easeOutQuart,
    );
    
    _contentAnimation = createStaggeredAnimation(
      begin: 0.0,
      end: 1.0,
      startInterval: 0.3,
      endInterval: 0.5,
      curve: Curves.easeOutQuart,
    );
    
    _bottomBarAnimation = createStaggeredAnimation(
      begin: 0.0,
      end: 1.0,
      startInterval: 0.4,
      endInterval: 0.6,
      curve: Curves.easeOutQuart,
    );
    
    // Set initial selected category
    _selectedCategory = _settings.keys.first;
    
    // Populate some sample debug logs
    _debugLogs.add("[${DateTime.now().toString()}] System initialized");
    _debugLogs.add("[${DateTime.now().toString()}] All components loaded");
    _debugLogs.add("[${DateTime.now().toString()}] Ready");
  }
  
  @override
  void dispose() {
    _expandAnimationController.dispose();
    _logsScrollController.dispose();
    _logInputController.dispose();
    super.dispose();
  }
  
  // Update settings and track changes
  void _updateSetting(String category, String setting, bool value) {
    setState(() {
      if (_settings[category]?[setting] != null) {
        _settings[category]![setting]['value'] = value;
        haveUnsavedChanges = true;
        
        // Check if restart is required
        if (_settings[category]![setting]['requiresRestart'] == true && !showRestartDialog) {
          _showRestartRequiredDialog();
          showRestartDialog = true;
        }
      }
    });
    
    // Add a debug log entry
    if (_settings['Debugging Options']?['Enable Debug Logs']?['value'] == true) {
      _addDebugLog("Setting '$setting' in '$category' changed to '$value'");
    }
  }
  
  void _addDebugLog(String message) {
    setState(() {
      _debugLogs.add("[${DateTime.now().toString()}] $message");
    });
    
    // Scroll to the bottom of the logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logsScrollController.hasClients) {
        _logsScrollController.animateTo(
          _logsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _savePreferences() {
    // Here you would save to shared preferences or a backend
    
    // Add success log
    _addDebugLog("Advanced settings saved successfully");
    
    // Show a snackbar to confirm
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Advanced settings saved'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
    
    setState(() {
      haveUnsavedChanges = false;
    });
  }
  
  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
      _addDebugLog("Logs cleared");
    });
  }
  
  void _showRestartRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restart Required'),
          content: const Text(
            'Some of the changes you made require the app to be restarted to take effect. '
            'These changes will be applied the next time you launch the app.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _resetAllSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Settings'),
          content: const Text(
            'This will reset all advanced settings to their default values. '
            'This action cannot be undone. Are you sure?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  // Reset all settings to their default values
                  _settings['Developer Options']?.forEach((key, value) {
                    value['value'] = false;
                  });
                  
                  _settings['Performance Options']?['Background Processing']?['value'] = true;
                  _settings['Performance Options']?['Enable Caching']?['value'] = true;
                  _settings['Performance Options']?['High Performance Mode']?['value'] = false;
                  _settings['Performance Options']?['Offline Mode']?['value'] = false;
                  
                  _settings['Debugging Options']?['Enable Debug Logs']?['value'] = false;
                  _settings['Debugging Options']?['Crash Reporting']?['value'] = true;
                  _settings['Debugging Options']?['Extended Error Details']?['value'] = false;
                  _settings['Debugging Options']?['Network Debugging']?['value'] = false;
                  
                  _settings['Advanced Features']?['Custom Themes']?['value'] = false;
                  _settings['Advanced Features']?['Voice Command Mode']?['value'] = false;
                  _settings['Advanced Features']?['Alternative Text Models']?['value'] = false;
                  _settings['Advanced Features']?['Keyboard Shortcuts']?['value'] = true;
                  
                  selectedLogLevel = 'Warning';
                  haveUnsavedChanges = true;
                });
                _addDebugLog("All settings reset to defaults");
              },
              child: const Text('RESET'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return WillPopScope(
      onWillPop: () async {
        if (haveUnsavedChanges) {
          _showUnsavedChangesDialog();
          return false;
        }
        return true;
      },
      child: GradientScaffold(
        appBar: AppBar(
          title: FadeTransition(
            opacity: _headerAnimation,
            child: Text(
              'Advanced Settings',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (haveUnsavedChanges) {
                _showUnsavedChangesDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetAllSettings,
              tooltip: 'Reset all settings',
            ),
            // Toggle system info
            IconButton(
              icon: Icon(_showSystemInfo ? Icons.info : Icons.info_outline, color: Colors.white),
              onPressed: _toggleSystemInfo,
              tooltip: 'System Information',
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning
            FadeTransition(
              opacity: _warningAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(_warningAnimation),
                child: _buildWarningHeader(isDarkMode, themeProvider),
              ),
            ),
            
            // Category tabs
            FadeTransition(
              opacity: _tabsAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_tabsAnimation),
                child: _buildCategoryTabs(isDarkMode, themeProvider),
              ),
            ),
            
            // Main content
            Expanded(
              child: FadeTransition(
                opacity: _contentAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_contentAnimation),
                  child: _buildMainContent(isDarkMode, themeProvider),
                ),
              ),
            ),
            
            // Save button at bottom
            FadeTransition(
              opacity: _bottomBarAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_bottomBarAnimation),
                child: _buildBottomActionSection(isDarkMode, themeProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainContent(bool isDarkMode, ThemeProvider themeProvider) {
    // Show system info if enabled
    if (_showSystemInfo) {
      return _buildSystemInfoSection(isDarkMode, themeProvider);
    }
    
    // Show all settings
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // If a category is selected, show only its settings
        if (_selectedCategory != null && _settings.containsKey(_selectedCategory)) ...[
          ...buildSettingsForCategory(_selectedCategory!, isDarkMode, themeProvider),
        ],
        
        // If Developer Mode is enabled, show additional debug options
        if (_selectedCategory == 'Debugging Options' && 
            _settings['Developer Options']?['Enable Developer Mode']?['value'] == true) ...[
          _buildDebugConsole(isDarkMode, themeProvider),
        ],
        
        // If Performance Metrics is enabled, show metrics panel
        if (_selectedCategory == 'Performance Options' && 
            _settings['Developer Options']?['Enable Developer Mode']?['value'] == true) ...[
          const SizedBox(height: 16),
          _buildPerformanceMetricsPanel(isDarkMode, themeProvider),
        ],
      ],
    );
  }

  List<Widget> buildSettingsForCategory(String category, bool isDarkMode, ThemeProvider themeProvider) {
    final settingsForCategory = _settings[category];
    if (settingsForCategory == null) return [];
    
    return [
      _buildCategoryHeader(category, isDarkMode, themeProvider),
      
      // If this is the Debugging category and debug logs are enabled, show log level selector
      if (category == 'Debugging Options' && 
          settingsForCategory['Enable Debug Logs']?['value'] == true) ...[
        _buildLogLevelSelector(isDarkMode, themeProvider),
      ],
      
      // Display all settings for this category
      ...settingsForCategory.entries.map((entry) {
        final settingName = entry.key;
        final settingData = entry.value;
        
        return _buildAnimatedSwitchTile(
          title: settingName,
          description: settingData['description'] as String,
          details: settingData['details'] as String,
          icon: settingData['icon'] as IconData,
          value: settingData['value'] as bool,
          isDarkMode: isDarkMode,
          themeProvider: themeProvider,
          requiresRestart: settingData['requiresRestart'] as bool? ?? false,
          onChanged: (val) => _updateSetting(category, settingName, val),
        );
      }),
    ];
  }

  Widget _buildWarningHeader(bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Settings',
                  style: themeProvider.titleMedium.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These settings are intended for advanced users. Changes may affect app stability.',
                  style: themeProvider.bodyMedium.copyWith(
                    color: Colors.orange.shade800,
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
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _settings.keys.map((category) {
          final isSelected = _selectedCategory == category;
          final hoverKey = 'tab_$category';
          final isHovering = _hoverStates[hoverKey] ?? false;
          
          return MouseRegion(
            onEnter: (_) => setState(() => _hoverStates[hoverKey] = true),
            onExit: (_) => setState(() => _hoverStates[hoverKey] = false),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected 
                        ? [
                            themeProvider.accentColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                            themeProvider.accentColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                          ]
                        : isHovering
                            ? [
                                Colors.grey.withOpacity(isDarkMode ? 0.2 : 0.1),
                                Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.05),
                              ]
                            : [
                                Colors.transparent,
                                Colors.transparent,
                              ],
                  ),
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  border: Border.all(
                    color: isSelected 
                        ? themeProvider.accentColor 
                        : isHovering
                            ? themeProvider.accentColor.withOpacity(0.3)
                            : themeProvider.settingsCardBorderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected || isHovering
                      ? [
                          BoxShadow(
                            color: isSelected
                                ? themeProvider.accentColor.withOpacity(0.1)
                                : Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 18,
                      color: isSelected 
                          ? themeProvider.accentColor
                          : isHovering
                              ? themeProvider.accentColor.withOpacity(0.7)
                              : themeProvider.secondaryIconColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.replaceAll(' Options', ''),
                      style: themeProvider.bodyMedium.copyWith(
                        color: isSelected 
                            ? themeProvider.accentColor
                            : isHovering
                                ? themeProvider.accentColor.withOpacity(0.7)
                                : themeProvider.secondaryTextColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemInfoSection(bool isDarkMode, ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.4),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade800.withOpacity(0.5)
                      : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSystemInfo = !_showSystemInfo;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeProvider.accentColor.withOpacity(0.2),
                            themeProvider.accentColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(themeProvider.borderRadius),
                          topRight: Radius.circular(themeProvider.borderRadius),
                          bottomLeft: _showSystemInfo ? Radius.zero : Radius.circular(themeProvider.borderRadius),
                          bottomRight: _showSystemInfo ? Radius.zero : Radius.circular(themeProvider.borderRadius),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  themeProvider.accentColor.withOpacity(0.3),
                                  themeProvider.accentColor.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: themeProvider.accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'System Information',
                            style: themeProvider.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.primaryTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _showSystemInfo ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: themeProvider.primaryIconColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showSystemInfo ? null : 0,
                    child: _showSystemInfo
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSystemInfoItem(
                                  icon: Icons.phone_android,
                                  title: 'Device',
                                  value: 'iPhone 13 Pro',
                                  isDarkMode: isDarkMode,
                                  themeProvider: themeProvider,
                                ),
                                _buildSystemInfoItem(
                                  icon: Icons.memory,
                                  title: 'OS Version',
                                  value: 'iOS 16.2',
                                  isDarkMode: isDarkMode,
                                  themeProvider: themeProvider,
                                ),
                                _buildSystemInfoItem(
                                  icon: Icons.storage,
                                  title: 'Storage',
                                  value: '45.2 GB Free / 128 GB',
                                  isDarkMode: isDarkMode,
                                  themeProvider: themeProvider,
                                ),
                                _buildSystemInfoItem(
                                  icon: Icons.memory_outlined,
                                  title: 'RAM',
                                  value: '2.1 GB Free / 6 GB',
                                  isDarkMode: isDarkMode,
                                  themeProvider: themeProvider,
                                ),
                                _buildSystemInfoItem(
                                  icon: Icons.app_settings_alt,
                                  title: 'App Version',
                                  value: '1.2.3 (Build 45)',
                                  isDarkMode: isDarkMode,
                                  themeProvider: themeProvider,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'This information may be useful for troubleshooting and support.',
                                          style: themeProvider.bodySmall.copyWith(
                                            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.2),
                ]
              : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
        border: Border.all(
          color: isDarkMode
              ? Colors.grey.shade800.withOpacity(0.3)
              : Colors.grey.shade300.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeProvider.accentColor.withOpacity(0.2),
                  themeProvider.accentColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
            ),
            child: Icon(
              icon,
              color: themeProvider.accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: themeProvider.bodyMedium.copyWith(
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: themeProvider.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsPanel(bool isDarkMode, ThemeProvider themeProvider) {
    // Implementation of _buildPerformanceMetricsPanel method
    // This method should return a widget representing the performance metrics panel
    return Container(); // Placeholder return, actual implementation needed
  }

  Widget _buildDebugConsole(bool isDarkMode, ThemeProvider themeProvider) {
    // Implementation of _buildDebugConsole method
    // This method should return a widget representing the debug console
    return Container(); // Placeholder return, actual implementation needed
  }

  Widget _buildBottomActionSection(bool isDarkMode, ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.4),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade800.withOpacity(0.5)
                      : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (haveUnsavedChanges)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    themeProvider.accentColor.withOpacity(0.1),
                                    themeProvider.accentColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                                border: Border.all(
                                  color: themeProvider.accentColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: themeProvider.accentColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You have unsaved changes. Save or reset to apply changes.',
                                      style: themeProvider.bodySmall.copyWith(
                                        color: themeProvider.accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: haveUnsavedChanges ? _resetAllSettings : null,
                        icon: Icon(
                          Icons.refresh,
                          color: haveUnsavedChanges
                              ? Colors.red.shade300
                              : Colors.grey.withOpacity(0.5),
                          size: 18,
                        ),
                        label: Text(
                          'Reset',
                          style: themeProvider.bodyMedium.copyWith(
                            color: haveUnsavedChanges
                                ? Colors.red.shade300
                                : Colors.grey.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                            side: BorderSide(
                              color: haveUnsavedChanges
                                  ? Colors.red.shade300.withOpacity(0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: haveUnsavedChanges ? _saveSettings : null,
                        icon: Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'Save Changes',
                          style: themeProvider.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: haveUnsavedChanges ? 4 : 0,
                          shadowColor: themeProvider.accentColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                          ),
                          visualDensity: VisualDensity.comfortable,
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.grey.withOpacity(0.2);
                              }
                              return themeProvider.accentColor;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleSystemInfo() {
    setState(() {
      _showSystemInfo = !_showSystemInfo;
      _selectedCategory = null;
    });
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Would you like to save them before leaving?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('DISCARD'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _savePreferences();
                Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(String category, bool isDarkMode, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    themeProvider.accentColor.withOpacity(0.1),
                    themeProvider.accentColor.withOpacity(0.05),
                  ]
                : [
                    themeProvider.accentColor.withOpacity(0.1),
                    themeProvider.accentColor.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
          boxShadow: [
            BoxShadow(
              color: themeProvider.accentColor.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeProvider.accentColor.withOpacity(0.2),
                    themeProvider.accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: themeProvider.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              category,
              style: themeProvider.settingsHeaderStyle.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogLevelSelector(bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        border: Border.all(
          color: isDarkMode
              ? Colors.grey.shade800.withOpacity(0.5)
              : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.accentColor.withOpacity(0.2),
                      themeProvider.accentColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                ),
                child: Icon(
                  Icons.tune,
                  color: themeProvider.accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Logging Level',
                style: themeProvider.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                      ]
                    : [
                        Colors.grey.shade200.withOpacity(0.6),
                        Colors.grey.shade100.withOpacity(0.4),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: logLevels.length,
              itemBuilder: (context, index) {
                final level = logLevels[index];
                final isSelected = selectedLogLevel == level;
                final hoverKey = 'log_level_$level';
                final isHovering = _hoverStates[hoverKey] ?? false;
                
                // Choose appropriate color based on log level
                Color levelColor;
                switch (level) {
                  case 'Debug':
                    levelColor = Colors.grey;
                    break;
                  case 'Info':
                    levelColor = Colors.blue;
                    break;
                  case 'Warning':
                    levelColor = Colors.orange;
                    break;
                  case 'Error':
                    levelColor = Colors.red;
                    break;
                  case 'Critical':
                    levelColor = Colors.purple;
                    break;
                  default:
                    levelColor = Colors.grey;
                }
                
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoverStates[hoverKey] = true),
                  onExit: (_) => setState(() => _hoverStates[hoverKey] = false),
                  child: GestureDetector(
                    onTap: () => _updateLogLevel(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  levelColor,
                                  levelColor.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: isHovering && !isSelected
                            ? levelColor.withOpacity(0.1)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: levelColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          level,
                          style: themeProvider.bodyMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : isHovering
                                    ? levelColor
                                    : levelColor.withOpacity(0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.shade100.withOpacity(0.5),
              borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
              border: Border.all(
                color: isDarkMode
                    ? Colors.grey.shade800.withOpacity(0.3)
                    : Colors.grey.shade300.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: themeProvider.secondaryIconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Controls the verbosity of logs. Higher levels include all lower levels.',
                    style: themeProvider.bodySmall.copyWith(
                      color: themeProvider.secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  Widget _buildAnimatedSwitchTile({
    required String title,
    required String description,
    required String details,
    required IconData icon,
    required bool value,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
    required bool requiresRestart,
    required ValueChanged<bool> onChanged,
  }) {
    final hoverKey = 'setting_$title';
    final isHovering = _hoverStates[hoverKey] ?? false;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[hoverKey] = true),
      onExit: (_) => setState(() => _hoverStates[hoverKey] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Colors.black.withOpacity(isHovering ? 0.7 : 0.5),
                    Colors.black.withOpacity(isHovering ? 0.6 : 0.4),
                  ]
                : [
                    Colors.white.withOpacity(isHovering ? 0.95 : 0.9),
                    Colors.white.withOpacity(isHovering ? 0.9 : 0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovering ? 0.1 : 0.05),
              blurRadius: isHovering ? 8 : 5,
              spreadRadius: isHovering ? 1 : 0,
              offset: isHovering ? const Offset(0, 2) : const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: isHovering
                ? themeProvider.accentColor.withOpacity(0.3)
                : isDarkMode
                    ? Colors.grey.shade800.withOpacity(0.3)
                    : Colors.grey.shade300.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: value
                        ? [
                            themeProvider.accentColor.withOpacity(0.3),
                            themeProvider.accentColor.withOpacity(0.2),
                          ]
                        : [
                            Colors.grey.withOpacity(0.2),
                            Colors.grey.withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: themeProvider.accentColor.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: value
                      ? themeProvider.accentColor
                      : themeProvider.secondaryIconColor,
                  size: 20,
                ),
              ),
              title: Text(
                title,
                style: themeProvider.settingsTitleStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: themeProvider.settingsDescriptionStyle.copyWith(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),
                  if (requiresRestart) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Requires restart',
                          style: themeProvider.bodySmall.copyWith(
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: themeProvider.accentColor,
                activeTrackColor: themeProvider.accentColor.withOpacity(0.4),
                inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade50,
                inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            if (details.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.shade100.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade800.withOpacity(0.3)
                          : Colors.grey.shade300.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    details,
                    style: themeProvider.bodySmall.copyWith(
                      color: themeProvider.secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateLogLevel(String level) {
    setState(() {
      selectedLogLevel = level;
    });
    
    // Add a debug log entry
    if (_settings['Debugging Options']?['Enable Debug Logs']?['value'] == true) {
      _addDebugLog("Logging level changed to '$level'");
    }
  }

  // Save settings
  void _saveSettings() {
    // Here you would typically save to SharedPreferences or backend
    setState(() {
      haveUnsavedChanges = false;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Developer Options':
        return Icons.code;
      case 'Performance Options':
        return Icons.speed;
      case 'Debugging Options':
        return Icons.bug_report;
      case 'Advanced Features':
        return Icons.extension;
      default:
        return Icons.settings;
    }
  }
}
