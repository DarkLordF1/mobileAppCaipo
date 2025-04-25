import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();

  /// This method should be implemented by subclasses to build the screen content
  Widget buildContent(BuildContext context, ThemeProvider themeProvider);
}

class _BaseScreenState extends State<BaseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.7, 1.0],
            colors: themeProvider.isDarkMode
                ? [
                    const Color(0xFF1A0E38), 
                    const Color(0xFF0F0521), 
                    Colors.black
                  ]
                : [
                    Colors.blue.shade600, 
                    Colors.blue.shade700, 
                    Colors.blue.shade900
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.buildContent(context, themeProvider),
          ),
        ),
      ),
    );
  }
}

/// A mixin that can be used to add animation capabilities to screens
/// that don't extend BaseScreen but need similar animation functionality
mixin ScreenAnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController screenAnimationController;
  late Animation<double> fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    screenAnimationController = AnimationController(
      vsync: this as TickerProvider,
      duration: const Duration(milliseconds: 800),
    );
    
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: screenAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    screenAnimationController.forward();
  }
  
  @override
  void dispose() {
    screenAnimationController.dispose();
    super.dispose();
  }
  
  /// Helper method to create staggered animations
  Animation<double> createStaggeredAnimation({
    required double begin,
    required double end,
    required double startInterval,
    required double endInterval,
    Curve curve = Curves.easeOut,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: screenAnimationController,
        curve: Interval(startInterval, endInterval, curve: curve),
      ),
    );
  }
} 