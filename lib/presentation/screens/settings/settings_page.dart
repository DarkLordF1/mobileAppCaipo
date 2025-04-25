import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/theme_provider.dart';
import '../profile/account_profile_page.dart';
import '../ai/ai_preferences_page.dart';
import '../notifications/notifications_page.dart';
import 'privacy_data_page.dart';
import 'appearance_display_page.dart';
import 'advanced_settings_page.dart';
import '../support/about_support_page.dart';
import '../../widgets/gradient_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  // Additional animations for enhanced effects
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  
  // For animation of list items
  final List<Animation<double>> _itemAnimations = [];
  
  // Keep track of recently accessed settings
  final List<String> _recentSettings = [];
  
  // Mouse hover states for interactive feedback
  final Map<String, bool> _hoveredItems = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadRecentSettings();
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeIn
    );
    
    // Initialize pulse animation for interactive elements
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }
  
  Future<void> _loadRecentSettings() async {
    // This would typically load from SharedPreferences in a real app
    // For now we'll just use a placeholder set of recent items
    setState(() {
      _recentSettings.addAll([
        'Appearance & Display',
        'Account & Profile',
      ]);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _addToRecent(String title) {
    // Add to recent if not already there
    if (!_recentSettings.contains(title)) {
      setState(() {
        _recentSettings.insert(0, title);
        if (_recentSettings.length > 3) {
          _recentSettings.removeLast();
        }
      });
    } else {
      // Move to the front if already exists
      setState(() {
        _recentSettings.remove(title);
        _recentSettings.insert(0, title);
      });
    }
    
    // In a real app, save to persistent storage
    // _saveRecentSettings();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final List<Map<String, dynamic>> settingsOptions = [
      {
        'title': 'Account & Profile', 
        'icon': Icons.person, 
        'page': const AccountProfilePage(), 
        'description': 'Manage your personal information',
        'color': Colors.indigo,
      },
      {
        'title': 'AI Preferences', 
        'icon': Icons.smart_toy, 
        'page': const AIPreferencesPage(), 
        'description': 'Customize how CAIPO interacts with you',
        'color': Colors.purple,
      },
      {
        'title': 'Notifications & Reminders', 
        'icon': Icons.notifications, 
        'page': const NotificationsPage(), 
        'description': 'Control alerts and reminders',
        'color': Colors.amber.shade700,
      },
      {
        'title': 'Privacy & Data', 
        'icon': Icons.shield, 
        'page': const PrivacyDataPage(), 
        'description': 'Manage data sharing and privacy options',
        'color': Colors.green,
      },
      {
        'title': 'Appearance & Display', 
        'icon': Icons.palette, 
        'page': const AppearanceDisplayPage(), 
        'description': 'Customize your app appearance',
        'color': Colors.blue,
      },
      {
        'title': 'Advanced Settings', 
        'icon': Icons.build, 
        'page': const AdvancedSettingsPage(), 
        'description': 'Developer options and advanced features',
        'color': Colors.orange,
      },
      {
        'title': 'About & Support', 
        'icon': Icons.help_outline, 
        'page': const AboutSupportPage(), 
        'description': 'Get help and learn about CAIPO',
        'color': Colors.teal,
      },
      {
        'title': 'Theme',
        'icon': isDarkMode ? Icons.dark_mode : Icons.light_mode,
        'description': isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
        'color': isDarkMode ? Colors.blueGrey : Colors.amber,
        'widget': Switch(
          value: themeProvider.themeMode == ThemeMode.dark,
          activeColor: themeProvider.accentColor,
          inactiveTrackColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          onChanged: (value) {
            setState(() {
              themeProvider.toggleTheme(value);
            });
          },
        ),
      },
    ];

    // Initialize animations for each list item if needed
    if (_itemAnimations.isEmpty && settingsOptions.isNotEmpty) {
      for (int i = 0; i < settingsOptions.length; i++) {
        _itemAnimations.add(
          Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                0.1 + (i * 0.05),  // Staggered start
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
        );
      }
    }

    // Filter options based on search query
    final filteredOptions = _searchQuery.isEmpty
        ? settingsOptions
        : settingsOptions.where((option) =>
            option['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (option['description'] != null && 
             option['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
          ).toList();

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
          tooltip: 'Back',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            tooltip: 'Reset',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _fadeInAnimation.value) * -20),
                    child: Opacity(
                      opacity: _fadeInAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.accentColor.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: themeProvider.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Search settings...',
                      hintStyle: themeProvider.bodyMedium.copyWith(
                        color: themeProvider.disabledTextColor,
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                          ? Colors.black26
                          : Colors.white.withOpacity(0.9),
                      prefixIcon: Icon(
                        Icons.search,
                        color: themeProvider.secondaryIconColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: themeProvider.secondaryIconColor,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        borderSide: BorderSide(
                          color: themeProvider.accentColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
              ),
            ),
            
            // Recently accessed settings
            if (_recentSettings.isNotEmpty && _searchQuery.isEmpty) ...[
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _fadeInAnimation.value) * -15),
                    child: Opacity(
                      opacity: _fadeInAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 12.0, bottom: 8.0),
                      child: Text(
                        'Recently Accessed',
                        style: themeProvider.titleMedium.copyWith(
                          color: themeProvider.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 46,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentSettings.length,
                        itemBuilder: (context, index) {
                          final recentTitle = _recentSettings[index];
                          final recentOption = settingsOptions.firstWhere(
                            (option) => option['title'] == recentTitle,
                            orElse: () => {'title': recentTitle},
                          );
                          
                          final String chipKey = 'recent_$index';
                          final bool isHovered = _hoveredItems[chipKey] ?? false;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: MouseRegion(
                              onEnter: (_) => setState(() => _hoveredItems[chipKey] = true),
                              onExit: (_) => setState(() => _hoveredItems[chipKey] = false),
                              child: Transform.scale(
                                scale: isHovered ? 1.05 : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: ActionChip(
                                    avatar: recentOption['icon'] != null
                                        ? Icon(
                                            recentOption['icon'],
                                            size: 16,
                                            color: recentOption['color'] ?? themeProvider.accentColor,
                                          )
                                        : null,
                                    label: Text(recentTitle),
                                    backgroundColor: isDarkMode
                                        ? isHovered 
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade800
                                        : isHovered
                                            ? Colors.grey.shade100
                                            : Colors.white,
                                    labelStyle: themeProvider.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: isHovered
                                          ? recentOption['color'] ?? themeProvider.accentColor
                                          : themeProvider.primaryTextColor,
                                    ),
                                    elevation: isHovered ? 4 : 2,
                                    shadowColor: isHovered
                                        ? (recentOption['color'] ?? themeProvider.accentColor).withOpacity(0.3)
                                        : Colors.black26,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    onPressed: () {
                                      if (recentOption['page'] != null) {
                                        _addToRecent(recentOption['title']);
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => recentOption['page'],
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0.05, 0),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            transitionDuration: themeProvider.animationDurationMedium,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
            
            // Settings category header - only show if not searching
            if (_searchQuery.isEmpty)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _fadeInAnimation.value) * -10),
                    child: Opacity(
                      opacity: _fadeInAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              Colors.grey.shade800.withOpacity(0.6),
                              Colors.grey.shade900.withOpacity(0.3),
                            ]
                          : [
                              themeProvider.accentColor.withOpacity(0.1),
                              themeProvider.accentColor.withOpacity(0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 18,
                        color: themeProvider.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All Settings',
                        style: themeProvider.titleMedium.copyWith(
                          color: themeProvider.primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // No results message
            if (filteredOptions.isEmpty)
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeInAnimation,
                      child: child,
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkMode
                                  ? Colors.grey.shade800.withOpacity(0.3)
                                  : Colors.grey.shade200.withOpacity(0.5),
                            ),
                            child: Icon(
                              Icons.search_off,
                              size: 64,
                              color: themeProvider.disabledIconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No settings found',
                          style: themeProvider.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: themeProvider.bodyMedium.copyWith(
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Clear Search'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Settings list
            if (filteredOptions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: filteredOptions.length,
                  itemBuilder: (context, index) {
                    final option = filteredOptions[index];
                    
                    return FadeTransition(
                      opacity: _itemAnimations.length > index
                          ? _itemAnimations[index]
                          : const AlwaysStoppedAnimation(1.0),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(
                          _itemAnimations.length > index
                              ? _itemAnimations[index]
                              : const AlwaysStoppedAnimation(1.0),
                        ),
                        child: _buildSettingCard(
                          option,
                          isDarkMode,
                          index,
                          themeProvider,
                          onTap: () {
                            if (option['page'] != null) {
                              _addToRecent(option['title']);
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => option['page'],
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.05, 0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  transitionDuration: themeProvider.animationDurationMedium,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Version info at bottom
            if (_searchQuery.isEmpty)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeInAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              Colors.grey.shade900.withOpacity(0.5),
                              Colors.grey.shade900.withOpacity(0.3),
                            ]
                          : [
                              Colors.grey.shade200.withOpacity(0.5),
                              Colors.grey.shade200.withOpacity(0.3),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: themeProvider.disabledTextColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CAIPO App v1.0.0',
                        style: themeProvider.bodySmall.copyWith(
                          color: themeProvider.disabledTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingCard(
    Map<String, dynamic> option, 
    bool isDarkMode, 
    int index,
    ThemeProvider themeProvider, {
    required VoidCallback onTap
  }) {
    final String itemKey = 'setting_$index';
    final bool isHovered = _hoveredItems[itemKey] ?? false;
    final Color itemColor = option['color'] ?? themeProvider.accentColor;
    
    return Semantics(
      button: true,
      label: 'Settings option for ${option['title']}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItems[itemKey] = true),
        onExit: (_) => setState(() => _hoveredItems[itemKey] = false),
        child: AnimatedContainer(
          duration: themeProvider.animationDurationShort,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black26
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(themeProvider.borderRadius),
            border: Border.all(
              color: isHovered
                  ? itemColor.withOpacity(0.5)
                  : isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
              width: isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? itemColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isHovered ? 8 : 4,
                spreadRadius: isHovered ? 1 : 0,
                offset: isHovered
                    ? const Offset(0, 3)
                    : const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: option['page'] != null ? onTap : null,
              borderRadius: BorderRadius.circular(themeProvider.borderRadius),
              splashColor: itemColor.withOpacity(0.1),
              highlightColor: itemColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Icon with background
                    AnimatedContainer(
                      duration: themeProvider.animationDurationShort,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                        boxShadow: isHovered ? [
                          BoxShadow(
                            color: itemColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : [],
                      ),
                      child: Icon(
                        option['icon'] ?? Icons.settings,
                        size: 24,
                        color: itemColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'],
                            style: themeProvider.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (option['description'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              option['description'],
                              style: themeProvider.bodySmall.copyWith(
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Action (switch or arrow)
                    option.containsKey('widget')
                        ? option['widget']
                        : AnimatedContainer(
                            duration: themeProvider.animationDurationShort,
                            width: isHovered ? 24 : 20,
                            height: isHovered ? 24 : 20,
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? itemColor.withOpacity(0.1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chevron_right,
                                size: isHovered ? 20 : 16,
                                color: isHovered
                                    ? itemColor
                                    : themeProvider.secondaryIconColor,
                              ),
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
}