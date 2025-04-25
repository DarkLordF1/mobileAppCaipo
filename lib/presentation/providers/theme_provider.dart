import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

/// A comprehensive theme provider that implements a design system
/// for consistent UI across the app.
@singleton
class ThemeProvider with ChangeNotifier {
  // Preference keys
  static const String _themeKey = 'theme_mode';
  static const String _gradientStyleKey = 'gradient_style';
  static const String _fontFamilyKey = 'font_family';
  static const String _accentColorKey = 'accent_color';
  static const String _textSizeKey = 'text_size';
  static const String _animationSpeedKey = 'animation_speed';
  static const String _useAnimationsKey = 'use_animations';
  static const String _roundedCornersKey = 'rounded_corners';
  static const String _elevationStyleKey = 'elevation_style';
  
  final SharedPreferences _prefs;
  
  // Default values
  static const ThemeMode _defaultThemeMode = ThemeMode.system;
  static const Color _defaultAccentColor = Colors.blue;
  
  // Theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Gradient and color preferences
  String _gradientStyle = 'purple'; // 'purple', 'blue', 'teal'
  String _accentColorName = 'blue'; // 'blue', 'purple', 'teal', etc.
  
  // UI style preferences
  String _fontFamily = 'Roboto';
  double _textSizeMultiplier = 1.0; // For scaling text
  String _animationSpeed = 'normal'; // 'slow', 'normal', 'fast'
  bool _useAnimations = true;
  double _borderRadius = 12.0;
  double _elevationFactor = 1.0; // For scaling elevation across the app
  
  // Fonts available in the app
  final List<String> availableFonts = [
    'Roboto',
    'Montserrat',
    'Poppins',
    'Open Sans',
    'Lato'
  ];
  
  // Available animation speeds with their duration multipliers
  final Map<String, double> _animationSpeeds = {
    'slow': 1.5,
    'normal': 1.0,
    'fast': 0.7,
    'none': 0.0 // Instantaneous
  };
  
  // Color palette - A comprehensive palette for the app
  final Map<String, ColorSwatch> _colorPalette = {
    'blue': Colors.blue,
    'purple': Colors.purple,
    'teal': Colors.teal,
    'green': Colors.green,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'red': Colors.red,
    'amber': Colors.amber,
    'indigo': Colors.indigo,
    'cyan': Colors.cyan,
  };
  
  // Theme colors
  Color _accentColor = Colors.blueAccent;
  final Color _lightPrimaryColor = Colors.white;
  final Color _darkPrimaryColor = Colors.black87;
  
  // Text styles
  late TextStyle _displayMedium;
  late TextStyle _headlineSmall;
  late TextStyle _bodyMedium;
  
  @factoryMethod
  ThemeProvider(@Named('sharedPreferences') this._prefs) {
    _initializeTextStyles();
  }

  // Initialize the provider with custom settings
  void initialize({
    ThemeMode initialThemeMode = ThemeMode.system,
    double initialBorderRadius = 12.0,
    Color initialAccentColor = Colors.blueAccent,
  }) {
    _themeMode = initialThemeMode;
    _borderRadius = initialBorderRadius;
    _accentColor = initialAccentColor;
  }

  // Public method to load preferences
  Future<void> loadPreferences() async {
    await _loadPreferences();
  }

  ThemeMode get themeMode => _themeMode;
  bool get usePurpleGradient => _gradientStyle == 'purple';

