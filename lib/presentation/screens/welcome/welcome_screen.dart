import 'package:flutter/material.dart';
import '../../../di/injection.dart';
import '../../widgets/base_screen.dart';
import '../../providers/theme_provider.dart';
import '../../../core/utils/logger.dart';

class WelcomeScreen extends BaseScreen {
  const WelcomeScreen({super.key});

  @override
  Widget buildContent(BuildContext context, ThemeProvider themeProvider) {
    final logger = getIt<LoggerService>();
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Logo with enhanced glow effect and animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          themeProvider.accentColor.withOpacity(0.7),
                          themeProvider.accentColor.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.accentColor.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Title with enhanced styling and animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    'Welcome to CAIPO',
                    style: themeProvider.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Subtitle with improved contrast, styling and animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Container(
                    width: size.width * 0.85,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Your AI-powered companion for seamless communication and productivity',
                      textAlign: TextAlign.center,
                      style: themeProvider.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.4,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const Spacer(flex: 2),
          // Stylized button with gradient and animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Container(
                    width: size.width * 0.8,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                      gradient: LinearGradient(
                        colors: [
                          themeProvider.accentColor,
                          themeProvider.accentColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.accentColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        logger.info('Navigating to auth screen');
                        Navigator.pushReplacementNamed(context, '/auth');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        ),
                        elevation: 0, // No elevation since we're using custom shadow
                      ),
                      child: Text(
                        'Get Started',
                        style: themeProvider.headlineSmall.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Subtle text link with animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: TextButton(
                  onPressed: () {
                    // Could navigate to about/info page
                    logger.info('Learn more pressed');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Learn More',
                    style: themeProvider.bodyMedium.copyWith(
                      fontSize: 15,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.underline,
                      decorationThickness: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
} 