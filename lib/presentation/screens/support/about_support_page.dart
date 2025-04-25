import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';

class AboutSupportPage extends StatefulWidget {
  const AboutSupportPage({super.key});

  @override
  State<AboutSupportPage> createState() => _AboutSupportPageState();
}

class _AboutSupportPageState extends State<AboutSupportPage> with SingleTickerProviderStateMixin {
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
    
    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          'About & Support',
          style: themeProvider.settingsHeaderStyle.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.primaryIconColor),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAboutSection(themeProvider),
                  const SizedBox(height: 24),
                  _buildFAQSection(themeProvider),
                  const SizedBox(height: 24),
                  _buildSupportButton(themeProvider),
                  const SizedBox(height: 28),
                  _buildVersionInfo(themeProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAboutSection(ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: themeProvider.settingsCardDecoration.copyWith(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.accentColor.withOpacity(0.15),
                            themeProvider.accentColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                        border: Border.all(
                          color: themeProvider.accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  themeProvider.accentColor.withOpacity(0.9),
                                  themeProvider.accentColor.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smart_toy_outlined,
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
                                  'CAIPO Assistant',
                                  style: themeProvider.settingsTitleStyle.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your AI-powered companion',
                                  style: themeProvider.settingsDescriptionStyle.copyWith(
                                    color: themeProvider.accentColor.withOpacity(0.8),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CAIPO is your intelligent assistant designed to help streamline tasks, provide insights, and improve productivity through natural conversations.',
                      style: themeProvider.settingsDescriptionStyle.copyWith(
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Powered by advanced AI technology, CAIPO learns from your interactions to deliver increasingly personalized assistance tailored to your needs.',
                      style: themeProvider.settingsDescriptionStyle.copyWith(
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFAQSection(ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: themeProvider.settingsHeaderDecoration.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeProvider.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.help_outline,
                          color: themeProvider.accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Frequently Asked Questions',
                        style: themeProvider.settingsHeaderStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: themeProvider.settingsCardDecoration.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      children: [
                        _buildFAQItem(
                          question: 'How does CAIPO work?',
                          answer: 'CAIPO uses advanced AI to process and understand your queries in real-time. It analyzes your input, retrieves relevant information, and generates helpful responses tailored to your needs.',
                          themeProvider: themeProvider,
                        ),
                        Divider(color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                        _buildFAQItem(
                          question: 'Is my data secure?',
                          answer: 'Yes, your interactions are private and encrypted. We use industry-standard security protocols to ensure your data remains confidential and protected at all times.',
                          themeProvider: themeProvider,
                        ),
                        Divider(color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                        _buildFAQItem(
                          question: 'How do I contact support?',
                          answer: 'You can contact our support team using the button below. Our dedicated team is available to assist you with any questions or issues you may encounter.',
                          themeProvider: themeProvider,
                        ),
                        Divider(color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                        _buildFAQItem(
                          question: 'Can I customize CAIPO?',
                          answer: 'Yes, you can customize various aspects of CAIPO through the settings menu. Adjust notification preferences, appearance settings, and more to tailor the experience to your preferences.',
                          themeProvider: themeProvider,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFAQItem({
    required String question, 
    required String answer,
    required ThemeProvider themeProvider,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: themeProvider.settingsTitleStyle.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        iconColor: themeProvider.accentColor,
        collapsedIconColor: themeProvider.secondaryIconColor,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Text(
            answer,
            style: themeProvider.settingsDescriptionStyle.copyWith(
              height: 1.4,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupportButton(ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Center(
              child: Container(
                height: 54,
                width: 220,
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Placeholder for support action
                    _showSupportDialog(context, themeProvider);
                  },
                  icon: const Icon(Icons.support_agent, size: 20),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    ),
                    elevation: 0,
                    textStyle: themeProvider.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildVersionInfo(ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: themeProvider.settingsCardDecoration.copyWith(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  themeProvider.accentColor.withOpacity(0.7),
                                  themeProvider.accentColor.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.accentColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flutter_dash,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CAIPO',
                      style: themeProvider.settingsTitleStyle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Version 1.0.0',
                      style: themeProvider.settingsDescriptionStyle.copyWith(
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '© 2025 FLOMAD. All rights reserved.',
                      style: themeProvider.settingsDescriptionStyle.copyWith(
                        color: themeProvider.isDarkMode 
                            ? Colors.white.withOpacity(0.6) 
                            : Colors.black.withOpacity(0.6),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showSupportDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: themeProvider.cardBackground,
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeProvider.accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          color: themeProvider.accentColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Contact Support',
                        style: themeProvider.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Our support team is ready to assist you with any questions or issues.',
                        textAlign: TextAlign.center,
                        style: themeProvider.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Your email address',
                          filled: true,
                          fillColor: themeProvider.isDarkMode 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe your issue or question',
                          filled: true,
                          fillColor: themeProvider.isDarkMode 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              'Cancel',
                              style: themeProvider.bodyMedium.copyWith(
                                color: themeProvider.isDarkMode 
                                    ? Colors.white.withOpacity(0.8) 
                                    : Colors.black.withOpacity(0.7),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Submit support request
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Support request submitted. We\'ll get back to you soon.'),
                                  backgroundColor: themeProvider.accentColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                              ),
                            ),
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}