  Future<void> _loadPreferences() async {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
    _gradientStyle = _prefs.getString(_gradientStyleKey) ?? 'purple';
    _accentColorName = _prefs.getString(_accentColorKey) ?? 'blue';
    _fontFamily = _prefs.getString(_fontFamilyKey) ?? 'Roboto';
    _textSizeMultiplier = _prefs.getDouble(_textSizeKey) ?? 1.0;
    _animationSpeed = _prefs.getString(_animationSpeedKey) ?? 'normal';
    _useAnimations = _prefs.getBool(_useAnimationsKey) ?? true;
    _borderRadius = _prefs.getDouble(_roundedCornersKey) ?? 12.0;
    _elevationFactor = _prefs.getDouble(_elevationStyleKey) ?? 1.0;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Get the appropriate scaffold gradient based on theme
  LinearGradient get scaffoldGradient {
    if (_themeMode == ThemeMode.light) {
      // Light theme - light blue gradient
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE3F2FD), // Very light blue
          Color(0xFF90CAF9), // Medium light blue
        ],
      );
    } else {
      // Dark theme - more elegant and subtle gradient
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF252042), // Muted dark purple - 0%
          Color(0xFF1E1A38), // Deeper muted purple - 20%
          Color(0xFF18152E), // Deep blue-purple - 40%
          Color(0xFF131126), // Deep blue-purple - 60%
          Color(0xFF0E0C1E), // Very deep blue-purple - 80%
          Color(0xFF090818), // Almost black with deep blue tint - 100%
        ],
        stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      );
    }
  }

  // Get the header gradient (can be used for cards, app bars, etc.)
  LinearGradient get headerGradient {
    if (_themeMode == ThemeMode.light) {
      return const LinearGradient(
        colors: [
          Color(0xFF2196F3),  // Primary blue
          Color(0xFF64B5F6),  // Lighter blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      if (_gradientStyle == 'purple') {
        return const LinearGradient(
          colors: [Color(0xFF4A2B9E), Color(0xFF341C78)], // More muted purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        return const LinearGradient(
          colors: [Color(0xFF0A0F1F), Color(0xFF152238)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
  }

  // Get the appropriate gradient colors as a list (for backward compatibility)
  List<Color> getGradientColors() {
    if (_themeMode == ThemeMode.light) {
      // Light theme - light blue gradient
      return const [
        Color(0xFFE3F2FD), // Very light blue
        Color(0xFF90CAF9), // Medium light blue
      ];
    } else {
      // Dark theme - extremely dark version of the gradient
      return const [
        Color(0xFF2A0D4D), // Very dark purple - 0%
        Color(0xFF230B40), // Extremely dark purple - 19%
        Color(0xFF1B0A30), // Nearly black with purple tint - 39%
        Color(0xFF140721), // Nearly black with slight purple - 60%
        Color(0xFF0A0312), // Almost pure black with hint of purple - 80%
        Color(0xFF000000), // Pure black - 100%
      ];
    }
  }

  // Toggle between light and dark themes
  void toggleTheme(bool isDarkMode) async {
    await setThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  // Toggle between purple gradient and teal gradient in dark mode
  Future<void> setGradientStyle(String style) async {
    _gradientStyle = style;
    await _prefs.setString(_gradientStyleKey, style);
    notifyListeners();
  }

  void toggleGradientStyle(bool usePurple) async {
    await setGradientStyle(usePurple ? 'purple' : 'teal');
  }

  Color getIconColor(BuildContext context) {
    return _themeMode == ThemeMode.dark 
        ? Colors.white 
        : Colors.black87;
  }

  Color getTextColor(BuildContext context) {
    return _themeMode == ThemeMode.dark 
        ? Colors.white 
        : Colors.white; // Always white for better contrast
  }

  Color get cardBackground {
    return _themeMode == ThemeMode.dark 
        ? Colors.black.withAlpha(153) // 0.6 * 255 ≈ 153 (more transparent)
        : Colors.white.withAlpha(230); // 0.9 * 255 ≈ 230
  }

  TextStyle get headlineStyle {
    return TextStyle(
      color: Colors.white, // Always white for better contrast
      fontSize: 22,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.4),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ],
    );
  }

  TextStyle get bodyTextStyle {
    return TextStyle(
      color: _themeMode == ThemeMode.dark ? Colors.white.withOpacity(0.9) : Colors.white,
      fontSize: 16,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    );
  }

  Color get inputBackgroundColor {
    return _themeMode == ThemeMode.dark 
        ? Colors.grey.shade800 
        : Colors.grey.shade200;
  }

  Color get inputTextColor {
    return _themeMode == ThemeMode.dark 
        ? Colors.white 
        : Colors.black87;
  }

  // ---------- Getters ----------
  
  String get gradientStyle => _gradientStyle;
  String get fontFamily => _fontFamily;
  double get textSizeMultiplier => _textSizeMultiplier;
  bool get useAnimations => _useAnimations;
  String get animationSpeedName => _animationSpeed;
  double get borderRadius => _borderRadius;
  
  // Accent color getters
  Color get accentColor => _colorPalette[_accentColorName]!;
  String get accentColorName => _accentColorName;
  Map<String, ColorSwatch> get colorPalette => _colorPalette;
  
  // Animation duration getters
  Duration get animationDurationShort => Duration(
    milliseconds: (150 * _getAnimationMultiplier()).round()
  );
  
  Duration get animationDurationMedium => Duration(
    milliseconds: (300 * _getAnimationMultiplier()).round()
  );
  
  Duration get animationDurationLong => Duration(
    milliseconds: (500 * _getAnimationMultiplier()).round()
  );
  
  // Typography scale
  TextStyle get displayLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32 * _textSizeMultiplier,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: -0.5,
  );
  
  TextStyle get displayMedium => _displayMedium;
  
  TextStyle get displaySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24 * _textSizeMultiplier,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  TextStyle get headlineLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22 * _textSizeMultiplier,
    fontWeight: FontWeight.bold,
    color: textColor,
    shadows: isDarkMode ? [
      Shadow(
        color: Colors.black.withOpacity(0.3),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ] : [],
  );
  
  TextStyle get headlineMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20 * _textSizeMultiplier,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  TextStyle get headlineSmall => _headlineSmall;
  
  TextStyle get titleLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16 * _textSizeMultiplier,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  TextStyle get titleMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14 * _textSizeMultiplier,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16 * _textSizeMultiplier,
    color: textColor,
  );
  
  TextStyle get bodyMedium => _bodyMedium;
  
  TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12 * _textSizeMultiplier,
    color: textColor.withOpacity(0.67),
  );
  
  // Color getters for text, icons, surfaces
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get inverseTextColor => !isDarkMode ? Colors.white : Colors.black87;
  Color get primaryTextColor => textColor;
  Color get secondaryTextColor => textColor.withOpacity(0.7);
  Color get disabledTextColor => textColor.withOpacity(0.38);
  
  Color get iconColor => isDarkMode ? Colors.white : Colors.black87;
  Color get primaryIconColor => accentColor;
  Color get secondaryIconColor => iconColor.withOpacity(0.7);
  Color get disabledIconColor => iconColor.withOpacity(0.38);
  
  // Surface colors
  Color get surfaceColor => isDarkMode ? const Color(0xFF121212) : Colors.white;
  Color get modalBackgroundColor => isDarkMode 
      ? const Color(0xFF161616) 
      : Colors.white;
  Color get canvasColor => isDarkMode 
      ? const Color(0xFF0A0A0A) 
      : const Color(0xFFF5F5F5);
  
  // Input and form colors
  Color get inputBorderColor => isDarkMode 
      ? Colors.grey.shade700 
      : Colors.grey.shade300;
  Color get inputFocusedBorderColor => accentColor;
  
  // Feedback colors
  Color get successColor => Colors.green;
  Color get errorColor => Colors.red;
  Color get warningColor => Colors.orange;
  Color get infoColor => Colors.blue;
  
  // Card styles
  CardTheme get cardTheme => CardTheme(
    color: cardBackground,
    elevation: 1.5 * _elevationFactor, // Reduced elevation for more subtle look
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
    ),
    shadowColor: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
  );
  
  // Button styles
  ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    elevation: 2 * _elevationFactor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
    ),
    textStyle: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16 * _textSizeMultiplier,
      fontWeight: FontWeight.bold,
    ),
  );
  
  ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: accentColor,
    side: BorderSide(color: accentColor),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
    ),
    textStyle: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16 * _textSizeMultiplier,
      fontWeight: FontWeight.w500,
    ),
  );
  
  ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: accentColor,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
    ),
    textStyle: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14 * _textSizeMultiplier,
      fontWeight: FontWeight.w500,
    ),
  );
  
  // Input decoration style
  InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: inputBackgroundColor,
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      borderSide: BorderSide(color: inputBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      borderSide: BorderSide(color: inputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      borderSide: BorderSide(color: inputFocusedBorderColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      borderSide: BorderSide(color: errorColor),
    ),
    hintStyle: TextStyle(color: disabledTextColor),
  );

  double _getAnimationMultiplier() {
    return _animationSpeeds[_animationSpeed] ?? 1.0;
  }

  // ---------- Theme setters ----------
  
  Future<void> setFontFamily(String fontFamily) async {
    if (availableFonts.contains(fontFamily)) {
      _fontFamily = fontFamily;
      await _prefs.setString(_fontFamilyKey, fontFamily);
      notifyListeners();
    }
  }
  
  Future<void> setAccentColor(String colorName) async {
    if (_colorPalette.containsKey(colorName)) {
      _accentColorName = colorName;
      await _prefs.setString(_accentColorKey, colorName);
      notifyListeners();
    }
  }
  
  Future<void> setTextSizeMultiplier(double multiplier) async {
    if (multiplier >= 0.8 && multiplier <= 1.5) {
      _textSizeMultiplier = multiplier;
      await _prefs.setDouble(_textSizeKey, multiplier);
      notifyListeners();
    }
  }
  
  Future<void> setAnimationSpeed(String speed) async {
    if (_animationSpeeds.containsKey(speed)) {
      _animationSpeed = speed;
      await _prefs.setString(_animationSpeedKey, speed);
      notifyListeners();
    }
  }
  
  Future<void> setUseAnimations(bool useAnimations) async {
    _useAnimations = useAnimations;
    await _prefs.setBool(_useAnimationsKey, useAnimations);
    notifyListeners();
  }
  
  Future<void> setBorderRadius(double radius) async {
    if (radius >= 0 && radius <= 24) {
      _borderRadius = radius;
      await _prefs.setDouble(_roundedCornersKey, radius);
      notifyListeners();
    }
  }
  
  Future<void> setElevationFactor(double factor) async {
    if (factor >= 0 && factor <= 2) {
      _elevationFactor = factor;
      await _prefs.setDouble(_elevationStyleKey, factor);
      notifyListeners();
    }
  }
  
  // Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _gradientStyle = 'purple';
    _fontFamily = 'Roboto';
    _accentColorName = 'blue';
    _textSizeMultiplier = 1.0;
    _animationSpeed = 'normal';
    _useAnimations = true;
    _borderRadius = 12.0;
    _elevationFactor = 1.0;
    
    await _prefs.clear();
    notifyListeners();
  }
  
  // Create a complete ThemeData object for MaterialApp
  ThemeData getThemeData(bool isDark) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: isDark ? _darkPrimaryColor : _lightPrimaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: headlineLarge,
      ),
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge, 
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      fontFamily: _fontFamily,
      cardTheme: cardTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      inputDecorationTheme: inputDecorationTheme,
      scaffoldBackgroundColor: Colors.transparent,
      dialogTheme: DialogTheme(
        backgroundColor: modalBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: 16 * _elevationFactor,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade900,
        contentTextStyle: bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: accentColor,
        textColor: textColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 0.5,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark ? Colors.grey.shade800 : Colors.grey.shade400;
          }
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return isDark ? Colors.grey.shade400 : Colors.grey.shade50;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
          }
          if (states.contains(WidgetState.selected)) {
            return accentColor.withOpacity(0.4);
          }
          return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? Colors.black.withOpacity(0.8) : Colors.white,
        selectedItemColor: accentColor,
        unselectedItemColor: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        elevation: 8 * _elevationFactor,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _useAnimations 
              ? CupertinoPageTransitionsBuilder() 
              : FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(_borderRadius / 2),
        ),
        textStyle: bodySmall.copyWith(color: Colors.white),
      ),
    );
  }

  void _initializeTextStyles() {
    _displayMedium = TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28 * _textSizeMultiplier,
      fontWeight: FontWeight.bold,
      color: textColor,
      letterSpacing: -0.5,
    );
    
    _headlineSmall = TextStyle(
      fontFamily: _fontFamily,
      fontSize: 18 * _textSizeMultiplier,
      fontWeight: FontWeight.w600,
      color: textColor,
    );
    
    _bodyMedium = TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14 * _textSizeMultiplier,
      color: textColor,
    );
  }

  // Settings-specific styles
  Color get settingsCardBackground => isDarkMode 
      ? Colors.black.withOpacity(0.3) 
      : Colors.white.withOpacity(0.9);

  Color get settingsCardBorderColor => isDarkMode
      ? Colors.grey.shade800
      : Colors.grey.shade300;

  BoxDecoration get settingsCardDecoration => BoxDecoration(
    color: settingsCardBackground,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: settingsCardBorderColor,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  BoxDecoration get settingsHeaderDecoration => BoxDecoration(
    color: isDarkMode 
        ? Colors.black.withOpacity(0.4)
        : accentColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: isDarkMode
          ? Colors.grey.shade800
          : accentColor.withOpacity(0.2),
      width: 1,
    ),
  );

  TextStyle get settingsHeaderStyle => headlineSmall.copyWith(
    color: isDarkMode ? Colors.white : Colors.black87,
    fontWeight: FontWeight.bold,
  );

  TextStyle get settingsTitleStyle => titleMedium.copyWith(
    fontWeight: FontWeight.w600,
    color: isDarkMode ? Colors.white : Colors.black87,
  );

  TextStyle get settingsDescriptionStyle => bodyMedium.copyWith(
    color: secondaryTextColor,
  );

  BoxDecoration getSettingsIconDecoration({required bool isActive}) => BoxDecoration(
    color: (isActive ? accentColor : Colors.grey).withOpacity(isDarkMode ? 0.2 : 0.1),
    borderRadius: BorderRadius.circular(borderRadius / 2),
  );

  Color getSettingsIconColor({required bool isActive}) => isActive 
      ? accentColor
      : isDarkMode 
          ? Colors.grey.shade400 
          : Colors.grey.shade600;

  // Bottom bar decoration for settings pages
  BoxDecoration get settingsBottomBarDecoration => BoxDecoration(
    color: isDarkMode 
        ? Colors.black.withOpacity(0.4)
        : Colors.white.withOpacity(0.9),
    border: Border(
      top: BorderSide(
        color: isDarkMode
            ? Colors.grey.shade800
            : Colors.grey.shade300,
        width: 1,
      ),
    ),
  );

  // Get the solid background color for the theme
  Color get backgroundColor {
    return _themeMode == ThemeMode.light
        ? const Color(0xFFE3F2FD) // Light blue for light theme
        : const Color(0xFF1E1A33); // Dark purplish-blue for dark theme
  }
}