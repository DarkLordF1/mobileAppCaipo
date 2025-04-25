import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/base_screen.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin, ScreenAnimationMixin {
  // Animation variables for staggered animations
  late Animation<double> _headerAnimation;
  late Animation<double> _warningAnimation;
  late Animation<double> _tabsAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _bottomBarAnimation;
  
  // Grouped notification settings
  Map<String, Map<String, bool>> _notificationGroups = {
    'General': {
      'Push Notifications': true,
      'Email Notifications': false,
    },
    'App': {
      'Reminders': true,
      'Weekly Reports': false,
    },
    'Content': {
      'App Updates': true,
      'Transcription Alerts': true,
    }
  };
  
  // Icons for each notification type
  final Map<String, IconData> _notificationIcons = {
    'Push Notifications': Icons.notifications_active,
    'Email Notifications': Icons.email,
    'Reminders': Icons.access_time,
    'Weekly Reports': Icons.summarize,
    'App Updates': Icons.system_update,
    'Transcription Alerts': Icons.record_voice_over,
  };
  
  // Descriptions for each notification type
  final Map<String, String> _notificationDescriptions = {
    'Push Notifications': 'Receive notifications directly to your device.',
    'Email Notifications': 'Receive notifications via email.',
    'Reminders': 'Get reminded about pending tasks and actions.',
    'Weekly Reports': 'Receive a summary of your activity every week.',
    'App Updates': 'Be notified when new features are available.',
    'Transcription Alerts': 'Get notified when your transcriptions are ready.',
  };
  
  // Time preferences
  String selectedTimeRange = "Anytime";
  final List<String> timeRanges = ["Anytime", "8 AM - 8 PM", "9 AM - 5 PM", "Custom"];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  
  // Track if there are unsaved changes
  bool haveUnsavedChanges = false;
  bool showConfirmation = false;
  
  // Animation controllers
  late AnimationController _expandAnimationController;
  
  // Track expanded categories
  final Set<String> _expandedCategories = {'General', 'App', 'Content'};
  
  // Tab controller for notification types
  final int _selectedTab = 0;
  final List<String> _tabs = ['All', 'Messages', 'Transcriptions', 'Updates'];
  
  // For hover effects
  final Map<String, bool> _hoverStates = {};
  
  @override
  void initState() {
    super.initState();
    
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
    
    _warningAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.1, 
      endInterval: 0.7, 
      curve: Curves.easeOutCubic
    );
    
    _tabsAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.2, 
      endInterval: 0.8, 
      curve: Curves.easeOutCubic
    );
    
    _contentAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.3, 
      endInterval: 0.9, 
      curve: Curves.easeOutCubic
    );
    
    _bottomBarAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.4, 
      endInterval: 1.0, 
      curve: Curves.easeOutCubic
    );
    
    _expandAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    screenAnimationController.forward();
    
    // Simulate loading saved preferences
    _loadSavedPreferences();
  }
  
  @override
  void dispose() {
    _expandAnimationController.dispose();
    screenAnimationController.dispose();
    super.dispose();
  }
  
  // Load saved preferences (would connect to SharedPreferences in a real app)
  Future<void> _loadSavedPreferences() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // In a real app, you would load from SharedPreferences or backend
    // For now, we'll just use the default values defined above
  }
  
  // Update a notification setting
  void _updateSetting(String category, String setting, bool value) {
    setState(() {
      _notificationGroups[category]![setting] = value;
      haveUnsavedChanges = true;
    });
  }
  
  // Toggle a category expansion state
  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }
  
  // Save notification preferences
  void _savePreferences() {
    // In a real app, you would save to SharedPreferences or backend
    
    // Show confirmation message
    setState(() {
      showConfirmation = true;
      haveUnsavedChanges = false;
    });
    
    // Hide the confirmation after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showConfirmation = false;
        });
      }
    });
  }
  
  // Select time
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (BuildContext context, Widget? child) {
        // Use theme provider to style the time picker
        final themeProvider = Provider.of<ThemeProvider>(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: themeProvider.accentColor,
              onPrimary: Colors.white,
              surface: themeProvider.modalBackgroundColor,
              onSurface: themeProvider.primaryTextColor,
            ), dialogTheme: DialogTheme(backgroundColor: themeProvider.modalBackgroundColor),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        haveUnsavedChanges = true;
      });
    }
  }
  
  // Check for unsaved changes before navigating back
  Future<bool> _onWillPop() async {
    if (!haveUnsavedChanges) {
      return true;
    }
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        
        return AlertDialog(
          title: Text(
            'Unsaved Changes',
            style: themeProvider.headlineMedium,
          ),
          content: Text(
            'You have unsaved notification settings. Do you want to discard these changes?',
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('DISCARD'),
            ),
          ],
        );
      },
    );
    
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GradientScaffold(
        appBar: AppBar(
          title: AnimatedBuilder(
            animation: screenAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _headerAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _headerAnimation.value)),
                  child: Text(
                    'Notifications & Reminders',
                    style: themeProvider.settingsHeaderStyle,
                  ),
                ),
              );
            }
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: themeProvider.primaryIconColor),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            AnimatedBuilder(
              animation: screenAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _warningAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _warningAnimation.value)),
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
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
                                  Colors.blue.withOpacity(0.2),
                                  Colors.blue.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Customize how and when you receive notifications from CAIPO.',
                              style: themeProvider.bodyMedium.copyWith(
                                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
            
            // Notification settings in a scrollable list
            Expanded(
              child: AnimatedBuilder(
                animation: screenAnimationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _contentAnimation.value)),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: [
                          _buildCategoryHeader('General Notifications', isDarkMode, themeProvider),
                          _buildAnimatedSwitchTile(
                            title: 'Push Notifications',
                            description: 'Receive notifications directly to your device.',
                            icon: Icons.notifications_active,
                            value: _notificationGroups['General']!['Push Notifications']!,
                            isDarkMode: isDarkMode,
                            themeProvider: themeProvider,
                            onChanged: (val) => _updateSetting('General', 'Push Notifications', val),
                          ),
                          _buildAnimatedSwitchTile(
                            title: 'Email Notifications',
                            description: 'Receive notifications via email.',
                            icon: Icons.email,
                            value: _notificationGroups['General']!['Email Notifications']!,
                            isDarkMode: isDarkMode,
                            themeProvider: themeProvider,
                            onChanged: (val) => _updateSetting('General', 'Email Notifications', val),
                          ),
                          
                          _buildCategoryHeader('App Notifications', isDarkMode, themeProvider),
                          _buildAnimatedSwitchTile(
                            title: 'Reminders',
                            description: 'Get reminded about pending tasks and actions.',
                            icon: Icons.access_time,
                            value: _notificationGroups['App']!['Reminders']!,
                            isDarkMode: isDarkMode,
                            themeProvider: themeProvider,
                            onChanged: (val) => _updateSetting('App', 'Reminders', val),
                          ),
                          _buildAnimatedSwitchTile(
                            title: 'Weekly Reports',
                            description: 'Receive a summary of your activity every week.',
                            icon: Icons.summarize,
                            value: _notificationGroups['App']!['Weekly Reports']!,
                            isDarkMode: isDarkMode,
                            themeProvider: themeProvider,
                            onChanged: (val) => _updateSetting('App', 'Weekly Reports', val),
                          ),
                          
                          _buildCategoryHeader('Content Notifications', isDarkMode, themeProvider),
                          _buildAnimatedSwitchTile(
                            title: 'App Updates',
                            description: 'Be notified when new features are available.',
                            icon: Icons.system_update,
                            value: _notificationGroups['Content']!['App Updates']!,
                            isDarkMode: isDarkMode,
                            themeProvider: themeProvider,
                            onChanged: (val) => _updateSetting('Content', 'App Updates', val),
                          ),
                          _buildAnimatedSwitchTile(
                            title: 'Transcription Alerts',
                            description: 'Get notified when your transcriptions are ready.',
                            icon: Icons.record_voice_over,
                            value: _notificationGroups['Content']!['Transcription Alerts']!,
                            isDarkMode: isDarkMode,
                            themeProvider: themeProvider,
                            onChanged: (val) => _updateSetting('Content', 'Transcription Alerts', val),
                          ),
                          
                          // Notification time preferences
                          if (_notificationGroups['General']!['Push Notifications']! || _notificationGroups['General']!['Email Notifications']!) ...[
                            _buildCategoryHeader('Notification Time', isDarkMode, themeProvider),
                            _buildTimePreferences(isDarkMode, themeProvider),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'You can change these settings at any time. Some platform-specific notification settings may also need to be configured in your device settings.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            
            // Save button and confirmation at bottom
            AnimatedBuilder(
              animation: screenAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _bottomBarAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _bottomBarAnimation.value)),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: themeProvider.settingsBottomBarDecoration,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Success confirmation
                          AnimatedCrossFade(
                            firstChild: Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Notification settings saved!',
                                    style: themeProvider.bodyMedium.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondChild: const SizedBox(height: 36),
                            crossFadeState: showConfirmation 
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 300),
                          ),
                          
                          // Action buttons
                          Row(
                            children: [
                              // Reset button
                              TextButton.icon(
                                onPressed: haveUnsavedChanges
                                    ? () => _showResetConfirmation(themeProvider)
                                    : null,
                                icon: Icon(
                                  Icons.refresh,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: Text(
                                  'Reset',
                                  style: themeProvider.bodyMedium.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Save button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: haveUnsavedChanges ? _savePreferences : null,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Save Preferences'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                                    ),
                                    backgroundColor: themeProvider.accentColor,
                                    disabledBackgroundColor: themeProvider.accentColor.withOpacity(0.5),
                                    elevation: 0,
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
              }
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryHeader(String title, bool isDarkMode, ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          themeProvider.accentColor.withOpacity(0.15),
                          themeProvider.accentColor.withOpacity(0.05),
                        ]
                      : [
                          themeProvider.accentColor.withOpacity(0.15),
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
                      _getCategoryIcon(title),
                      color: themeProvider.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: themeProvider.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general notifications':
        return Icons.notifications_active_outlined;
      case 'app notifications':
        return Icons.apps_outlined;
      case 'content notifications':
        return Icons.article_outlined;
      case 'notification time':
        return Icons.schedule_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
  
  Widget _buildAnimatedSwitchTile({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required bool isDarkMode,
    required ThemeProvider themeProvider,
    required ValueChanged<bool> onChanged,
    bool requiresRestart = false,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[title] = true),
      onExit: (_) => setState(() => _hoverStates[title] = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          final isHovered = _hoverStates[title] == true;
          
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHovered
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
                              themeProvider.backgroundColor.withOpacity(0.8),
                              themeProvider.backgroundColor.withOpacity(0.6),
                            ]
                          : [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7),
                            ],
                ),
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: isHovered
                        ? themeProvider.accentColor.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isHovered ? 8 : 5,
                    spreadRadius: isHovered ? 1 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isHovered
                      ? themeProvider.accentColor.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: value
                                  ? [
                                      themeProvider.accentColor.withOpacity(0.2),
                                      themeProvider.accentColor.withOpacity(0.1),
                                    ]
                                  : [
                                      Colors.grey.withOpacity(0.2),
                                      Colors.grey.withOpacity(0.1),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                          ),
                          child: Icon(
                            icon,
                            color: value ? themeProvider.accentColor : themeProvider.secondaryIconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title, 
                                style: themeProvider.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.primaryTextColor,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description, 
                                style: themeProvider.bodySmall.copyWith(
                                  color: themeProvider.secondaryTextColor,
                                ),
                              ),
                              if (requiresRestart) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      size: 14,
                                      color: themeProvider.accentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Requires restart',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: themeProvider.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: value,
                          onChanged: onChanged,
                          activeColor: themeProvider.accentColor,
                          activeTrackColor: themeProvider.accentColor.withOpacity(0.3),
                        ),
                      ],
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
  
  Widget _buildTimePreferences(bool isDarkMode, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: isDarkMode ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
      ),
      color: isDarkMode 
          ? Colors.black.withOpacity(0.3)
          : Colors.white.withOpacity(0.9),
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
                    color: themeProvider.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: themeProvider.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Time Preference',
                      style: themeProvider.titleMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Choose when you want to receive notifications',
                      style: themeProvider.bodySmall.copyWith(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Time range options with improved layout
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeRanges.map((time) {
                final isSelected = selectedTimeRange == time;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTimeRange = time;
                      haveUnsavedChanges = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: themeProvider.animationDurationShort,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 10
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? themeProvider.accentColor.withOpacity(isDarkMode ? 0.3 : 0.1)
                          : isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? themeProvider.accentColor 
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: themeProvider.accentColor.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: themeProvider.accentColor,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        Text(
                          time,
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
              }).toList(),
            ),
            
            // Custom time range selector with improved UI
            if (selectedTimeRange == "Custom") ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  border: Border.all(
                    color: isDarkMode 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Time Range',
                      style: themeProvider.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12, 
                                horizontal: 12
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: themeProvider.accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: themeProvider.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _startTime.format(context),
                                    style: themeProvider.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'to',
                            style: themeProvider.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12, 
                                horizontal: 12
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: themeProvider.accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: themeProvider.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _endTime.format(context),
                                    style: themeProvider.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Daily schedule options
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDayChip('Mon', true, isDarkMode, themeProvider),
                        _buildDayChip('Tue', true, isDarkMode, themeProvider),
                        _buildDayChip('Wed', true, isDarkMode, themeProvider),
                        _buildDayChip('Thu', true, isDarkMode, themeProvider),
                        _buildDayChip('Fri', true, isDarkMode, themeProvider),
                        _buildDayChip('Sat', false, isDarkMode, themeProvider),
                        _buildDayChip('Sun', false, isDarkMode, themeProvider),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Show help dialog with explanation of notification options
  void _showHelp(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: themeProvider.accentColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Notification Help',
              style: themeProvider.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                'Push Notifications',
                'Receive alerts on your device when important events happen, such as completed transcriptions.',
                Icons.notifications_active,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Email Notifications',
                'Get emails about your activity, updates, and important information.',
                Icons.email,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Notification Time',
                'Control when notifications are sent to avoid disruptions during focused work or sleep hours.',
                Icons.access_time,
                themeProvider,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Weekly Reports',
                'Receive a summary of your activity every week, including usage statistics and suggestions.',
                Icons.summarize,
                themeProvider,
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
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
      ),
    );
  }
  
  Widget _buildHelpItem(String title, String description, IconData icon, ThemeProvider themeProvider) {
    return Row(
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
    );
  }
  
  // Show confirmation dialog for resetting settings
  void _showResetConfirmation(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Settings',
          style: themeProvider.headlineMedium,
        ),
        content: Text(
          'This will reset all notification settings to their default values. Are you sure you want to continue?',
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
              _resetSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
      ),
    );
  }
  
  // Reset notification settings to defaults
  void _resetSettings() {
    setState(() {
      // Reset to default values
      _notificationGroups = {
        'General': {
          'Push Notifications': true,
          'Email Notifications': false,
        },
        'App': {
          'Reminders': true,
          'Weekly Reports': false,
        },
        'Content': {
          'App Updates': true,
          'Transcription Alerts': true,
        }
      };
      
      selectedTimeRange = "Anytime";
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      
      // Mark as having unsaved changes
      haveUnsavedChanges = true;
    });
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Widget _buildDayChip(String day, bool isActive, bool isDarkMode, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        // Would toggle day selection in a real app
        setState(() {
          haveUnsavedChanges = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? themeProvider.accentColor.withOpacity(isDarkMode ? 0.3 : 0.1)
              : isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade200.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? themeProvider.accentColor
                : Colors.transparent,
          ),
        ),
        child: Text(
          day,
          style: themeProvider.bodySmall.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? themeProvider.accentColor
                : isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}