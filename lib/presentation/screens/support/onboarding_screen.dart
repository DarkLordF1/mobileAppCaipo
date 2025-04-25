import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import '../auth/auth_screen.dart'; // Navigate to login after onboarding

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/onboarding1.png",
      "title": "Welcome to CAIPO.ai",
      "description": "Your AI-powered personal assistant for productivity, business, and more.",
    },
    {
      "image": "assets/onboarding2.png",
      "title": "Record & Manage",
      "description": "Easily record, store, and access your voice and video files anytime, anywhere.",
    },
    {
      "image": "assets/onboarding3.png",
      "title": "AI-Powered Insights",
      "description": "Transcribe, analyze, and optimize your recordings with advanced AI tools.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hasSeenOnboarding", true);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    
    // Reset and play animation when page changes
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;
    
    return GradientScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _buildOnboardingPage(
                  context,
                  onboardingData[index]["image"]!,
                  onboardingData[index]["title"]!,
                  onboardingData[index]["description"]!,
                );
              },
            ),

            // Page Indicator & Navigation Buttons
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  _buildPageIndicator(themeProvider),
                  const SizedBox(height: 30),
                  _buildNavigationButtons(themeProvider, size),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(BuildContext context, String image, String title, String description) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated image
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  height: size.height * 0.35,
                  width: size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.accentColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: size.height * 0.06),
          // Animated title
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    title,
                    style: themeProvider.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Animated description
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: themeProvider.bodyMedium.copyWith(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(onboardingData.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 10,
          width: _currentPage == index ? 24 : 10,
          decoration: BoxDecoration(
            color: _currentPage == index 
                ? themeProvider.accentColor 
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _currentPage == index ? [
              BoxShadow(
                color: themeProvider.accentColor.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons(ThemeProvider themeProvider, Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Skip button
        TextButton(
          onPressed: _completeOnboarding,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(themeProvider.borderRadius),
            ),
          ),
          child: Text(
            "Skip",
            style: themeProvider.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Next/Finish button
        Container(
          height: 50,
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
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (_currentPage == onboardingData.length - 1) {
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
              ),
              elevation: 0,
            ),
            child: Text(
              _currentPage == onboardingData.length - 1 ? "Get Started" : "Next",
              style: themeProvider.headlineSmall.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
